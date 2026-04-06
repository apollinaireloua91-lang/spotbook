import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Backgrounds ───
  static const Color fond = Color(0xFFFFFFFF);           // Blanc pur
  static const Color surface = Color(0xFFFFF3DA);         // Beige chaud
  static const Color surfaceAlt = Color(0xFFFFF8ED);      // Beige très clair
  static const Color surfaceAuth = Color(0xFFFFF8ED);     // Beige clair (auth)

  // ─── Primary (Vert) ───
  static const Color violet = Color(0xFF043603);          // Vert foncé (primary)
  static const Color violetClair = Color(0xFF0A5E08);     // Vert moyen
  static const Color rose = Color(0xFF2D8C2A);            // Vert clair (accent)
  static const Color roseClair = Color(0xFF2D8C2A);       // Vert clair

  // ─── Text ───
  static const Color blanc = Color(0xFF1A1A1A);           // Noir (text principal)
  static const Color gris = Color(0xFF6B6B6B);            // Gris (secondary text)
  static const Color grisClair = Color(0xFF6B6B6B);       // Gris
  static const Color grisInactif = Color(0xFFB0B0B0);     // Gris clair (disabled)
  static const Color accent = Color(0xFF2D8C2A);          // Vert clair
  static const Color accentGreen = Color(0xFF043603);     // Vert

  // ─── Borders ───
  static const Color border = Color(0xFFE8E0D0);          // Beige foncé
  static const Color sheetSeparator = Color(0xFFE8E0D0);

  // ─── Semantic ───
  static const Color success = Color(0xFF043603);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF8C42);

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

  // ─── Catering ───
  static const Color catering = Color(0xFFFF8C42);
  static const Color cateringBg = Color(0xFFFFF3DA);
  static const Color cateringDark = Color(0xFFF97316);
  static const Color cateringLight = Color(0xFFFFB347);

  // ─── Strip backgrounds (on video — keep semi-transparent dark) ───
  static const Color ctaServiceStripBg = Color(0xE6FFFFFF);
  static const Color ctaEventStripBg = Color(0xE6FFFFFF);
  static const Color ctaBookingStripBg = Color(0xE6FFFFFF);
  static const Color ctaCateringStripBg = Color(0xE6FFF3DA);

  // ─── Shadows & overlays (keep dark for video overlays) ───
  static const Color shadowCard = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
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

  // ─── Nav bar ───
  static const Color navBarBg = Color(0xFFFFFFFF);

  // ─── Status ───
  static const Color statusCompleted = Color(0xFF043603);
  static const Color successLight = Color(0xFF86EFAC);

  // ─── Info ───
  static const Color infoBlue = Color(0xFF42A5F5);
  static const Color locationBlue = Color(0xFF007AFF);

  // ─── Text on video (keep white for readability) ───
  static const Color textOnVideo = Color(0xFFFFFFFF);

  // ─── Text on primary buttons (white on green) ───
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Gradients ───
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

  // ─── Legacy gradient helpers (kept for compat) ───
  static const Color violetDarkGradient = Color(0xFF043603);
  static const Color violetDarkGradientEnd = Color(0xFF0A5E08);
}
