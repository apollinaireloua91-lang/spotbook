import 'package:flutter/material.dart';

/// Brightness-aware color palette for Spotbook.
///
/// **Light mode**: Clean white / soft gray / violet (#8039C5)
/// **Dark mode**: True black #000000 + deep purple accents (#8E05C2)
///
/// All screens use `AppColors.xxx` — colors resolve automatically based on
/// the current brightness set via [AppColors.brightness].
///
/// These values are the SINGLE SOURCE OF TRUTH — [AppTheme] reads from here.
abstract final class AppColors {
  // ─── Brightness state ───
  static Brightness brightness = Brightness.light;

  static bool get isDark => brightness == Brightness.dark;

  // ═════════════════════════════════════════════════════════════════════════
  // THEME-SENSITIVE COLORS (resolve based on brightness)
  // ═════════════════════════════════════════════════════════════════════════

  // ─── Backgrounds ───
  static Color get fond => isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F3);
  static Color get surface => isDark ? const Color(0xFF121218) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => isDark ? const Color(0xFF0A0A10) : const Color(0xFFF7F7F5);
  static Color get surfaceAuth => isDark ? const Color(0xFF000000) : const Color(0xFFF7F7F5);
  static Color get surfaceElevated => isDark ? const Color(0xFF1A1A26) : const Color(0xFFFFFFFF);

  // ─── Primary ───
  static Color get violet => isDark ? const Color(0xFF8E05C2) : const Color(0xFF8039C5);
  static Color get violetClair => isDark ? const Color(0xFFA855F7) : const Color(0xFF9B5DD6);
  static Color get rose => isDark ? const Color(0xFFF43E8F) : const Color(0xFFF43E8F);
  static Color get roseClair => isDark ? const Color(0xFFFF6BAA) : const Color(0xFFFF6BAA);

  // ─── Text ───
  static Color get blanc => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0C0C0C);
  static Color get gris => isDark ? const Color(0xFFA0A0B8) : const Color(0xFF6B6B6B);
  static Color get grisClair => isDark ? const Color(0xFFCCCCDD) : const Color(0xFF8A8A8A);
  static Color get grisInactif => isDark ? const Color(0xFF555566) : const Color(0xFFB0B0B0);
  static Color get accent => isDark ? const Color(0xFFA855F7) : const Color(0xFF9B5DD6);
  static Color get accentGreen => isDark ? const Color(0xFF34D399) : const Color(0xFF22C55E);

  // ─── Borders ───
  static Color get border => isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE5E5E5);
  static Color get sheetSeparator => isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE5E5E5);

  // ─── Semantic ───
  static Color get success => const Color(0xFF22C55E);
  static Color get error => isDark ? const Color(0xFFFF4444) : const Color(0xFFEF4444);
  static Color get warning => const Color(0xFFFFBB33);
  static Color get danger => const Color(0xFFEF4444);

  // ─── Catering ───
  static Color get cateringBg => isDark ? const Color(0xFF1A0E00) : const Color(0xFFFDF2C3);

  // ─── Strip backgrounds (on video — always dark for readability) ───
  static Color get ctaServiceStripBg => const Color(0xCC1A1A2E);
  static Color get ctaEventStripBg => const Color(0xCC1A1A2E);
  static Color get ctaBookingStripBg => const Color(0xCC1A1A2E);
  static Color get ctaCateringStripBg => const Color(0xCC2E1A08);

  // ─── Nav bar ───
  static Color get navBarBg => isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F3);

  // ─── Status ───
  static Color get statusCompleted => const Color(0xFF22C55E);
  static Color get successLight => const Color(0xFF86EFAC);

  // ─── Shadows (neon glow in dark) ───
  static Color get shadowCard => isDark ? const Color(0x338E05C2) : const Color(0x1A000000);
  static Color get shadowDark => isDark ? const Color(0x4D8E05C2) : const Color(0x33000000);

  // ─── Gradients ───
  static LinearGradient get gradientAccent => isDark
      ? const LinearGradient(
          colors: [Color(0xFF700B97), Color(0xFF8E05C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF7030B0), Color(0xFF9B5DD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  static LinearGradient get gradientAccentVertical => isDark
      ? const LinearGradient(
          colors: [Color(0xFF700B97), Color(0xFF8E05C2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : const LinearGradient(
          colors: [Color(0xFF7030B0), Color(0xFF9B5DD6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

  // ─── Legacy gradient helpers ───
  static Color get violetDarkGradient => isDark ? const Color(0xFF3E065F) : const Color(0xFF6A2EA8);
  static Color get violetDarkGradientEnd => isDark ? const Color(0xFF8E05C2) : const Color(0xFF8039C5);

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

  // ─── Logout / destructive ───
  static const Color logout = Color(0xFFEF4444);

  // ═════════════════════════════════════════════════════════════════════════
  // DARK MODE GLOW HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  static Color get glow => isDark ? const Color(0xFF8E05C2) : Colors.transparent;
  static Color get glowLight => isDark ? const Color(0xFFA855F7) : Colors.transparent;

  /// Neon glow shadow for cards in dark mode, subtle shadow in light mode.
  static List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: const Color(0xFF8E05C2).withAlpha(25),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ];

  /// Neon glow shadow for primary buttons in dark mode.
  static List<BoxShadow> get primaryButtonShadow => isDark
      ? [
          BoxShadow(
            color: const Color(0xFF8E05C2).withAlpha(100),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF8039C5).withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
}
