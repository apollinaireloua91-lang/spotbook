import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
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
}
