import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'spotbook_colors.dart';
import 'spotbook_text_styles.dart';

/// ThemeData Spotbook light mode complet.
///
/// Utilisation dans MaterialApp : `theme: SpotbookTheme.light`.
abstract final class SpotbookTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: SpotbookColors.background,
      cardColor: SpotbookColors.surface,
      canvasColor: SpotbookColors.surface,
      dividerColor: SpotbookColors.border,
      textTheme: SpotbookTextStyles.textTheme(base.textTheme),
      colorScheme: ColorScheme.light(
        primary: SpotbookColors.violet,
        secondary: SpotbookColors.rose,
        surface: SpotbookColors.surface,
        error: SpotbookColors.error,
        onPrimary: SpotbookColors.white,
        onSecondary: SpotbookColors.white,
        onSurface: SpotbookColors.textPrimary,
        onError: SpotbookColors.white,
        outline: SpotbookColors.border,
      ),

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: SpotbookColors.textPrimary),
        centerTitle: true,
      ),

      // ─── Bottom Navigation ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SpotbookColors.background,
        selectedItemColor: SpotbookColors.violet,
        unselectedItemColor: SpotbookColors.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ─── Bouton primaire (fond violet, texte blanc, radius 12) ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SpotbookColors.violet,
          foregroundColor: SpotbookColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: SpotbookTextStyles.button,
        ),
      ),

      // ─── Bouton secondaire (fond surface, bordure subtile, radius 12) ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SpotbookColors.textPrimary,
          backgroundColor: SpotbookColors.surface,
          side: BorderSide(color: SpotbookColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: SpotbookTextStyles.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SpotbookColors.violet,
          textStyle: SpotbookTextStyles.button,
        ),
      ),

      // ─── Champs de saisie ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpotbookColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SpotbookColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SpotbookColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: SpotbookColors.violet,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SpotbookColors.error),
        ),
        hintStyle: SpotbookTextStyles.bodySecondary,
        labelStyle: SpotbookTextStyles.bodySecondary,
      ),

      // ─── Cards ───
      cardTheme: CardThemeData(
        color: SpotbookColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpotbookColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: SpotbookColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        elevation: 0,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: SpotbookColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),

      // ─── SnackBar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SpotbookColors.surface,
        contentTextStyle: SpotbookTextStyles.bodySmall.copyWith(
          color: SpotbookColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: SpotbookColors.surface,
        side: BorderSide(color: SpotbookColors.border, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: SpotbookTextStyles.caption,
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: SpotbookColors.border,
        thickness: 0.5,
        space: 0,
      ),

      // ─── Progress ───
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: SpotbookColors.violet,
        linearTrackColor: SpotbookColors.surface,
      ),

      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SpotbookColors.violet;
          }
          return SpotbookColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SpotbookColors.violet.withAlpha(80);
          }
          return SpotbookColors.border;
        }),
      ),
    );
  }
}
