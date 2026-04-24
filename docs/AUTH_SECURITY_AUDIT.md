# AUDIT — Sécurité auth + isolation de session

**Date** : 2026-04-24
**Branche** : `agent/refonte-totale-premium`
**Périmètre** : Vérifier qu'un logout purge intégralement la session locale et
qu'un user B qui se logue après un user A ne peut JAMAIS voir / agir sur les
données de A. Bug rapporté en prod (iPhone Papi) : « je choisis Client à la
connexion, ça m'ouvre quand même le compte Pro ».

---

## Résumé exécutif

| Zone | Statut |
|------|--------|
| 1. Purge Keychain / SharedPrefs | ✅ |
| 2. Supabase signOut scope global + fallback | ✅ |
| 3. Riverpod cache invalidation entre users | ✅ |
| 4. Realtime channels unsubscribe | ✅ |
| 5. FCM token purge (DB + device) | ✅ |
| 6. GoRouter post-logout redirect | ⚠️ |
| 7. OAuth metadata isolation (rôle) | ❌ |

**Verdict** : 5/7 zones solides. **Deux bugs** liés à la même cause racine —
le rôle est lu depuis `auth.currentUser.userMetadata['role']` à deux endroits
critiques (router redirect + splash screen) alors que CLAUDE.md précise
explicitement que ce champ est **non fiable pour Google OAuth** et **éditable
par l'utilisateur**. La source de vérité (`public.users.role`) n'est consultée
que par `realtime_bootstrap`.

**Action requise** : commit unique de fix (Phase B-bis) avant de passer à
Phase C, OU Apollinaire peut décider d'accepter la dette et la planifier
post-launch.

---

## Zone 1 — Purge Keychain / SharedPreferences

**Status** : ✅ **SOLIDE**

**Fichiers** :
- `lib/shared/utils/secure_auth_storage.dart` (Keychain backing iOS / Keystore
  Android pour la session Supabase)
- `lib/features/auth/data/auth_repository.dart` L429-438 (`finally
  _secureStorage.deleteAll()`)

**Mécanique** :
1. `clearAuthKeychainIfFreshInstall()` purge le Keychain au PREMIER boot
   d'une install fraîche (détecté via flag SharedPreferences absent — wipé
   à l'uninstall, contrairement au Keychain iOS qui survit).
2. `signOut()` finit toujours par `_secureStorage.deleteAll()` dans un
   `finally`, peu importe si l'appel `signOut(global)` ou `signOut(local)`
   a planté.

**Pourquoi c'est solide** : la source de vérité de la session persistée
(Keychain) est purgée **systématiquement**. Sans le `finally`, un échec
réseau au `signOut(global)` aurait laissé le refresh token dans le Keychain
→ ré-hydratation au prochain boot.

---

## Zone 2 — Supabase signOut scope global + fallback

**Status** : ✅ **SOLIDE**

**Fichier** : `lib/features/auth/data/auth_repository.dart` L420-428

**Mécanique** :
```dart
try {
  await _supabase.auth.signOut(scope: SignOutScope.global); // révoque tous devices
} catch (_) {
  try {
    await _supabase.auth.signOut(scope: SignOutScope.local); // au moins purger local
  } catch (_) {
    // _secureStorage.deleteAll() ci-dessous prendra le relais
  }
}
```

**Pourquoi c'est solide** : 3 niveaux de défense (global → local → Keychain
deleteAll). `SignOutScope.global` invalide aussi les sessions sur les autres
devices (refresh token révoqué côté Supabase). Le fallback local couvre les
cas offline / 5xx.

---

## Zone 3 — Riverpod cache invalidation entre users

**Status** : ✅ **SOLIDE** (par sémantique autoDispose)

**Fichiers vérifiés** :
- `lib/features/feed/data/feed_notifier.dart:340` — `isAutoDispose: true`
- `lib/features/feed/data/discover_notifier.dart:203` — `isAutoDispose: true`
- `lib/features/feed/data/my_videos_notifier.dart:26` — `isAutoDispose: true`
- `lib/features/notifications/data/notification_notifier.dart:117,168` — `isAutoDispose: true`
- `lib/features/favorites/data/favorite_notifier.dart:65,119` — `isAutoDispose: true`
- `lib/features/events/data/event_notifier.dart:60,117,251` — `isAutoDispose: true`
- `lib/features/chat/data/chat_notifier.dart:69,210` — `isAutoDispose: true`

