import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

/// Palette Spotbook — delegates to [AppColors] for dark-mode awareness.
///
/// Utilisation : `SpotbookColors.primary` ou `SpotbookColors.gradientForCategory('barbier')`.
abstract final class SpotbookColors {
  // ─── Fond ───
  static Color get background => AppColors.fond;
  static Color get surface => AppColors.surface;
  static Color get surfaceAlt => AppColors.surfaceAlt;
  static Color get border => AppColors.border;

  // ─── Texte ───
  static const Color white = Color(0xFFFFFFFF);
  static Color get textPrimary => AppColors.blanc;
  static Color get textSecondary => AppColors.gris;
  static Color get textDisabled => AppColors.grisInactif;
  static Color get textCaption => AppColors.gris;

  // ─── Primary (Violet) ───
  static Color get violet => AppColors.violet;
  static Color get violetLight => AppColors.violetClair;
  static Color get rose => AppColors.rose;
  static Color get roseLight => AppColors.roseClair;

  // ─── Sémantique ───
  static Color get success => AppColors.success;
  static Color get error => AppColors.error;
  static Color get warning => AppColors.warning;

  // ─── Marques ───
  static const Color spotifyGreen = Color(0xFF1ED760);
  static const Color orange = Color(0xFFFF8C42);
  static const Color orangeLight = Color(0xFFFFB347);

  // ─── Gradients principaux ───
  static LinearGradient get gradientAccent => AppColors.gradientAccent;
  static LinearGradient get gradientAccentVertical =>
      AppColors.gradientAccentVertical;

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
