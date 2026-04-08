import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spotbook_colors.dart';

/// Typographie Spotbook centralisée.
///
/// Corps / labels / boutons : DM Sans (google_fonts).
/// Titres h1/h2 : DM Sans bold (remplacer par Clash Display quand les
///                assets `assets/fonts/ClashDisplay-*.ttf` seront ajoutés).
abstract final class SpotbookTextStyles {
  // ─── Headlines (titres d'écran) ───
  static TextStyle get headline1 => GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: SpotbookColors.textPrimary,
      );

  static TextStyle get headline2 => GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
        color: SpotbookColors.textPrimary,
      );

  // ─── Titles (sections, cards) ───
  static TextStyle get title => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: SpotbookColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: SpotbookColors.textPrimary,
      );

  // ─── Body ───
  static TextStyle get body => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: SpotbookColors.textPrimary,
      );

  static TextStyle get bodySecondary => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: SpotbookColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: SpotbookColors.textSecondary,
      );

  // ─── Caption ───
  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: SpotbookColors.textSecondary,
      );

  // ─── Label (sections, uppercase) ───
  static TextStyle get label => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        height: 1.2,
        color: SpotbookColors.textSecondary,
      );

  // ─── Button ───
  static TextStyle get button => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: SpotbookColors.white,
      );

  static TextStyle get buttonSmall => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: SpotbookColors.white,
      );

  // ─── Logo Spotbook — DM Sans bold 20, violet on light bg ───
  static TextStyle get logo => GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: SpotbookColors.violet,
      );

  // ─── Navigation ───
  static TextStyle navLabel({required bool active}) => GoogleFonts.dmSans(
        fontSize: 9,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        height: 1.1,
        color: active ? SpotbookColors.violet : SpotbookColors.textDisabled,
      );

  // ─── Feed (text on video — keep white + shadow) ───
  static TextStyle feedCaption({bool bold = false}) => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        height: 1.35,
        color: SpotbookColors.white,
        shadows: const [
          Shadow(
            color: Color(0xDD000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      );

  static TextStyle get feedActionCount => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: SpotbookColors.white,
        shadows: const [
          Shadow(
            color: Color(0xDD000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      );

  /// [TextTheme] DM Sans pour le ThemeData Material.
  static TextTheme textTheme(TextTheme base) {
    final dmSans = GoogleFonts.dmSansTextTheme(base);
    return dmSans.copyWith(
      displayLarge: dmSans.displayLarge?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: dmSans.displayMedium?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: dmSans.headlineLarge?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineMedium: dmSans.headlineMedium?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineSmall: dmSans.headlineSmall?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: dmSans.titleLarge?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleMedium: dmSans.titleMedium?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: dmSans.titleSmall?.copyWith(
        color: SpotbookColors.textPrimary,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: dmSans.bodyLarge?.copyWith(
        color: SpotbookColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: dmSans.bodyMedium?.copyWith(
        color: SpotbookColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: dmSans.bodySmall?.copyWith(
        color: SpotbookColors.textDisabled,
        height: 1.45,
      ),
      labelLarge: dmSans.labelLarge?.copyWith(
        color: SpotbookColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      labelMedium: dmSans.labelMedium?.copyWith(
        color: SpotbookColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: dmSans.labelSmall?.copyWith(
        color: SpotbookColors.textDisabled,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
