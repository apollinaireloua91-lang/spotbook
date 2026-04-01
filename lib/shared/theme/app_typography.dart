import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographie Spotbook — Plus Jakarta Sans (lisible, moderne).
/// Hiérarchie : logo marque → titres d’écran → sections (overline) → corps.
abstract final class AppTypography {
  /// Marque « Spotbook » — texte blanc uniquement (spec), lisible sur vidéo.
  static TextStyle spotbookLogo({bool onVideoBackground = false}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.05,
      color: AppColors.blanc,
      shadows: onVideoBackground
          ? const [
              Shadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  /// Onglets « Découvrir / Abonnements » (style pilule feed client).
  static TextStyle feedTab({required bool active}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      height: 1.2,
      color: active
          ? AppColors.blanc
          : AppColors.blanc.withAlpha(153),
    );
  }

  /// Titre de bottom sheet (ex. « Créer »).
  static TextStyle get sheetTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.2,
        color: AppColors.blanc,
      );

  /// Titre AppBar standard (pas de dépendance au [ThemeData] — police garantie).
  static TextStyle get appBarTitle => GoogleFonts.plusJakartaSans(
        color: AppColors.blanc,
        fontWeight: FontWeight.w600,
        fontSize: 17,
        letterSpacing: 0.2,
        height: 1.2,
      );

  /// Sous-titre AppBar (ex. nombre d’avis).
  static TextStyle get appBarMetaLine => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.gris,
      );

  /// Libellé option dans une sheet « Créer » (pro).
  static TextStyle get createSheetOptionLabel => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.blanc,
      );

  /// Libellés de section type maquette (uppercase, tracking large).
  static TextStyle get sectionLabel => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        height: 1.2,
        color: AppColors.gris,
      );

  /// Grands titres shell pro (Explorer, Agenda, etc.).
  static TextStyle get proHubTitle => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
        color: AppColors.blanc,
      );

  /// Nom affiché profil (client, style « réseau social »).
  static TextStyle get profileDisplayName => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.2,
        color: AppColors.blanc,
      );

  /// @username et méta profil.
  static TextStyle get profileHandle => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.gris,
      );

  /// Bio / paragraphes secondaires profil.
  static TextStyle get profileBio => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.gris,
      );

  /// Légendes feed (nom pro, légende courte).
  static TextStyle feedCaption({bool emphasized = false}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      height: 1.35,
      color: AppColors.blanc,
      shadows: const [
        Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
      ],
    );
  }

  /// Texte très petit sous les actions (compteurs like, etc.).
  static TextStyle get feedActionCount => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: AppColors.blanc,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
        ],
      );

  /// Barre de navigation basse (client : actif en violet ; pro : géré séparément).
  static TextStyle navLabel({
    required bool selected,
    required bool isClientShell,
  }) {
    final color = selected
        ? (isClientShell ? AppColors.violet : AppColors.blanc)
        : AppColors.grisInactif;
    return GoogleFonts.plusJakartaSans(
      fontSize: 9,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      height: 1.1,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// [ThemeData.textTheme] sombre basé sur Plus Jakarta Sans + couleurs Spotbook.
  static TextTheme darkTextTheme(TextTheme base) {
    final jakarta = GoogleFonts.plusJakartaSansTextTheme(base);
    return jakarta.copyWith(
      displayLarge: jakarta.displayLarge?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      displayMedium: jakarta.displayMedium?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      headlineLarge: jakarta.headlineLarge?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.2,
      ),
      headlineMedium: jakarta.headlineMedium?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.25,
      ),
      headlineSmall: jakarta.headlineSmall?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.25,
      ),
      titleLarge: jakarta.titleLarge?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleMedium: jakarta.titleMedium?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: jakarta.titleSmall?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: jakarta.bodyLarge?.copyWith(
        color: AppColors.blanc,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: jakarta.bodyMedium?.copyWith(
        color: AppColors.gris,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: jakarta.bodySmall?.copyWith(
        color: AppColors.grisInactif,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      labelLarge: jakarta.labelLarge?.copyWith(
        color: AppColors.gris,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        height: 1.2,
      ),
      labelMedium: jakarta.labelMedium?.copyWith(
        color: AppColors.gris,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        height: 1.2,
      ),
      labelSmall: jakarta.labelSmall?.copyWith(
        color: AppColors.grisInactif,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.15,
      ),
    );
  }
}
