import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

/// Écran de transition qui redirige silencieusement au prochain frame
/// selon l'état réel de la session Supabase.
///
/// - Pas de session → `/login`
/// - Session valide (mais la page appelante a jugé que l'user ne peut
///   pas être servi — typiquement ligne `users` manquante après Google
///   OAuth) → `/select-account-type` pour que le flow role/setup redémarre.
///
/// On décide la destination **ici** et pas via `context.go('/login')`
/// systématique, car le redirect global du `GoRouter` bounce les users
/// avec session vers `/pro/feed` → boucle infinie si la page feed
/// re-déclenche un état où le profil est introuvable.
class AuthRequiredRedirect extends StatefulWidget {
  const AuthRequiredRedirect({super.key, this.overrideDestination});

  /// Force la destination (utile pour les cas où l'appelant sait déjà
  /// où envoyer l'user — ex: onboarding pas terminé → `/onboarding`).
  /// Si null, la destination est calculée depuis la session courante.
  final String? overrideDestination;

  @override
  State<AuthRequiredRedirect> createState() => _AuthRequiredRedirectState();
}

class _AuthRequiredRedirectState extends State<AuthRequiredRedirect> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback : on ne peut pas appeler context.go() pendant
    // un build (ça explose GoRouter avec « setState during build »).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final destination = widget.overrideDestination ?? _resolveDestination();
      if (kDebugMode) {
        debugPrint('AuthRequiredRedirect → $destination');
      }
      context.go(destination);
    });
  }

  String _resolveDestination() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return '/login';
    // Session valide mais données user manquantes → re-run du flow
    // select-account-type qui va recréer la ligne users via
    // UserSetupRepository (avec l'observabilité ajoutée récemment).
    return '/select-account-type';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.violet),
      ),
    );
  }
}
