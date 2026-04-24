# Audit notifications & messages Pro — Phase A

Date : 2026-04-22
Branche : `agent/refonte-totale-premium`
Statut : **diagnostic uniquement, aucun fix appliqué — en attente validation**

## Symptôme rapporté

Un compte Pro ne reçoit ni push notifications ni messages in-app
quand un client lui écrit. Le message du client est bien envoyé
(le client le voit dans la conversation), mais côté Pro :
- pas de banner FCM (foreground ni background) ;
- pas de badge unread sur la nav bar ;
- la liste des conversations ne se met pas à jour en live.

---

## 1. Flux théorique attendu (cible)

```
[Client] sendMessage()
   │
   ├─ INSERT INTO messages (sender_id=client, conversation_id, content)
   │     │
   │     └─▶ trigger AFTER INSERT  →  fire_send_push_notification(recipient=pro, ...)
   │            │
   │            └─▶ HTTP POST  →  Edge Function `send-push-notification`
   │                   │
   │                   ├─ check notification_preferences (messages_enabled)
   │                   ├─ read users.fcm_token
   │                   ├─ FCM v1 → APNs → device Pro
   │                   └─ INSERT INTO notifications (in-app inbox)
   │
   └─ UPDATE conversations.last_message / last_message_at
         │
         └─▶ Realtime → channel `rt:conversations:<pro_uid>` (UPDATE conversations)
                                                              (INSERT messages)
                                                                       │
                                                                       └─▶ ConversationsNotifier
                                                                            (badge unread,
                                                                             tri liste)

[Device Pro]
   FCM payload arrive
      ├─ app fermée   → getInitialMessage()  → router.go('/pro/messages?cid=…')
      ├─ background   → onMessageOpenedApp() → router.go('/pro/messages?cid=…')
      └─ foreground   → onMessage() → in-app banner / SnackBar
```

## 2. Flux réel (ce que fait le code aujourd'hui)

### 2.1 Côté client (envoi)

`lib/features/chat/data/chat_repository.dart:91-176`

```
sendMessage()
   ├─ INSERT INTO messages              ← OK
   ├─ UPDATE conversations.last_message ← OK ('📷 Image' fallback, voir bug #7)
   └─ _notifyRecipient()                ← INSERT notifications EN PLUS DU TRIGGER (voir bug #4)
        ├─ increment unread_count_pro / unread_count_client (RPC) ← OK
        └─ INSERT notifications (type='new_message',
                                title='New message from $senderName')  ← bug #4 + #5 + #7
```

### 2.2 Côté DB (trigger)

`supabase/migrations/20260326121446_remote_schema.sql`

- L2242 : `CREATE OR REPLACE TRIGGER tr_messages_push_after_insert AFTER INSERT ON messages FOR EACH ROW EXECUTE FUNCTION tr_notify_new_message_push();` ← **présent**
- L901-940 : `tr_notify_new_message_push()` résout le recipient et appelle :

```sql
PERFORM public.fire_send_push_notification(
  recipient,
  'Nouveau message',
  preview,
  'message',
  jsonb_build_object(
    'conversationId', NEW.conversation_id::text,
    'route', '/client/messages'         -- ⚠ HARDCODÉ — bug #2
  )
);
```

- L312-354 : `fire_send_push_notification()`

```sql
v_url := NULLIF(current_setting('app.settings.push_function_url', true), '');
v_key := NULLIF(current_setting('app.settings.service_role_key', true), '');
IF v_url IS NULL OR v_key IS NULL THEN
  RAISE LOG 'fire_send_push_notification: skip (...)';
  RETURN;                                -- ⚠ silent no-op — bug #1
END IF;
PERFORM net.http_post(url := v_url, body := v_body, headers := ...);
```

Si les GUC PostgreSQL `app.settings.push_function_url` et
`app.settings.service_role_key` ne sont pas configurées sur la base
distante, **le trigger renvoie sans rien faire — pas d'appel à l'EF, pas
de FCM, pas de notif in-app issue de l'EF**.

### 2.3 Côté Edge Function

`supabase/functions/send-push-notification/index.ts`

Fonctionne correctement (auth service-role, FCM v1 OAuth2, vérif prefs,
INSERT notifications avec type `'message'` et `push_sent`).

### 2.4 Côté device Pro (réception)

`lib/main.dart:39-41`

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();   // c'est tout
}
```

`lib/main.dart:126`

```dart
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

`lib/core/realtime/realtime_bootstrap.dart:154-187` — `_registerFcmToken(ref)` :
- requestPermission ✓
- getToken + saveFcmToken ✓
- onTokenRefresh listener (via `_fcmRefreshSub` global) ✓

