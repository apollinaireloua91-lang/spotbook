import 'package:flutter/material.dart';

/// Palette Spotbook — source unique pour toutes les couleurs et gradients.
///
/// Utilisation : `SpotbookColors.violet` ou `SpotbookColors.gradientForCategory('barbier')`.
abstract final class SpotbookColors {
  // ─── Fond ───
  static const Color background = Color(0xFF0D0D14);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color surfaceAlt = Color(0xFF16161F);
  static const Color border = Color(0xFF2A2A3A);

  // ─── Texte ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9090AA);
  static const Color textDisabled = Color(0xFF555555);
  static const Color textCaption = Color(0xFFDDDDDD);

  // ─── Accent ───
  static const Color violet = Color(0xFF6C3EF4);
  static const Color violetLight = Color(0xFF8B63FF);
  static const Color rose = Color(0xFFF43E8F);
  static const Color roseLight = Color(0xFFFF6BAA);

  // ─── Sémantique ───
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFBB33);

  // ─── Marques ───
  static const Color spotifyGreen = Color(0xFF1ED760);
  static const Color orange = Color(0xFFFF8C42);
  static const Color orangeLight = Color(0xFFFFB347);

  // ─── Gradients principaux ───
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [violet, rose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAccentVertical = LinearGradient(
    colors: [violet, rose],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Gradients catégorie Pro ───
  static final Map<String, LinearGradient> _categoryGradients = {
    'barbier': const LinearGradient(
      colors: [Color(0xFFFF6B35), Color(0xFFFFB347)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'nail_art': const LinearGradient(
      colors: [Color(0xFFE91E90), Color(0xFFFF69B4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'coach': const LinearGradient(
      colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'photo': const LinearGradient(
      colors: [Color(0xFF6C3EF4), Color(0xFFA78BFA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'tatoueur': const LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFFCA5A5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'esthetique': const LinearGradient(
      colors: [Color(0xFFF43E8F), Color(0xFFFB7BB8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'traiteur': const LinearGradient(
      colors: [Color(0xFFFF8C42), Color(0xFFF97316)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'dj': const LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  /// Retourne le gradient pour une catégorie Pro, avec fallback accent.
  static LinearGradient gradientForCategory(String category) {
    return _categoryGradients[category.toLowerCase()] ?? gradientAccent;
  }

  /// Couleur primaire d'une catégorie (premier stop du gradient).
  static Color colorForCategory(String category) {
    return gradientForCategory(category).colors.first;
  }
}
