import 'package:flutter/material.dart';

/// Palette Spotbook — Violet + Beige + Light.
///
/// Utilisation : `SpotbookColors.primary` ou `SpotbookColors.gradientForCategory('barbier')`.
abstract final class SpotbookColors {
  // ─── Fond ───
  static const Color background = Color(0xFFF3F4F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF9F9F7);
  static const Color border = Color(0xFFE0E0E0);

  // ─── Texte ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0C0C0C);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFFB0B0B0);
  static const Color textCaption = Color(0xFF6B6B6B);

  // ─── Primary (Violet) ───
  static const Color violet = Color(0xFF8039C5);
  static const Color violetLight = Color(0xFF9B5DD6);
  static const Color rose = Color(0xFFFDF2C3);
  static const Color roseLight = Color(0xFFFDF2C3);

  // ─── Sémantique ───
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFFBB33);

  // ─── Marques ───
  static const Color spotifyGreen = Color(0xFF1ED760);
  static const Color orange = Color(0xFFFF8C42);
  static const Color orangeLight = Color(0xFFFFB347);

  // ─── Gradients principaux ───
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFF8039C5), Color(0xFF9B5DD6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAccentVertical = LinearGradient(
    colors: [Color(0xFF8039C5), Color(0xFF9B5DD6)],
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
      colors: [Color(0xFF8039C5), Color(0xFF9B5DD6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'tatoueur': const LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFFCA5A5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'esthetique': const LinearGradient(
      colors: [Color(0xFF9B5DD6), Color(0xFFB98AE8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'traiteur': const LinearGradient(
      colors: [Color(0xFFFF8C42), Color(0xFFF97316)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'dj': const LinearGradient(
      colors: [Color(0xFF6A2EA8), Color(0xFF8039C5)],
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
