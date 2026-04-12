import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material ThemeData for Spotbook — derived from [AppColors].
///
/// Both themes are built from AppColors constants so the palette stays
/// in a single source of truth.
abstract final class AppTheme {
  // ═════════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — Clean white / soft gray / violet (#8039C5)
  // ═════════════════════════════════════════════════════════════════════════════

  static const _lFond = Color(0xFFF5F5F3);
  static const _lSurface = Color(0xFFFFFFFF);
  static const _lSurfaceAlt = Color(0xFFF7F7F5);
  static const _lBorder = Color(0xFFE5E5E5);
  static const _lPrimary = Color(0xFF8039C5);
  static const _lPrimaryLight = Color(0xFF9B5DD6);
  static const _lText = Color(0xFF0C0C0C);
  static const _lTextSecondary = Color(0xFF6B6B6B);
  static const _lTextDisabled = Color(0xFFB0B0B0);
  static const _lError = Color(0xFFEF4444);
  static const _lOnPrimary = Color(0xFFFFFFFF);

  static ThemeData get light => ThemeData.light().copyWith(
        scaffoldBackgroundColor: _lFond,
        cardColor: _lSurface,
        dividerColor: _lBorder,
        colorScheme: const ColorScheme.light(
          surface: _lSurface,
          primary: _lPrimary,
          secondary: _lPrimaryLight,
          error: _lError,
          onPrimary: _lOnPrimary,
          onSurface: _lText,
          onError: _lOnPrimary,
          outline: _lBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _lFond,
          foregroundColor: _lText,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _lFond,
          selectedItemColor: _lPrimary,
          unselectedItemColor: _lTextDisabled,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lPrimary,
            foregroundColor: _lOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _lText,
            backgroundColor: _lSurface,
            side: const BorderSide(color: _lBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _lPrimary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lSurface,
          hintStyle: const TextStyle(color: _lTextSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lError, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          color: _lSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _lBorder, width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _lFond,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _lText,
          contentTextStyle: const TextStyle(color: _lOnPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _lSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: _lText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _lSurface,
          side: const BorderSide(color: _lBorder, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _lBorder,
          thickness: 0.5,
          space: 0,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _lPrimary,
          linearTrackColor: _lSurfaceAlt,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _lPrimary;
            return _lTextDisabled;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _lPrimaryLight.withAlpha(80);
            }
            return _lBorder;
          }),
        ),
        textTheme: _buildTextTheme(
          sora: GoogleFonts.soraTextTheme(),
          dmSans: GoogleFonts.dmSansTextTheme(),
          text: _lText,
          textSecondary: _lTextSecondary,
          textDisabled: _lTextDisabled,
        ),
      );

  // ═════════════════════════════════════════════════════════════════════════════
  // DARK THEME — True black #000000 + deep purple (#8E05C2)
  // ═════════════════════════════════════════════════════════════════════════════

  static const _dFond = Color(0xFF000000);
  static const _dSurface = Color(0xFF121218);
  static const _dSurfaceAlt = Color(0xFF0A0A10);
  static const _dBorder = Color(0xFF1E1E2E);
  static const _dPrimary = Color(0xFF8E05C2);
  static const _dPrimaryLight = Color(0xFFA855F7);
  static const _dText = Color(0xFFFFFFFF);
  static const _dTextSecondary = Color(0xFFA0A0B8);
  static const _dTextDisabled = Color(0xFF555566);
  static const _dError = Color(0xFFEF4444);

  static ThemeData get dark => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _dFond,
        cardColor: _dSurface,
        dividerColor: _dBorder,
        colorScheme: const ColorScheme.dark(
          surface: _dSurface,
          primary: _dPrimary,
          secondary: _dPrimaryLight,
          error: _dError,
          onPrimary: _dText,
          onSurface: _dText,
          onError: _dText,
          outline: _dBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _dFond,
          foregroundColor: _dText,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _dFond,
          selectedItemColor: _dPrimaryLight,
          unselectedItemColor: _dTextDisabled,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _dPrimary,
            foregroundColor: _dText,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _dText,
            backgroundColor: _dSurface,
            side: const BorderSide(color: _dBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _dPrimaryLight,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _dSurface,
          hintStyle: const TextStyle(color: _dTextSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _dBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _dBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _dPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _dError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _dError, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          color: _dSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _dBorder, width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _dSurfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _dSurface,
          contentTextStyle: const TextStyle(color: _dText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _dSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: _dText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _dSurface,
          side: const BorderSide(color: _dBorder, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _dBorder,
          thickness: 0.5,
          space: 0,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _dPrimary,
          linearTrackColor: _dSurface,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _dPrimaryLight;
            return _dTextDisabled;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _dPrimary.withAlpha(120);
            }
            return _dBorder;
          }),
        ),
        textTheme: _buildTextTheme(
          sora: GoogleFonts.soraTextTheme(),
          dmSans: GoogleFonts.dmSansTextTheme(),
          text: _dText,
          textSecondary: _dTextSecondary,
          textDisabled: _dTextDisabled,
        ),
      );

  // ─── Shared text theme builder — Sora (headlines/titles) + DM Sans (body/labels) ───
  static TextTheme _buildTextTheme({
    required TextTheme sora,
    required TextTheme dmSans,
    required Color text,
    required Color textSecondary,
    required Color textDisabled,
  }) {
    return dmSans.copyWith(
      displayLarge: sora.displayLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: sora.displayMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: sora.headlineLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        height: 1.2,
      ),
      headlineMedium: sora.headlineMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        height: 1.25,
      ),
      headlineSmall: sora.headlineSmall?.copyWith(
        color: text,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: sora.titleLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleMedium: sora.titleMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: sora.titleSmall?.copyWith(
        color: text,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: dmSans.bodyLarge?.copyWith(
        color: text,
        height: 1.5,
      ),
      bodyMedium: dmSans.bodyMedium?.copyWith(
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: dmSans.bodySmall?.copyWith(
        color: textDisabled,
        height: 1.45,
      ),
      labelLarge: dmSans.labelLarge?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      labelMedium: dmSans.labelMedium?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: dmSans.labelSmall?.copyWith(
        color: textDisabled,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
