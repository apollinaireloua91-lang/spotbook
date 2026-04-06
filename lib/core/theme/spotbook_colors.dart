import 'package:flutter/material.dart';

/// Palette Spotbook — Blanc + Beige + Vert.
///
/// Utilisation : `SpotbookColors.primary` ou `SpotbookColors.gradientForCategory('barbier')`.
abstract final class SpotbookColors {
  // ─── Fond ───
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFF3DA);
  static const Color surfaceAlt = Color(0xFFFFF8ED);
  static const Color border = Color(0xFFE8E0D0);

  // ─── Texte ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFFB0B0B0);
  static const Color textCaption = Color(0xFF6B6B6B);

  // ─── Primary (Vert) ───
  static const Color violet = Color(0xFF043603);
  static const Color violetLight = Color(0xFF0A5E08);
  static const Color rose = Color(0xFF2D8C2A);
  static const Color roseLight = Color(0xFF2D8C2A);

  // ─── Sémantique ───
  static const Color success = Color(0xFF043603);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF8C42);

  // ─── Marques ───
  static const Color spotifyGreen = Color(0xFF1ED760);
  static const Color orange = Color(0xFFFF8C42);
  static const Color orangeLight = Color(0xFFFFB347);

  // ─── Gradients principaux ───
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFF043603), Color(0xFF2D8C2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAccentVertical = LinearGradient(
    colors: [Color(0xFF043603), Color(0xFF2D8C2A)],
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
      colors: [Color(0xFF043603), Color(0xFF2D8C2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'tatoueur': const LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFFCA5A5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'esthetique': const LinearGradient(
      colors: [Color(0xFF2D8C2A), Color(0xFF4ADE80)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'traiteur': const LinearGradient(
      colors: [Color(0xFFFF8C42), Color(0xFFF97316)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'dj': const LinearGradient(
      colors: [Color(0xFF043603), Color(0xFF0A5E08)],
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
