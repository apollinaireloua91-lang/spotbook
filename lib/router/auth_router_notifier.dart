import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cache du rôle utilisateur courant (`'client'` ou `'pro'`) lu de manière
/// AUTORITAIRE depuis `public.users.role`, exposé en lecture synchrone pour
/// les `redirect` de [GoRouter] (qui ne peuvent pas être asynchrones).
///
/// Pourquoi
/// ────────
/// Avant 2026-04-24, le router et le splash lisaient le rôle depuis
/// `auth.currentUser.userMetadata['role']`. Ce champ est :
///   * NULL pour les inscriptions OAuth (Google, Apple) — Supabase ne le
///     propage pas tant qu'on ne fait pas un `signUp` avec `data: {role}` ;
///   * éditable par l'utilisateur (security best practice : ne JAMAIS baser
///     d'autorisation dessus).
///
/// Symptôme observé en prod (Bugs 7a + 7b dans `docs/AUTH_SECURITY_AUDIT.md`) :
/// un Pro inscrit via Google atterrissait sur `/select-account-type` au cold
/// start au lieu de `/pro/feed`, et le redirect post-login le renvoyait vers
/// `/client/feed`.
///
/// Source de vérité
/// ────────────────
/// `public.users.role` (déjà utilisée par
/// `realtime_bootstrap._fetchUserRole`). Cette classe centralise la valeur
/// pour que **router + splash + bootstrap** la lisent de la même façon.
///
/// Refresh listenable
/// ──────────────────
/// Implémente [ChangeNotifier] pour servir de `refreshListenable` au
/// [GoRouter]. Notifie sur :
///   * tout `AuthChangeEvent` (signedIn, signedOut, tokenRefreshed,
///     userUpdated, initialSession) → le router ré-évalue ses redirects
///     même quand la session expire passivement (ce qui n'était pas géré
///     avant — cf. zone 6 de l'audit) ;
///   * tout changement de rôle pushé via [setRole] (par bootstrap après
///     `_fetchUserRole` ou par splash après son fetch initial).
class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier._();

  /// Singleton — instancié à l'import. Pas d'état tant que [start] n'a pas
  /// été appelé après `Supabase.initialize` (cf. `app.dart` initState).
  static final AuthRouterNotifier instance = AuthRouterNotifier._();

  String? _role;
  StreamSubscription<AuthState>? _authSub;

  /// Rôle courant (`'client'`, `'pro'`, ou `null` si pas connecté ou pas
  /// encore fetché). Lu **synchrone** par le router et le splash.
  String? get role => _role;

  /// À appeler une seule fois après `Supabase.initialize` (depuis
  /// `app.dart`). Idempotent : un second appel est no-op.
  void start() {
    if (_authSub != null) return;
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      // Sur signOut, le rôle cached devient invalide. On le purge AVANT de
      // notifier pour que le router voie un état cohérent (session=null,
      // role=null) au moment de re-évaluer ses redirects.
      if (event.event == AuthChangeEvent.signedOut) {
        _role = null;
      }
      // Notifier inconditionnel : permet au router de réagir aux expirations
      // passives (refresh token révoqué côté serveur → Supabase émet
      // signedOut sans qu'on l'ait demandé).
      notifyListeners();
    });
  }

  /// Met à jour le rôle cached et notifie les listeners (le router en
  /// particulier). Appelé par `realtime_bootstrap._fetchUserRole` et par le
  /// splash après leur fetch authoritatif.
  ///
  /// No-op si la valeur ne change pas → évite des rebuild inutiles du router.
  void setRole(String? role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _authSub = null;
    super.dispose();
  }
}