**Mécanique** : Tous les providers qui cachent des données user-specific
sont `autoDispose`. Quand `signOut()` → `context.go('/login')` détruit l'arbre
authentifié (ClientShell / ProShell), les listeners se détachent → providers
disposés → state vidé. Le user B logue → rebuild des shells → providers
ré-instanciés → fetch initial avec le NOUVEAU `auth.currentUserId`.

**Note** : ni `signOut()` ni les 4 sites d'appel (`client_profile_screen`,
`pro_shell_profile_screen`, `provider_settings_screen`, `settings_screen`)
ne font de `ref.invalidate(...)` explicite. C'est volontaire — la
sémantique `autoDispose` rend l'opération inutile et l'oubli sans
conséquence.

**Risque résiduel** : si un nouveau provider est introduit en tant que
`NotifierProvider` non-autoDispose et cache un userId, il y aurait bleed.
Garde-fou recommandé : code-review check-list (cf. §Recommandations).

---

## Zone 4 — Realtime channels unsubscribe

**Status** : ✅ **SOLIDE**

**Fichiers** :
- `lib/core/realtime/realtime_bootstrap.dart` L92-100 (signedOut event)
- `lib/features/auth/data/auth_repository.dart` L404-408 (`removeAllChannels`)

**Mécanique** :
1. `auth.signOut()` émet `AuthChangeEvent.signedOut`.
2. `realtimeBootstrapProvider` réagit → `manager.tearDown()` qui détruit
   les channels mais préserve les `StreamControllers` (soft teardown,
   permet un re-login dans la même session app sans perdre les listeners).
3. En parallèle dans `signOut()`, `_supabase.removeAllChannels()` enlève
   aussi les channels au cas où.

**Note** : `realtimeBootstrapProvider` est un `Provider<void>` keep-alive
(jamais autoDispose) — c'est volontaire pour qu'il reste attentif à
`onAuthStateChange` toute la durée de l'app.

---

## Zone 5 — FCM token purge (DB + device)

**Status** : ✅ **SOLIDE**

**Fichier** : `lib/features/auth/data/auth_repository.dart` L383-402

**Mécanique** :
```dart
// 1. Purger users.fcm_token AVANT de perdre RLS write-access
await _supabase.from('users').update({'fcm_token': null}).eq('id', uid);

// 2. Rotater le token côté device — le cached APNs/FCM token devient invalide
await FirebaseMessaging.instance.deleteToken();
```

**Pourquoi c'est solide** : sans la step 1, après signOut le device garderait
sa ligne `users.fcm_token` valide → l'ex-user continuerait à recevoir les
pushes destinées à son compte tant qu'il n'y a pas de re-login sur ce device.
La step 2 force FCM à régénérer un token au prochain `getToken()` → impossible
de target l'ancien device par erreur.

**Re-registration** : au login suivant, `realtime_bootstrap._registerFcmToken`
re-appelle `getToken()` (nouveau token) + `saveFcmToken()` (DB).

---

## Zone 6 — GoRouter post-logout redirect

**Status** : ⚠️ **PARTIEL — fonctionne par convention, pas par mécanisme**

**Fichier** : `lib/router/app_router.dart` L121-168

**Constat** :
- Le router lit `Supabase.instance.client.auth.currentSession` **synchrone**
  dans `redirect`. Pas de `refreshListenable`.
- Conséquence : `signOut()` ne déclenche pas automatiquement de
  re-évaluation du router.
- **Le logout ne fonctionne QUE parce que les 4 sites d'appel ajoutent
  manuellement `context.go('/login')` après `signOut()` :**
  - `lib/features/profile/presentation/screens/client_profile_screen.dart:811`
  - `lib/features/profile/presentation/screens/pro_shell_profile_screen.dart:2116`
  - `lib/features/profile/presentation/screens/provider_settings_screen.dart:626`
  - `lib/features/settings/presentation/screens/settings_screen.dart:295`

