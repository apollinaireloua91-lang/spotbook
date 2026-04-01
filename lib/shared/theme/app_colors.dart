import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const Color fond = Color(0xFF0D0D14);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color surfaceAlt = Color(0xFF16161F);
  static const Color border = Color(0xFF2A2A3A);

  // Text
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color gris = Color(0xFF9090AA);
  static const Color grisInactif = Color(0xFF555555);
  static const Color grisClair = Color(0xFFCCCCCC);

  // Accents
  static const Color violet = Color(0xFF6C3EF4);
  static const Color violetClair = Color(0xFF8B63FF);
  static const Color rose = Color(0xFFF43E8F);
  static const Color roseClair = Color(0xFFFF6BAA);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFBB33);

  /// Vert marque Spotify (piste / musique sur le feed).
  static const Color spotifyGreen = Color(0xFF1ED760);

  /// Séparateurs sheets / nav (proche #1e1e2e).
  static const Color sheetSeparator = Color(0xFF1A1A2A);

  /// Bandeaux CTA feed (service / événement).
  static const Color ctaServiceStripBg = Color(0xFF1A1330);
  static const Color ctaEventStripBg = Color(0xFF1E0532);

  /// Marques (partage).
  static const Color brandTikTok = Color(0xFF010101);
  static const Color brandWhatsApp = Color(0xFF25D366);

  // ── Overlays & Shadows (video feed, dialogs, image pickers) ───────────────

  /// Semi-transparent dark overlay for video scrims, dialog backdrops.
  static const Color overlayDark = Color(0x73000000); // ~45%
  /// Lighter dark overlay for icon backgrounds, badges on media.
  static const Color overlayMedium = Color(0x55000000); // ~33%
  /// Subtle shadow behind action buttons and text on video.
  static const Color shadowDark = Color(0x8A000000); // ~54%
  /// Image picker dimmed background.
  static const Color overlayPicker = Color(0xDE000000); // ~87%

  // ── Gradients ──────────────────────────────────────────────────────────────

  /// Dégradé violet → rose (boutons CTA, badges premium).
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [violet, rose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé violet clair → rose clair (halos, rings, glow).
  static const LinearGradient gradientGlow = LinearGradient(
    colors: [violetClair, roseClair],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé surface subtil (cartes premium, backgrounds).
  static const LinearGradient gradientSurface = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Shimmer sweep gradient pour les loading states.
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [surfaceAlt, Color(0xFF2A2A3A), surfaceAlt],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}

/// Alias sémantiques — utilisés par les écrans profil et widgets partagés.
abstract final class SpotbookColors {
  static const Color background = AppColors.fond;
  static const Color surface = AppColors.surface;
  static const Color surfaceVariant = AppColors.surfaceAlt;
  static const Color border = AppColors.border;
  static const Color textPrimary = AppColors.blanc;
  static const Color textSecondary = AppColors.gris;
  static const Color textTertiary = AppColors.grisClair;
  static const Color textDisabled = AppColors.grisInactif;
  static const Color accent = AppColors.violet;
  static const Color accentSecondary = AppColors.rose;
  static const Color error = AppColors.error;
  static const Color success = AppColors.success;
}
