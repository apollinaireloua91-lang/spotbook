import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color fond = Color(0xFF0D0D14);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color surfaceAlt = Color(0xFF16161F);
  static const Color surfaceAuth = Color(0xFF1A1A2E);
  static const Color border = Color(0xFF2A2A3A);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color gris = Color(0xFF9090AA);
  static const Color grisClair = Color(0xFFCCCCCC);
  static const Color grisInactif = Color(0xFF555555);
  static const Color accent = Color(0xFF00D1FF);
  static const Color accentGreen = Color(0xFF00C853);
  static const Color violet = Color(0xFF6C3EF4);
  static const Color violetClair = Color(0xFF8B63FF);
  static const Color rose = Color(0xFFF43E8F);
  static const Color roseClair = Color(0xFFFF6BAA);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFBB33);
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color shadowCard = Color(0x4D000000);
  static const Color shadowDark = Color(0x66000000);
  static const Color overlayLight = Color(0x55000000);
  static const Color overlayMedium = Color(0x80000000);
  static const Color overlayPicker = Color(0xCC000000);
  static const Color overlayHeavy = Color(0xDD000000);
  static const Color overlayStrong = Color(0xB8000000);
  static const Color shadowTextLight = Color(0x8A000000);
  static const Color sheetSeparator = Color(0xFF2A2A3A);
  static const Color ctaServiceStripBg = Color(0xFF1A1A2E);
  static const Color ctaEventStripBg = Color(0xFF1E1A2E);
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

  // Catering / traiteur
  static const Color catering = Color(0xFFFF8C42);
  static const Color cateringBg = Color(0xE6301A00);

  // Strip backgrounds (overlay on video)
  static const Color ctaBookingStripBg = Color(0xE61A1330);
  static const Color ctaCateringStripBg = Color(0xE6301A00);

  // Rating star
  static const Color starGold = Color(0xFFFFD700);
  static const Color starGoldLight = Color(0xFFFFE066);

  // Nav bar background (97% opacity fond)
  static const Color navBarBg = Color(0xF80D0D14);

  // Social gradient helpers
  static const Color violetDarkGradient = Color(0xFF2A1A50);
  static const Color violetDarkGradientEnd = Color(0xFF1A1030);

  // Success lighter variant
  static const Color successLight = Color(0xFF86EFAC);

  // Catering accent
  static const Color cateringDark = Color(0xFFF97316);
  static const Color cateringLight = Color(0xFFFFB347);

  // Status
  static const Color statusCompleted = Color(0xFFA78BFA);

  // Rating / stars
  static const Color ratingAmber = Color(0xFFFFB800);

  // Search / info
  static const Color infoBlue = Color(0xFF42A5F5);

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
}
