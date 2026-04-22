import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Écran de transition qui redirige silencieusement vers `/login` au
/// prochain frame.
///
/// Utilisé comme fallback sur les onglets du Pro/Client Shell (Profil,
/// Dashboard, RDV, etc.) quand la session est absente OU que les données
/// utilisateur sont introuvables — cas typique d'une session Keychain iOS
/// « orpheline » (le token persiste après une désinstallation mais la
/// ligne `users` Supabase n'existe plus).
///
/// Rend un scaffold plein fond avec un spinner violet le temps que
/// GoRouter transitionne, puis l'écran `/login` prend le relais et la
/// navbar du shell est automatiquement masquée (route hors StatefulShell).
class AuthRequiredRedirect extends StatefulWidget {
  const AuthRequiredRedirect({super.key, this.destination = '/login'});

  /// Route vers laquelle rediriger. Par défaut `/login`.
  final String destination;

  @override
  State<AuthRequiredRedirect> createState() => _AuthRequiredRedirectState();
}

class _AuthRequiredRedirectState extends State<AuthRequiredRedirect> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback : on ne peut pas appeler context.go() pendant
    // un build (ça explose GoRouter avec « setState during build »).
    // En différant d'un frame, on laisse la frame courante se terminer
    // avant de déclencher la navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(widget.destination);
    });
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
