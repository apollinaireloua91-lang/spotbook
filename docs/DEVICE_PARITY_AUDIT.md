# DEVICE_PARITY_AUDIT

**Mission** — Parité iPhone physique ↔ simulateur iOS.
**Branche** — `agent/refonte-totale-premium`
**Date** — 2026-04-21
**Device référence** — iPhone papi, iOS 26.2.1

## Méthode

Reconnaissance du code d'authentification, du bootstrap user, du logout, des
permissions iOS et du feed temps réel. Les bugs remontés par le user ne sont
pas traités un-à-un : ils sont regroupés en **5 patterns racines**. Chaque
pattern a 1 fix structurel qui éteint plusieurs symptômes à la fois.

Les bugs confirmés :
1. Écran fantôme "Not signed in" en anglais
2. Login Client qui ouvre le compte Pro précédent (Keychain persisté)
3. Onboarding non re-joué après désinstallation
4. Google Sign-In → profil vide (full_name / avatar_url NULL)
5. "Failed to update like" en anglais sur feed Pro

---

## Pattern 1 — Fragmentation du logout (4 entry points, 2 comportements)

### Symptômes couverts
- Bug #2 (Client ouvre le compte Pro précédent)
- Logout qui laisse traîner des channels Realtime actifs
- Token Google non révoqué → "Sign in with Google" reproduit auto le même compte

### Preuve code
`grep` sur `signOut\(\)` dans `lib/` :

| Fichier | Ligne | Implémentation |
|---|---|---|
| `lib/features/auth/data/auth_repository.dart` | 311-327 | audit_log + `removeAllChannels()` + `supabase.auth.signOut()` + `secureStorage.deleteAll()` |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 295 | `ref.read(authRepositoryProvider).signOut()` ✅ |
| `lib/features/profile/presentation/screens/pro_shell_profile_screen.dart` | 2074 | `ref.read(authRepositoryProvider).signOut()` ✅ |
| `lib/features/profile/presentation/screens/provider_settings_screen.dart` | 625 | `ref.read(authRepositoryProvider).signOut()` ✅ |
| `lib/features/profile/presentation/screens/client_profile_screen.dart` | 794-800 | **Bypass repo** : wipe Hive `settings`/`app_settings`/`search_history` + raw `Supabase.instance.client.auth.signOut()` ❌ |

### Ce qui manque dans TOUS les chemins (même le chemin repo)
- `SignOutScope.global` — le logout actuel est `local`, le refresh token reste
  valide côté Supabase. Sur un autre device, la session survit.
- `GoogleSignIn().signOut()` + `.disconnect()` — le token Google cache côté
  iOS. Prochain tap sur "Continuer avec Google" reconnecte silencieusement
  le même compte sans fenêtre de sélection.
- Purge du token FCM (`FirebaseMessaging.instance.deleteToken()`) — le device
  continue à recevoir les pushes destinées à l'ex-user.
- `ref.invalidate(...)` des providers de données dépendants de l'uid. Les
  `FutureProvider.family` / `AsyncNotifier` gardent le cache de l'ex-user en
  mémoire → le feed/profil affiche brièvement les données du Pro précédent
  avant reload.

### Bug #2 — mécanisme exact
1. User Pro logout depuis `client_profile_screen` (chemin bypass).
2. Hive `settings` est clear. `secureStorage` **n'est PAS** clear (bypass du
   repo). La session Keychain (`first_unlock_this_device`) survit.
3. `supabase.auth.signOut()` avec scope `local` (défaut) → le client
   Supabase nettoie sa session locale mais les tokens persistés dans la
   surface `LocalStorage` (notre `SecureAuthStorage`) **ne sont pas purgés
   par le bypass**.
4. Au prochain login Client, `currentSession` au démarrage retrouve les
   tokens Keychain → l'AuthBloc considère que la session précédente est
   active → redirection `/pro/feed`.

### Fix proposé (1 commit)
Centraliser dans `AuthRepository.signOut()` :