**Risque** :
- Si un nouveau site d'appel oublie le `context.go('/login')`, l'écran
  authentifié reste affiché alors que la session est purgée → exception
  RLS au prochain fetch, écran cassé.
- Si une session expire **passivement** (refresh token révoqué côté serveur,
  Supabase émet `signedOut`), le router ne réagit pas → l'utilisateur
  reste bloqué sur un écran mort jusqu'à un cold restart.

**Recommandation** :
- Soit ajouter un `refreshListenable` sur `authStateProvider` pour que le
  router re-évalue automatiquement à chaque `signedOut`.
- Soit documenter en haut de `app_router.dart` que tout site de logout
  DOIT faire `context.go('/login')` manuellement (et code-review check).

**Sévérité** : moyenne. Pas de bleed de données entre users (Zone 3 est
solide), mais UX dégradée si oubli ou session passive expirée.

---

## Zone 7 — OAuth metadata isolation (rôle)

**Status** : ❌ **BUG CONFIRMÉ — c'est très probablement la cause racine
du symptôme « login client ouvre compte pro »**

### Bug 7a — Splash redirect basé sur userMetadata

**Fichier** : `lib/features/auth/presentation/screens/splash_screen.dart` L113-120

```dart
switch (repo.currentUserRole) {  // = currentUser?.userMetadata?['role']
  case 'client':
    context.go('/client/feed');
  case 'pro':
    context.go('/pro/feed');
  default:
    context.go('/select-account-type');  // ← fallback pour metadata absent
}
```

**Problème** :
- CLAUDE.md (commenté dans `realtime_bootstrap.dart` L72-76) :
  > `user.userMetadata['role'] is unreliable: not populated on Google OAuth
  > sign-ins, and is editable by the user anyway (security best practice:
  > never base authorization on user_metadata).`
- Pour un Pro qui s'est inscrit via Google (donc sans payload `data: {role}`
  envoyé au signUp), `userMetadata['role']` est **null** au cold start
  suivant → splash redirige vers `/select-account-type` au lieu de
  `/pro/feed`.
- Si l'utilisateur ré-clique « Pro » sur RoleSelectionScreen, ça écrase peut-être
  la valeur DB ou ça crée un conflit UI/DB. À vérifier (cf. RoleSelectionScreen).

### Bug 7b — Router redirect basé sur userMetadata

**Fichier** : `lib/router/app_router.dart` L140-144

```dart
if (session != null && isAuthOnlyPath) {
  final role = Supabase.instance.client.auth.currentUser
          ?.userMetadata?['role'] as String?;
  return role == 'pro' ? '/pro/feed' : '/client/feed';
}
```

**Problème** : même cause. Un Pro Google-OAuth qui revisite `/login` se fait
rediriger vers `/client/feed` (fallback `else`) au lieu de `/pro/feed`.

**Symptôme prod (iPhone Papi)** : « je choisis Client à la connexion, ça
m'ouvre quand même le compte Pro ». Mécanisme probable :
1. Papi a un compte Pro pré-existant avec session encore valide en Keychain.
2. Au boot, splash voit la session active.
3. Splash lit `userMetadata['role']` → **'pro'** (parce que ce compte a été
   créé via email avec payload `data: {role: 'pro'}` au signUp historique).
4. Redirige vers `/pro/feed` → « ça m'ouvre le compte Pro » alors que Papi
   pensait avoir choisi « Client » au moment du login Email/Password
   (mais en réalité on n'a JAMAIS demandé son rôle pendant le login —
   seul le signup a un payload `role`).

Note : ce symptôme spécifique est **résolu côté UX** par le fait que
`signOut()` purge bien le Keychain (Zone 1+2), donc un vrai re-login
(déconnexion + nouveau login Email/Password avec un autre compte) n'a plus
le bug. Le bug n'apparaît QUE si Papi pense qu'il s'est déconnecté alors
qu'il n'a fait que fermer/rouvrir l'app.

### Source de vérité — déjà utilisée ailleurs

`realtime_bootstrap._fetchUserRole(userId)` (L133-145) lit `public.users.role`
authoritatively. C'est **ce pattern** qu'il faut propager à Splash + Router.

### Fix proposé (Phase B-bis, hors scope du présent audit)

