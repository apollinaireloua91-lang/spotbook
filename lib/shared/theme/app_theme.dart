import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  // ─── Light (beige / vert) ───
  static ThemeData get light => ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.fond,
        cardColor: AppColors.surface,
        dividerColor: AppColors.border,
        colorScheme: const ColorScheme.light(
          surface: AppColors.surface,
          primary: AppColors.violet,
          error: AppColors.error,
          onPrimary: AppColors.textOnPrimary,
          onSurface: AppColors.blanc,
          onError: AppColors.textOnPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.fond,
          foregroundColor: AppColors.blanc,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.fond,
          selectedItemColor: AppColors.violet,
          unselectedItemColor: AppColors.grisInactif,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.violet,
            foregroundColor: AppColors.textOnPrimary,
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
            foregroundColor: AppColors.blanc,
            side: const BorderSide(color: AppColors.border),
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceAlt,
          hintStyle: const TextStyle(color: AppColors.gris),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.violet),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surface,
          contentTextStyle: const TextStyle(color: AppColors.blanc),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.fond,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            color: AppColors.blanc,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.blanc,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: AppColors.grisClair,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            color: AppColors.gris,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      );

  // ─── Dark (noir / violet) ───
  static const _dFond = Color(0xFF0D0D14);
  static const _dSurface = Color(0xFF1E1E2E);
  static const _dSurfaceAlt = Color(0xFF16161F);
  static const _dBorder = Color(0xFF2A2A3A);
  static const _dPrimary = Color(0xFF6C3EF4);
  static const _dPrimaryLight = Color(0xFF8B63FF);
  static const _dText = Color(0xFFFFFFFF);
  static const _dTextSecondary = Color(0xFF9090AA);
  static const _dTextDisabled = Color(0xFF555555);
  static const _dError = Color(0xFFFF4444);

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
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _dFond,
          foregroundColor: _dText,
          elevation: 0,
          centerTitle: true,
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
            borderSide: const BorderSide(color: _dPrimary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          titleTextStyle: const TextStyle(
            color: _dText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