```dart
Future<void> signOut() async {
  final uid = currentUserId;
  if (uid != null) {
    // audit log (inchangé)
  }

  // 1. Purger les dépendances externes AVANT de couper la session.
  try {
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {}
  try {
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }
  } catch (_) {}

  // 2. Couper Realtime + session globale.
  await _supabase.removeAllChannels();
  await _supabase.auth.signOut(scope: SignOutScope.global);

  // 3. Purger le stockage local.
  await _secureStorage.deleteAll();
}
```

Et dans `client_profile_screen.dart:790-800`, remplacer le bypass par
`await ref.read(authRepositoryProvider).signOut();`.

Invalidation Riverpod : déplacer le `router.go('/login')` derrière un
`ref.invalidate(profileRepositoryProvider)` + autres providers de données
(feed, social, messages) — à faire au niveau de l'appelant (pas du repo)
car Riverpod n'est pas disponible dans la couche data.

**Fichiers touchés** : 2 (auth_repository.dart, client_profile_screen.dart).
Éventuellement 3 si on ajoute un helper `_signOutAndClearState(WidgetRef)`
partagé entre les 4 entry points.

---

## Pattern 2 — Profile bootstrap : mapping OAuth → `users` incohérent

### Symptômes couverts
- Bug #4 (Google profil vide — `full_name` et `avatar_url` NULL en DB)

### Preuve code
`lib/features/auth/data/user_setup_repository.dart:70,78` :

```dart
'full_name': meta['full_name'],
...
'avatar_url': meta['avatar_url'],
```

`meta` = `user.userMetadata`. Valeurs réelles selon provider :