**Aucun listener `FirebaseMessaging.onMessage` ni `onMessageOpenedApp` ni
`getInitialMessage` n'est branché dans `main.dart`, `app.dart` ou
`realtime_bootstrap.dart`.** La classe `PushNotificationService`
(`lib/shared/utils/push_notification_service.dart`) qui contient ces
handlers **n'est jamais instanciée** :

```
$ grep -rn "PushNotificationService(" lib/
(no match)
```

→ Conséquence : même si l'EF réussit à envoyer le push, sur le device Pro
- foreground : push avalé silencieusement par OS (iOS) ou affiché par
  l'OS (Android FCM auto-display si app en arrière-plan), aucun handler app ;
- tap sur push : ouvre l'app sur le dernier écran, **aucune navigation
  vers la conversation** ;
- cold start sur push : idem, message ignoré.

### 2.5 Realtime in-app (badges live)

`lib/core/realtime/realtime_manager.dart:380-417` — `_subscribeConversations(userId)` :
- `UPDATE conversations` filtré côté client (`if r.client_id == userId || r.pro_id == userId`) ;
- `INSERT messages` filtré côté client (`if senderId != userId`).

Channel **bien souscrit** dès auth event `signedIn` via `realtime_bootstrap`.
RLS (`messages_participant`) limite déjà ce qui transite, donc le filtre
client-side est correct sécuritairement, juste sub-optimal en bande passante.

`lib/features/chat/data/chat_notifier.dart:42-69` :
- Écoute `conversationStream` ✓
- `isAutoDispose: true` → si aucun widget ne `watch` `conversationsProvider`,
  l'écoute s'arrête. La nav bar Pro affiche-t-elle le badge unread via ce
  provider ? Si oui, OK (toujours mounted dans le shell). Si elle utilise
  uniquement `notificationsProvider` (autre source), le live update inbox
  peut être en autodispose silencieux. **À vérifier sur device en Phase A
  follow-up.**

---

## 3. Bugs identifiés (par sévérité)

