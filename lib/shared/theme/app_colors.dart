import 'package:flutter/material.dart';

/// Brightness-aware color palette for Spotbook.
///
/// **Light mode**: White/beige/violet (#8039C5)
/// **Dark mode**: Deep-dark neutrals + neon-violet (#A855F7) accent
///
/// All screens use `AppColors.xxx` — colors resolve automatically based on
/// the current brightness set via [AppColors.brightness].
abstract final class AppColors {
  // ─── Brightness state ───
  static Brightness brightness = Brightness.light;

  static bool get isDark => brightness == Brightness.dark;

  // ═════════════════════════════════════════════════════════════════════════
  // THEME-SENSITIVE COLORS (resolve based on brightness)
  // ═════════════════════════════════════════════════════════════════════════

  // ─── Backgrounds ───
  static Color get fond => isDark ? const Color(0xFF0D0D14) : const Color(0xFFF3F4F1);
  static Color get surface => isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => isDark ? const Color(0xFF16161F) : const Color(0xFFF9F9F7);
  static Color get surfaceAuth => isDark ? const Color(0xFF0D0D14) : const Color(0xFFF9F9F7);
  static Color get surfaceElevated => isDark ? const Color(0xFF252538) : const Color(0xFFFFFFFF);

  // ─── Primary ───
  static Color get violet => isDark ? const Color(0xFFA855F7) : const Color(0xFF8039C5);
  static Color get violetClair => isDark ? const Color(0xFFC084FC) : const Color(0xFF9B5DD6);
  static Color get rose => isDark ? const Color(0xFFF43E8F) : const Color(0xFFFDF2C3);
  static Color get roseClair => isDark ? const Color(0xFFFF6BAA) : const Color(0xFFFDF2C3);

  // ─── Text ───
  static Color get blanc => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0C0C0C);
  static Color get gris => isDark ? const Color(0xFF9090AA) : const Color(0xFF6B6B6B);
  static Color get grisClair => isDark ? const Color(0xFFB8B8CC) : const Color(0xFF6B6B6B);
  static Color get grisInactif => isDark ? const Color(0xFF555555) : const Color(0xFFB0B0B0);
  static Color get accent => isDark ? const Color(0xFFC084FC) : const Color(0xFF9B5DD6);
  static Color get accentGreen => isDark ? const Color(0xFF34D399) : const Color(0xFF8039C5);

  // ─── Borders ───
  static Color get border => isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE0E0E0);
  static Color get sheetSeparator => isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE0E0E0);

  // ─── Semantic ───
  static Color get success => isDark ? const Color(0xFF22C55E) : const Color(0xFF22C55E);
  static Color get error => isDark ? const Color(0xFFFF4444) : const Color(0xFFEF4444);
  static Color get warning => isDark ? const Color(0xFFFFBB33) : const Color(0xFFFFBB33);

  // ─── Catering ───
  static Color get cateringBg => isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFDF2C3);

  // ─── Strip backgrounds (on video — always dark for readability) ───
  static Color get ctaServiceStripBg => const Color(0xCC1A1A2E);
  static Color get ctaEventStripBg => const Color(0xCC1A1A2E);
  static Color get ctaBookingStripBg => const Color(0xCC1A1A2E);
  static Color get ctaCateringStripBg => isDark ? const Color(0xCC2E1A08) : const Color(0xCC2E1A08);

  // ─── Nav bar ───
  static Color get navBarBg => isDark ? const Color(0xFF0D0D14) : const Color(0xFFF3F4F1);

  // ─── Status ───
  static Color get statusCompleted => isDark ? const Color(0xFF22C55E) : const Color(0xFF22C55E);
  static Color get successLight => isDark ? const Color(0xFF86EFAC) : const Color(0xFF86EFAC);

  // ─── Shadows (neon glow in dark) ───
  static Color get shadowCard => isDark ? const Color(0x26A855F7) : const Color(0x1A000000);
  static Color get shadowDark => isDark ? const Color(0x40A855F7) : const Color(0x33000000);

  // ─── Gradients ───
  static LinearGradient get gradientAccent => isDark
      ? const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF8039C5), Color(0xFF9B5DD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  static LinearGradient get gradientAccentVertical => isDark
      ? const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : const LinearGradient(
          colors: [Color(0xFF8039C5), Color(0xFF9B5DD6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

  // ─── Legacy gradient helpers ───
  static Color get violetDarkGradient => isDark ? const Color(0xFF7C3AED) : const Color(0xFF6A2EA8);
  static Color get violetDarkGradientEnd => isDark ? const Color(0xFFA855F7) : const Color(0xFF8039C5);

  // ═════════════════════════════════════════════════════════════════════════
  // CONSTANT COLORS (same in both modes)
  // ═════════════════════════════════════════════════════════════════════════

  // ─── Brand ───
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color brandWhatsApp = Color(0xFF25D366);
  static const Color brandTikTok = Color(0xFFFF0050);
  static const Color brandTikTokDark = Color(0xFF010101);
  static const Color brandInstagram = Color(0xFFC13584);
  static const Color brandInstagramAlt = Color(0xFFE4405F);
  static const Color brandYouTube = Color(0xFFFF0000);
  static const Color brandSnapchat = Color(0xFFFFFC00);
  static const Color brandTwitter = Color(0xFF1DA1F2);
  static const Color brandFacebook = Color(0xFF1877F2);
  static const Color brandPinterest = Color(0xFFE60023);

  // ─── Catering (accent — same both modes) ───
  static const Color catering = Color(0xFFFF8C42);
  static const Color cateringDark = Color(0xFFF97316);
  static const Color cateringLight = Color(0xFFFFB347);

  // ─── Overlays (always dark — used on video) ───
  static const Color overlayLight = Color(0x22000000);
  static const Color overlayMedium = Color(0x44000000);
  static const Color overlayPicker = Color(0xCC000000);
  static const Color overlayHeavy = Color(0xDD000000);
  static const Color overlayStrong = Color(0xB8000000);
  static const Color shadowTextLight = Color(0x8A000000);

  // ─── Rating / stars ───
  static const Color starGold = Color(0xFFFFD700);
  static const Color starGoldLight = Color(0xFFFFE066);
  static const Color ratingAmber = Color(0xFFFFB800);

  // ─── Info ───
  static const Color infoBlue = Color(0xFF42A5F5);
  static const Color locationBlue = Color(0xFF007AFF);

  // ─── Text on video (always white) ───
  static const Color textOnVideo = Color(0xFFFFFFFF);

  // ─── Text on primary buttons (always white) ───
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ═════════════════════════════════════════════════════════════════════════
  // DARK MODE GLOW HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  static Color get glow => isDark ? const Color(0xFFA855F7) : Colors.transparent;
  static Color get glowLight => isDark ? const Color(0xFFC084FC) : Colors.transparent;

  /// Neon glow shadow for cards in dark mode, subtle shadow in light mode.
  static List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: const Color(0xFFA855F7).withAlpha(30),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  /// Neon glow shadow for primary buttons in dark mode.
  static List<BoxShadow> get primaryButtonShadow => isDark
      ? [
          BoxShadow(
            color: const Color(0xFFA855F7).withAlpha(90),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ]
      : [];
}
