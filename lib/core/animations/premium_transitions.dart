import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Premium page transitions for Spotbook — fluid slide + fade + scale.
///
/// Usage in GoRouter:
/// ```dart
/// GoRoute(
///   path: '/some-route',
///   pageBuilder: (context, state) => premiumPage(
///     state: state,
///     child: const SomeScreen(),
///   ),
/// )
/// ```

/// Default premium transition: iOS-style slide from right with subtle scale.
CustomTransitionPage<void> premiumPage({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 350),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      // Outgoing page: slight shrink + fade
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.94).animate(secondaryCurved),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.6).animate(secondaryCurved),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// Fade-through transition for modal-style screens (settings, details).
CustomTransitionPage<void> premiumFadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Bottom-up slide transition for sheets/modals pushed as pages.
CustomTransitionPage<void> premiumSlideUpPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}