| # | Sévérité | Fichier | Description courte |
|---|----------|---------|--------------------|
| 1 | **BLOCKER** | DB GUC | `app.settings.push_function_url` / `service_role_key` non configurés → trigger no-op silencieux |
| 2 | **BLOCKER** | migration `20260326121446_remote_schema.sql:934` | Route push hardcodée `/client/messages` — un Pro reçoit un payload pointant sur le shell client |
| 3 | **HIGH** | `lib/main.dart` + `realtime_bootstrap.dart` | Aucun handler `onMessage` / `onMessageOpenedApp` / `getInitialMessage`. `PushNotificationService` jamais instanciée |
| 4 | **HIGH** | `chat_repository.dart:165-172` | INSERT `notifications` côté Flutter en plus du trigger DB → doublons inbox Pro (titre EN + emoji) |
| 5 | MEDIUM | `chat_repository.dart:167` vs EF L98-103 | Type `'new_message'` (Flutter) ≠ `'message'` (EF). `notification_preferences.messages_enabled` ne filtre que la branche EF |
| 6 | MEDIUM | `push_notification_service.dart:91-124` | Routes invalides (`/chat/:id`, `/booking/:id`, `/event/:id`, `/notifications`) — n'existent pas dans GoRouter actuel |
| 7 | LOW | `chat_repository.dart:112,117,159,168` | Strings EN (`'New message from'`, `'Someone'`) + emoji (`'📷 Image'`) — viole règles projet (FR sentence case, pas d'emoji, pas de "!") |
| 8 | LOW | trigger `tr_notify_new_message_push` L909-936 | Ne vérifie pas `notification_preferences` avant d'appeler l'EF (l'EF re-vérifie de toute façon, donc juste inefficient) |
| 9 | LOW | `realtime_manager.dart:380-417` | Filtre client-side au lieu de `PostgresChangeFilter.eq` — RLS protège, mais bande passante gaspillée |
| 10 | INFO | `chat_notifier.dart:69` | `isAutoDispose: true` → vérifier qu'au moins un widget du shell Pro `watch` `conversationsProvider` en permanence (sinon badge inbox cassé) |

---

## 4. Pourquoi ça casse exactement

Cascade complète, du symptôme à la cause racine :

1. **Pro reçoit zéro push** parce que :
   - Soit bug #1 (GUC non set) → `fire_send_push_notification` silently exit, l'EF n'est jamais appelée, FCM jamais envoyé.
   - Soit GUC set mais bug #2 + #3 : push arrive sur le device Pro, mais aucun handler ne le traite (foreground avalé, tap ne navigue nulle part, cold start ignore le initial message).

2. **Pro voit zéro notif in-app pertinente** parce que :
   - Si bug #1 actif : seule la notif insérée par `_notifyRecipient` (Flutter) apparaît. Elle a un titre EN sale et le tap ne navigue nulle part (pas de handler dans `notification_history_screen` qui consomme `data.conversation_id`).
   - Si bug #1 résolu : doublon (1 row Flutter + 1 row EF), expérience cassée mais visible au moins.

3. **Pro inbox ne se met pas à jour live** parce que :
   - Si bug #10 confirmé (autoDispose drop) : le `_subscribeConversations` du `realtime_manager` envoie bien `InboxMessageReceived` dans le stream, mais aucun `Notifier` n'est abonné → l'event tombe dans le vide tant que le Pro n'ouvre pas l'écran messages.
   - À vérifier en runtime — l'archi suggère que le shell Pro garde `conversationsProvider` watched, mais à confirmer.

---

## 5. Fixes proposés (atomiques, à appliquer après validation)

### Commit A — `fix(push): adapt route per recipient role` (bug #2)

Fichier : nouvelle migration `supabase/migrations/<ts>_message_push_route_by_role.sql`

```sql
CREATE OR REPLACE FUNCTION public.tr_notify_new_message_push() ...
DECLARE
  conv public.conversations%ROWTYPE;
  recipient uuid;
  recipient_role text;
  preview text;
  v_route text;
BEGIN
  SELECT * INTO conv FROM public.conversations WHERE id = NEW.conversation_id;
  IF NOT FOUND THEN RETURN NEW; END IF;
  IF NEW.sender_id = conv.client_id THEN
    recipient := conv.pro_id;
  ELSE
    recipient := conv.client_id;
  END IF;
  IF recipient IS NULL OR recipient = NEW.sender_id THEN RETURN NEW; END IF;

  SELECT role INTO recipient_role FROM public.users WHERE id = recipient;
  v_route := CASE WHEN recipient_role = 'pro' THEN '/pro/messages' ELSE '/client/messages' END;

  preview := LEFT(COALESCE(NEW.content, 'Photo'), 140);

  PERFORM public.fire_send_push_notification(
    recipient,
    'Nouveau message',
    preview,
    'message',
    jsonb_build_object(
      'conversationId', NEW.conversation_id::text,
      'route', v_route
    )
  );
  RETURN NEW;
END;
$$;
```

Migration **non auto-appliquée** (règle absolue) — Apollinaire applique
manuellement après revue.

### Commit B — `fix(messages): drop duplicate Flutter notification + sanitize strings` (bugs #4, #5, #7)

Fichier : `lib/features/chat/data/chat_repository.dart`

- Supprimer entièrement `_notifyRecipient()` (la cascade trigger→EF gère déjà notif + push).
- Conserver l'increment `unread_count_*` mais le déplacer dans le trigger
  (ou laisser dans `markRead` pour le reset). Vérification : un trigger
  `tr_unread_count` existe déjà (migration L2266) → l'INSERT `messages` met
  déjà à jour les compteurs, donc le RPC `increment_field` côté Flutter
  est redondant aussi.
- Remplacer `'📷 Image'` par `'Photo'` aux lignes 112 et 117.

### Commit C — `feat(push): wire FCM message handlers` (bugs #3, #6)

Option choisie : **réécrire les handlers dans `realtime_bootstrap.dart`**
(la classe `PushNotificationService` actuelle est dead code avec routes
fausses → la supprimer en même temps).

Ajouter dans `realtime_bootstrap.dart`, à côté de `_registerFcmToken` :

```dart
StreamSubscription<RemoteMessage>? _fcmForegroundSub;
StreamSubscription<RemoteMessage>? _fcmTapSub;

void _wireFcmHandlers(Ref ref) {
  if (_fcmForegroundSub != null) return; // une seule fois

  _fcmForegroundSub = FirebaseMessaging.onMessage.listen((m) {
    // Foreground : push arriving while app is open.
    // Décision UX : SnackBar via un ScaffoldMessengerKey global,
    // pas d'AlertDialog (intrusif).
    _showInAppBanner(m);
  });

  _fcmTapSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
    _navigateFromPushPayload(m.data);
  });

  // Cold start
  FirebaseMessaging.instance.getInitialMessage().then((m) {
    if (m != null) _navigateFromPushPayload(m.data);
  });

  ref.onDispose(() {
    _fcmForegroundSub?.cancel(); _fcmForegroundSub = null;
    _fcmTapSub?.cancel(); _fcmTapSub = null;
  });
}

void _navigateFromPushPayload(Map<String, dynamic> data) {
  final route = data['route'] as String?;
  if (route == null) return;
  // Utilise le router root via un GlobalKey<NavigatorState> exposé
  // depuis app.dart, ou un ref.read(routerProvider).
  rootNavigatorKey.currentContext?.go(route);
}
```

Ajouter `_wireFcmHandlers(ref)` dans le bloc `case AuthChangeEvent.signedIn` à
côté de `_registerFcmToken(ref)`.

Supprimer `lib/shared/utils/push_notification_service.dart` (dead code,
routes fausses).

### Commit D — `chore(infra): documenter GUC push` (bug #1)

Ajouter à `docs/APOLLINAIRE_TODO.md` une nouvelle section :

> **Configurer GUC PostgreSQL pour push (BLOCKER prod)**
>
> Sans ces deux paramètres, **aucun trigger DB ne déclenche le push** :
>
> ```sql
> ALTER DATABASE postgres SET app.settings.push_function_url = 'https://<project-ref>.supabase.co/functions/v1/send-push-notification';
> ALTER DATABASE postgres SET app.settings.service_role_key = '<service_role_key>';
> ```
>
> À exécuter via le SQL editor Supabase (les `ALTER DATABASE` ne sont pas
> versionnés dans `supabase/migrations/` car ils touchent à des secrets).
> Vérifier : `SELECT current_setting('app.settings.push_function_url', true);`

### Commit E (optionnel) — `chore(realtime): server-side filter on messages` (bug #9)

Remplacer le filtre client-side par `PostgresChangeFilter` :

```dart
.onPostgresChanges(
  event: PostgresChangeEvent.insert,
  schema: 'public',
  table: 'messages',
  filter: PostgresChangeFilter(
    type: PostgresChangeFilterType.neq,
    column: 'sender_id',
    value: userId,
  ),
  callback: (payload) { /* … */ },
)
```

Mais ne filtre pas par participant — il faudrait un view ou sub combiné.
À considérer plus tard, pas bloquant v1.0.

---

## 6. Vérifications runtime à faire avant fix

Pour confirmer la cascade des bugs avant d'appliquer :

1. **Sur la DB distante**, exécuter :
   ```sql
   SELECT current_setting('app.settings.push_function_url', true) AS url,
          current_setting('app.settings.service_role_key', true) IS NOT NULL AS has_key;
   ```
   Si `url` est NULL → bug #1 confirmé, c'est la cause #1. Sinon écarter.

2. **Sur device Pro** (avec un client réel testant) :
   - Vérifier `users.fcm_token` rempli pour le compte Pro
     (`SELECT id, role, fcm_token IS NOT NULL FROM users WHERE id = '<pro_uid>';`)
   - Tail logs de l'EF `send-push-notification` pendant l'envoi du message
     → si invocation observée mais FCM 404/UNREGISTERED, c'est un token
     stale, pas un bug code.
   - Si invocation jamais observée → bug #1 (GUC).

3. **Sur device Pro** (app au foreground) : envoyer message client →
   actuellement aucun banner = bug #3 confirmé.

4. **Sur device Pro** (app fermée, tap sur push si reçu) : actuellement
   atterrit sur dernier écran = bug #2 + #3 confirmés.

---

## 7. Hors-scope mentionné mais OK

- RLS messages : `messages_participant` (migration L2765) est correct,
  Pro peut bien SELECT les messages où il est participant via la
  conversation. Pas un bug.
- Publication realtime : `messages`, `conversations`, `notifications` sont
  bien dans `supabase_realtime` (migration L3088-3180). Pas un bug.
- FCM token registration : fonctionne (`realtime_bootstrap.dart:154-187`),
  contrairement à ce que le rapport initial suggérait.

---

## 8. Décisions à valider avant Commit

Avant d'appliquer les commits A-D, je demande validation explicite sur :

1. **Migration ou hotfix SQL ?** Le bug #2 nécessite de toucher une
   fonction PL/pgSQL existante. Préférence : nouvelle migration timestampée
   + apply manuel par Apollinaire. Confirmer.
2. **Suppression `PushNotificationService`** : OK pour killer la classe
   complètement et tout réécrire dans `realtime_bootstrap.dart` ? Ou
   garder le fichier et le brancher ?
3. **In-app foreground UX** : SnackBar via un `scaffoldMessengerKey`
   global, AlertDialog, ou Banner Material ? La règle « pas d'emoji, pas
   de ! » est respectée dans tous les cas — c'est la forme du widget qui
   change.
4. **Suppression de `_notifyRecipient` côté Flutter** : confirme que tu
   acceptes que la notif inbox ne soit créée QUE par l'EF (donc
   conditionnelle à la résolution de bug #1 — sinon temporairement, un
   Pro avec GUC non set ne verra rien). Alternative : garder l'INSERT
   Flutter avec type `'message'` (cohérent avec EF) en attendant que
   GUC soit set, puis le retirer.

---

**Fin du diagnostic. Aucune modification de code, migration, ou EF
appliquée. En attente de ta validation sur la sévérité, l'ordre des
commits, et les 4 décisions de §8.**
