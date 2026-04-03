import 'package:flutter/material.dart';

/// Animations réutilisables Spotbook.
///
/// Chaque méthode retourne une [Animation] configurée à partir
/// d'un [AnimationController] fourni par l'appelant.
///
/// ```dart
/// // Dans un State avec SingleTickerProviderStateMixin :
/// final controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
/// final anim = SpotbookAnimations.scaleIn(controller);
/// controller.forward();
/// ```
abstract final class SpotbookAnimations {
  /// Scale 0 → 1 avec rebond élastique (300ms recommandé).
  static Animation<double> scaleIn(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    );
  }

  /// Translation Y 20 → 0 pour fade + slide up (400ms recommandé).
  static Animation<Offset> fadeSlideUp(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Opacité 0 → 1 pour accompagner fadeSlideUp.
  static Animation<double> fadeSlideUpOpacity(
    AnimationController controller,
  ) {
    return CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );
  }

  /// Scale 1 → 1.4 → 1 pour animation cœur like (200ms recommandé).
  static Animation<double> heartPop(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  /// Shimmer -1 → 2 pour loading effect (1500ms, repeat).
  static Animation<double> shimmerGlow(AnimationController controller) {
    return Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  /// Ring pulsant scale 1 → 1.5 (1200ms, repeat).
  static Animation<double> pulseRing(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  /// Opacité du ring pulsant 0.6 → 0 pour le fade out.
  static Animation<double> pulseRingOpacity(
    AnimationController controller,
  ) {
    return Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  /// Animation staggered : chaque item apparaît avec un délai décalé.
  ///
  /// [index] : position de l'item dans la liste.
  /// [itemCount] : nombre total d'items (pour calculer les intervalles).
  static Animation<double> staggeredItem(
    AnimationController controller, {
    required int index,
    required int itemCount,
  }) {
    final segmentLength = 1.0 / itemCount;
    final start = (index * segmentLength * 0.5).clamp(0.0, 0.9);
    final end = (start + segmentLength).clamp(start + 0.01, 1.0);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  /// Micro-bounce 1 → 1.15 → 1 pour les icônes nav bar (100ms recommandé).
  static Animation<double> microBounce(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
}
