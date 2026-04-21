/// spotbook POS — Scoped ThemeData applying the strict Design System rules.
///
/// Wrapped around the POS feature subtree via
/// `Theme(data: SpotbookPosTheme.dark(), child: PosReaderPage())`. Keeps the
/// strict palette (DM Sans only, purple accent, no greens/reds) contained to
/// the POS screens while the rest of the app keeps the legacy `AppColors`
/// palette.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spotbook_tokens.dart';

/// Builds a scoped [ThemeData] following the spotbook POS design system.
abstract final class SpotbookPosTheme {
  /// Primary dark surface — the canonical POS render mode. Use for reader,
  /// success, and error pages.
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: SpotbookColorsDs.accentDark,
      onPrimary: SpotbookColorsDs.white,
      secondary: SpotbookColorsDs.accentDark,
      onSecondary: SpotbookColorsDs.white,
      surface: SpotbookColorsDs.accentDeep,
      onSurface: SpotbookColorsDs.white,
      // Error = accent channel dimmed (70%), never red.
      error: Color(0xB38E05C2),
      onError: SpotbookColorsDs.white,
      outline: SpotbookColorsDs.borderDark,
    );

    final textTheme = _buildTextTheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: SpotbookColorsDs.black,
      canvasColor: SpotbookColorsDs.black,
      fontFamily: SpotbookTypographyDs.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: SpotbookColorsDs.white),
      primaryIconTheme: const IconThemeData(color: SpotbookColorsDs.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: SpotbookColorsDs.white,
        iconTheme: IconThemeData(color: SpotbookColorsDs.white),
        titleTextStyle: TextStyle(
          color: SpotbookColorsDs.white,
          fontFamily: SpotbookTypographyDs.fontFamily,
          fontSize: SpotbookTypographyDs.textHeading,
          fontWeight: SpotbookTypographyDs.weightSemibold,
        ),
      ),
      splashColor: SpotbookColorsDs.accent15,
      highlightColor: SpotbookColorsDs.accent08,
      dividerColor: SpotbookColorsDs.borderDark,
    );
  }

  /// Light variant — POS amount entry and history lean darker but the DS
  /// exposes light tokens for day-mode surfaces.
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: SpotbookColorsDs.accentLight,
      onPrimary: SpotbookColorsDs.white,
      secondary: SpotbookColorsDs.accentLight,
      onSecondary: SpotbookColorsDs.white,
      surface: SpotbookColorsDs.offWhite,
      onSurface: SpotbookColorsDs.blackLight,
      error: Color(0xB38039C5),
      onError: SpotbookColorsDs.white,
      outline: SpotbookColorsDs.borderLight,
    );

    final textTheme = _buildTextTheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: SpotbookColorsDs.white,
      canvasColor: SpotbookColorsDs.white,
      fontFamily: SpotbookTypographyDs.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: SpotbookColorsDs.blackLight),
      primaryIconTheme: const IconThemeData(color: SpotbookColorsDs.blackLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: SpotbookColorsDs.blackLight,
        iconTheme: IconThemeData(color: SpotbookColorsDs.blackLight),
        titleTextStyle: TextStyle(
          color: SpotbookColorsDs.blackLight,
          fontFamily: SpotbookTypographyDs.fontFamily,
          fontSize: SpotbookTypographyDs.textHeading,
          fontWeight: SpotbookTypographyDs.weightSemibold,
        ),
      ),
      dividerColor: SpotbookColorsDs.borderLight,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // TextTheme construction — DM Sans exclusivement.
  // ───────────────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme({required bool isDark}) {
    final fgPrimary = isDark
        ? SpotbookColorsDs.foregroundPrimaryDark
        : SpotbookColorsDs.foregroundPrimaryLight;
    final fgSecondary = isDark
        ? SpotbookColorsDs.foregroundSecondaryDark
        : SpotbookColorsDs.foregroundSecondaryLight;

    TextStyle t({
      required double size,
      required FontWeight weight,
      double height = SpotbookTypographyDs.lineHeightBody,
      double letterSpacing = 0,
      Color? color,
    }) =>
        GoogleFonts.dmSans(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: letterSpacing,
          color: color ?? fgPrimary,
        );

    return TextTheme(
      // Display (hero numbers / amount)
      displayLarge: t(
        size: SpotbookTypographyDs.textDisplay,
        weight: SpotbookTypographyDs.weightBold,
        height: SpotbookTypographyDs.lineHeightTight,
        letterSpacing: SpotbookTypographyDs.letterSpacingDisplay,
      ),

      // Title (state title on reader)
      headlineLarge: t(
        size: SpotbookTypographyDs.textTitle,
        weight: SpotbookTypographyDs.weightBold,
        height: SpotbookTypographyDs.lineHeightTight,
        letterSpacing: SpotbookTypographyDs.letterSpacingTitle,
      ),
      headlineMedium: t(
        size: SpotbookTypographyDs.textHeading,
        weight: SpotbookTypographyDs.weightSemibold,
        height: 1.2,
      ),

      // Body
      bodyLarge: t(
        size: SpotbookTypographyDs.textBody,
        weight: SpotbookTypographyDs.weightRegular,
      ),
      bodyMedium: t(
        size: SpotbookTypographyDs.textBodySm,
        weight: SpotbookTypographyDs.weightMedium,
        color: fgSecondary,
      ),
      bodySmall: t(
        size: SpotbookTypographyDs.textCaption,
        weight: SpotbookTypographyDs.weightRegular,
        height: 1.3,
        color: fgSecondary,
      ),

      labelLarge: t(
        size: SpotbookTypographyDs.textLabel,
        weight: SpotbookTypographyDs.weightMedium,
        height: 1.3,
      ),
      labelMedium: t(
        size: SpotbookTypographyDs.textLabel,
        weight: SpotbookTypographyDs.weightMedium,
        height: 1.3,
        color: fgSecondary,
      ),
      labelSmall: t(
        size: SpotbookTypographyDs.textCaption,
        weight: SpotbookTypographyDs.weightMedium,
        height: 1.3,
        color: fgSecondary,
      ),
    );
  }
}

/// Convenience widget that wraps [child] in the POS scoped dark theme.
///
/// Use this at the root of every POS page so the strict palette / DM Sans
/// rules apply automatically without polluting the rest of the app.
class SpotbookPosThemeScope extends StatelessWidget {
  const SpotbookPosThemeScope({
    super.key,
    required this.child,
    this.brightness = Brightness.dark,
  });

  final Widget child;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: brightness == Brightness.dark
          ? SpotbookPosTheme.dark()
          : SpotbookPosTheme.light(),
      child: child,
    );
  }
}