1. **Splash** : remplacer `repo.currentUserRole` par un `ref.read(...)`
   asynchrone qui fetch `public.users.role` (idem `_fetchUserRole`). Si
   null → `/select-account-type`. Sinon → feed correspondant.
2. **Router** : même pattern. Comme `redirect` est synchrone, on doit soit :
   - Créer un `roleProvider` qui cache la dernière valeur fetchée par
     `realtime_bootstrap` (autoritaire, mise à jour à chaque signedIn),
     que le router lit sync.
   - OU déplacer la logique de redirect dans le widget enfant (post-mount)
     qui peut faire un fetch async.

**Sévérité** : haute pour Google/Apple OAuth users. Faible pour Email/
Password users (qui ont `role` dans leur metadata depuis signUp).

---

## Recommandations

### À fixer avant launch (Phase B-bis)

1. **Bug 7a + 7b** : router + splash doivent lire le rôle depuis
   `public.users.role`, pas `userMetadata['role']`. Pattern déjà éprouvé
   dans `realtime_bootstrap._fetchUserRole`.

### À considérer (peut être post-launch)

2. **Zone 6** : ajouter un `refreshListenable` sur le router pour qu'il
   réagisse à `signedOut` même sans `context.go('/login')` explicite. OU
   commentaire dans `auth_repository.signOut()` rappelant que tout caller
   doit naviguer manuellement après.

3. **Zone 3 — garde-fou code-review** : pour tout nouveau provider qui
   cache de la donnée user-specific, exiger `isAutoDispose: true`. Possible
   à enforcer via une analyse statique custom si on veut être paranos.

### Tests d'acceptation à exécuter (cf. APOLLINAIRE_TODO §B)

| # | Scénario | Attendu |
|---|----------|---------|
| 1 | User Pro (email) signOut → re-login User Client (email) sur le même device | Aucune donnée Pro visible. Notifications Client fraîches. |
| 2 | User Pro (Google) cold start | Atterrit sur `/pro/feed`, pas `/select-account-type`. ❌ casse aujourd'hui |
| 3 | User Pro signOut → kill app → reopen | Atterrit sur `/login`, jamais sur un écran Pro. |
| 4 | Pro logué reçoit un push pendant que device A est offline → device A vient online après signOut | Push n'est PAS livré (FCM token DB null). |
| 5 | User A logué sur device 1 et device 2 → User A signOut sur device 1 | Device 2 voit sa session expirée au prochain fetch (révocation refresh token via `SignOutScope.global`). |
| 6 | User Pro édite manuellement `userMetadata.role = 'admin'` via Supabase JS console (paranoïa) | Aucune route admin n'apparaît côté Flutter (parce qu'on ne lit jamais le rôle pour de l'autorisation, juste pour le routing — les RLS DB sont la vraie barrière). À confirmer côté RLS. |

---

## Annexes

### A — Liste des sites de signOut

```
lib/features/profile/presentation/screens/client_profile_screen.dart:811
lib/features/profile/presentation/screens/pro_shell_profile_screen.dart:2116
lib/features/profile/presentation/screens/provider_settings_screen.dart:626
lib/features/settings/presentation/screens/settings_screen.dart:295
lib/features/auth/data/auth_repository.dart:556  (deleteAccount)
lib/features/auth/data/auth_repository.dart:566  (deleteAccount fallback)
```

### B — Providers user-specific vérifiés autoDispose

Tous OK : `feedProvider`, `discoverProvider`, `myVideosProvider`,
`notificationsProvider`, `notifPrefsProvider`, `favoriteIdsProvider`,
`eventsProvider`, `buyTicketProvider`, `chatProvider`, `conversationsProvider`.

### C — Fichiers analysés

```
lib/features/auth/data/auth_repository.dart           (625 lignes)
lib/shared/utils/secure_auth_storage.dart
lib/router/app_router.dart                            (1060 lignes)
lib/core/realtime/realtime_bootstrap.dart
lib/shared/utils/push_notification_service.dart
lib/features/auth/presentation/screens/splash_screen.dart
lib/features/chat/data/chat_notifier.dart
+ grep transversal isAutoDispose sur 24 NotifierProvider
```