| Provider | `full_name` key | `avatar_url` key |
|---|---|---|
| Email/Password | `full_name` (on le passe nous-mêmes dans `signUpWithEmail`) | N/A |
| Apple | `full_name` (on l'écrit nous-mêmes dans `signInWithApple:242-253`) | N/A |
| **Google** | **`name`** (Supabase mappe le `name` claim du ID token) | **`picture`** |

→ Pour Google, `meta['full_name']` et `meta['avatar_url']` sont `null`
  → UPSERT `users` insère `full_name=NULL, avatar_url=NULL` → profil vide.

### Fix proposé (1 commit)
Dans `user_setup_repository.dart`, ajouter un fallback :

```dart
final fullName = (meta['full_name'] as String?)
    ?? (meta['name'] as String?)
    ?? (meta['full_name_google'] as String?);
final avatarUrl = (meta['avatar_url'] as String?)
    ?? (meta['picture'] as String?);
```

puis utiliser `fullName` / `avatarUrl` dans l'UPSERT.

Aussi : retirer le `if (existing != null) return;` aveugle ligne 49 et le
remplacer par une mise à jour conditionnelle des champs manquants — sinon
un user créé avant ce fix restera vide à vie.

**Fichiers touchés** : 1 (`user_setup_repository.dart`).

---

## Pattern 3 — Redirections "Not signed in" en anglais / dead-end

### Symptômes couverts
- Bug #1 (écran fantôme EN)

### Preuve code
`Text(l.notSignedIn)` était le fallback historique sur `pro_shell_profile_screen`,
`pro_my_events_screen`, peut-être d'autres. Déjà remplacé dans 2 écrans par
`AuthRequiredRedirect` (commits `a0356dd`, `a6e2641`). Il reste à auditer
les autres écrans qui lisaient `currentUserId` ou `session` et avaient un
fallback texte.

### Reste à faire
`grep -rn "notSignedIn\|Not signed in\|currentUserId == null" lib/` pour
lister les sites restants. Remplacer partout par `const AuthRequiredRedirect()`
(FR + redirection adaptative déjà en place).

### Fix proposé
1 commit groupé `fix(auth): generalize AuthRequiredRedirect across screens`.

---

## Pattern 4 — Permissions iOS : strings Info.plist en anglais

### Symptômes couverts
- Une dialog iOS native en anglais sur un build FR

### Preuve code
`ios/Runner/Info.plist:77` :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Spotbook needs your location to show nearby pros on the map</string>
```

Les autres (camera, mic, photos) sont bien en FR. Celui-ci est passé à
travers les mailles.

### Fix proposé (1 commit)
Remplacer par `Spotbook a besoin de votre localisation pour afficher les
pros proches sur la carte.`

**Bonus** : vérifier que `ios/Runner/InfoPlist.strings` (localisation fr)
existe. Si non, documenter dans `APOLLINAIRE_TODO.md` §permissions qu'il
faut créer `fr.lproj/InfoPlist.strings` pour proprement localiser ces
dialogs côté iOS natif (la chaîne Info.plist est le fallback).

**Fichiers touchés** : 1 (`ios/Runner/Info.plist`). +1 optionnel pour la
localisation propre.

---

## Pattern 5 — Feed error UX asymétrique (Riverpod silencieux vs Cubit anglais)

### Symptômes couverts
- Bug #5 ("Failed to update like" en anglais sur feed Pro)
- Erreurs silencieuses sur feed Client (état revert sans feedback user)

### Preuve code

**Cubit Pro** — `lib/features/pro/presentation/feed/cubit/pro_feed_cubit.dart:189-193` :
```dart
} catch (e, st) {
  _reportCubitError('toggleLike', e, st);
  _updateVideoAt(index, v);
  if (!isClosed) emit(state.copyWith(error: 'like_failed'));
}
```
Et `pro_feed_screen.dart:80` :
```dart
? 'Failed to update like'  // ← EN hardcodé
```

**Notifier Client** — `lib/features/feed/data/feed_notifier.dart:206` :
```dart
(liked ? repo.likeVideo(v.id) : repo.unlikeVideo(v.id)).catchError((_) {
  // Rollback on error — ZÉRO feedback user
});
```

Deux problèmes :
1. **Inconsistance** : Pro voit un message, Client ne voit rien.
2. **l10n** : le message Pro est hardcodé en EN.
3. **Cause racine probable** : le `.catchError` avale `PostgrestException` /
   `AuthException`, donc on ne voit jamais le vrai problème (RLS denied
   après refresh token expiré est un suspect récurrent).

### Fix proposé (1 commit)
a) Ajouter des clés ARB `feedLikeFailed`, `feedSaveFailed`, `feedFollowFailed`.
   Les afficher via `ScaffoldMessenger` sur les deux chemins.
b) Remplacer `catchError((_))` dans `feed_notifier.dart` par un catch typé
   qui logge via Sentry (`_reportFeedError`) et affiche le SnackBar FR.
c) Remplir le helper `_reportCubitError` déjà présent — l'utiliser dans le
   catch au lieu de `_reportCubitError + emit(error:)` séparés.

**Fichiers touchés** : 4 — `feed_notifier.dart`, `pro_feed_cubit.dart`,
`pro_feed_screen.dart` (feed), `app_en.arb` + `app_fr.arb`.

---

## Plan d'exécution (atomic commits)

| # | Scope | Pattern | Estimation |
|---|---|---|---|
| 1 | `fix(auth): unify signOut — global scope, Google/FCM purge, Riverpod invalidation` | 1 | M |
| 2 | `fix(auth): backfill full_name/avatar_url from Google OAuth metadata` | 2 | S |
| 3 | `fix(auth): generalize AuthRequiredRedirect across remaining screens` | 3 | S |
| 4 | `fix(ios): translate NSLocationWhenInUseUsageDescription to FR` | 4 | XS |
| 5 | `fix(feed): FR error SnackBar on like/save/follow failure, both Riverpod & Cubit paths` | 5 | M |

Entre chaque commit : `flutter analyze` = 0 obligatoire.
Pas de deploy. Pas de `git push`. Pas de `supabase db push`.

## Ce que l'audit n'a PAS couvert (à faire dans une passe 2)

- Booking flow (step4_summary, step5_payment) — des modifs uncommitted
  pendantes dans `git status`
- Stripe Connect onboarding sur device physique (deep link `return_url`)
- Messagerie Realtime : les channels sont-ils bien rebuild après rotation
  d'écran / background-foreground ?
- Push notifications APNs : le token est-il bien rotaté à chaque login ?
- Contrôles caméra / micro sur iPhone physique (les sims sont mockés)
- POS flow sur device physique (NFC/Bluetooth)
