import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  // ═════════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — White / Beige / Violet (#8039C5)
  // ═════════════════════════════════════════════════════════════════════════════

  static const _lFond = Color(0xFFF3F4F1);
  static const _lSurface = Color(0xFFFFFFFF);
  static const _lSurfaceAlt = Color(0xFFF9F9F7);
  static const _lBorder = Color(0xFFE0E0E0);
  static const _lPrimary = Color(0xFF8039C5);
  static const _lPrimaryLight = Color(0xFF9B5DD6);
  static const _lSecondary = Color(0xFFFDF2C3);
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
          secondary: _lSecondary,
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
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
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
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
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
          fillColor: _lSurfaceAlt,
          hintStyle: const TextStyle(color: _lTextSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lError),
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
          backgroundColor: _lSurface,
          contentTextStyle: const TextStyle(color: _lText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _lFond,
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
          linearTrackColor: _lSurface,
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
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _lText,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            color: _lText,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            color: _lText,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: _lText,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: _lText,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: _lTextSecondary,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            color: _lTextSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      );

  // ═════════════════════════════════════════════════════════════════════════════
  // DARK THEME — Black / Neon Violet (#8E05C2)
  // ═════════════════════════════════════════════════════════════════════════════

  static const _dFond = Color(0xFF000000);
  static const _dSurface = Color(0xFF3E065F);
  static const _dSurfaceAlt = Color(0xFF1A0330);
  static const _dBorder = Color(0xFF4A0A6E);
  static const _dPrimary = Color(0xFF8E05C2);
  static const _dPrimaryLight = Color(0xFFA020F0);
  static const _dText = Color(0xFFFFFFFF);
  static const _dTextSecondary = Color(0xFFB8B8CC);
  static const _dTextDisabled = Color(0xFF4A4A5A);
  static const _dError = Color(0xFFEF4444);
  static const _dNavBar = Color(0xFF0A0A0A);

  static ThemeData get dark => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _dFond,
        cardColor: _dSurface,
        dividerColor: _dBorder,
        colorScheme: const ColorScheme.dark(
          surface: _dSurface,
          primary: _dPrimary,
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
          backgroundColor: _dNavBar,
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
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
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
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
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
          fillColor: _dSurfaceAlt,
          hintStyle: const TextStyle(color: _dTextSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _dBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _dBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _dPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _dError),
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
          backgroundColor: _dFond,
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
          backgroundColor: _dSurfaceAlt,
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
            if (states.contains(WidgetState.selected)) return _dPrimary;
            return _dTextDisabled;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _dPrimaryLight.withAlpha(80);
            }
            return _dBorder;
          }),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _dText,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            color: _dText,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            color: _dText,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: _dText,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: _dText,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: _dTextSecondary,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            color: _dTextSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      );
}
