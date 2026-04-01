import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color fond = Color(0xFF000000);
  static const Color fondDark = Color(0xFF0D0D14);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceAlt = Color(0xFF1A1A1A);
  static const Color surfaceAuth = Color(0xFF1A1A2E);
  static const Color border = Color(0xFF2A2A2A);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color gris = Color(0xFF888888);
  static const Color grisClair = Color(0xFFCCCCCC);
  static const Color grisInactif = Color(0xFF555555);
  static const Color accent = Color(0xFF00D1FF);
  static const Color accentGreen = Color(0xFF00C853);
  static const Color violet = Color(0xFF6C3EF4);
  static const Color violetClair = Color(0xFF8B63FF);
  static const Color rose = Color(0xFFF43E8F);
  static const Color roseClair = Color(0xFFFF6BAA);
  static const Color success = Color(0xFF00C851);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFBB33);
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color shadowDark = Color(0x66000000);
  static const Color overlayMedium = Color(0x80000000);
  static const Color overlayPicker = Color(0xCC000000);
  static const Color sheetSeparator = Color(0xFF2A2A3A);
  static const Color ctaServiceStripBg = Color(0xFF1A1A2E);
  static const Color ctaEventStripBg = Color(0xFF1E1A2E);
  static const Color brandWhatsApp = Color(0xFF25D366);
  static const Color brandTikTok = Color(0xFFFF0050);

  static const LinearGradient gradientAccent = LinearGradient(
    colors: [violet, rose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
