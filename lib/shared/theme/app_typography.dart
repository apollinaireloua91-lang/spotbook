import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographie Spotbook — DM Sans (corps, labels, boutons).
/// Hiérarchie : logo marque → titres d'écran → sections (overline) → corps.
abstract final class AppTypography {
  /// Marque « Spotbook » — DM Sans bold, 20px.
  /// On light bg: dark text. On video: white + shadow.
  static TextStyle spotbookLogo({bool onVideoBackground = false}) {
    return GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.05,
      color: onVideoBackground ? AppColors.textOnVideo : AppColors.blanc,
      shadows: onVideoBackground
          ? const [
              Shadow(
                color: AppColors.shadowTextLight,
                blurRadius: 10,
                offset: Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  /// Onglets « Découvrir / Abonnements » (style pilule feed client — on video).
  static TextStyle feedTab({required bool active}) {
    return GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      height: 1.2,
      color: active
          ? AppColors.textOnVideo
          : AppColors.textOnVideo.withAlpha(153),
    );
  }

  /// Titre de bottom sheet (ex. « Créer »).
  static TextStyle get sheetTitle => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.2,
        color: AppColors.blanc,
      );

  /// Titre AppBar standard (pas de dépendance au [ThemeData] — police garantie).
  static TextStyle get appBarTitle => GoogleFonts.dmSans(
        color: AppColors.blanc,
        fontWeight: FontWeight.w600,
        fontSize: 17,
        letterSpacing: 0.2,
        height: 1.2,
      );

  /// Sous-titre AppBar (ex. nombre d'avis).
  static TextStyle get appBarMetaLine => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.gris,
      );

  /// Libellé option dans une sheet « Créer » (pro).
  static TextStyle get createSheetOptionLabel => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.blanc,
      );

  /// Libellés de section type maquette (uppercase, tracking large).
  static TextStyle get sectionLabel => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        height: 1.2,
        color: AppColors.gris,
      );

  /// Grands titres shell pro (Explorer, Agenda, etc.).
  static TextStyle get proHubTitle => GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
        color: AppColors.blanc,
      );

  /// Nom affiché profil (client, style « réseau social »).
  static TextStyle get profileDisplayName => GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.2,
        color: AppColors.blanc,
      );

  /// @username et méta profil.
  static TextStyle get profileHandle => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.gris,
      );

  /// Bio / paragraphes secondaires profil.
  static TextStyle get profileBio => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.gris,
      );

  /// Légendes feed (nom pro, légende courte) — on video, keep white + shadow.
  static TextStyle feedCaption({bool emphasized = false}) {
    return GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      height: 1.35,
      color: AppColors.textOnVideo,
      shadows: const [
        Shadow(color: AppColors.overlayHeavy, blurRadius: 6, offset: Offset(0, 1)),
      ],
    );
  }

  /// Texte très petit sous les actions (compteurs like, etc.) — on video.
  static TextStyle get feedActionCount => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: AppColors.textOnVideo,
        shadows: const [
          Shadow(color: AppColors.overlayHeavy, blurRadius: 4, offset: Offset(0, 1)),
        ],
      );

  /// Barre de navigation basse (client : actif en vert ; pro : géré séparément).
  static TextStyle navLabel({
    required bool selected,
    required bool isClientShell,
  }) {
    final color = selected
        ? AppColors.violet
        : AppColors.grisInactif;
    return GoogleFonts.dmSans(
      fontSize: 9,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      height: 1.1,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// [ThemeData.textTheme] light basé sur DM Sans + couleurs Spotbook.
  static TextTheme lightTextTheme(TextTheme base) {
    final jakarta = GoogleFonts.dmSansTextTheme(base);
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
