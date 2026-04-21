/// spotbook Design System — Canonical tokens.
///
/// Port fidèle de `design_reference/spotbook_design_system/colors_and_type.css`
/// et de la doc `docs/SPOTBOOK_DS_FLUTTER_PORT.md`.
///
/// **Règles strictes** (cf. `design_reference/.../SKILL.md`) :
/// - Palette 3 couleurs uniquement : accent, noir, blanc (+ deep purple en
///   surface intermédiaire dark only). Aucun vert, aucun rouge.
/// - Glows via [BoxShadow] uniquement — jamais de `BackdropFilter` ni
///   `ImageFilter.blur`.
/// - DM Sans exclusivement (400/500/600/700).
/// - Motion = signature : sonar rings + heartbeat + counter-rhythm halo.
///
/// Ce fichier est **additif** — il coexiste avec la palette legacy
/// (`shared/theme/app_colors.dart`). Il n'est consommé que par le feature POS
/// (`lib/features/pos/`) où les règles DS strictes s'appliquent. Le reste de
/// l'app continue d'utiliser `AppColors`.
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

// ═══════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════

/// Couleurs de la palette stricte spotbook.
///
/// Toute couleur hors de cette classe dans le feature POS est un bug.
abstract final class SpotbookColorsDs {
  // ---- Accent purple (le seul canal coloré autorisé) ----
  static const Color accentDark = Color(0xFF8E05C2);
  static const Color accentLight = Color(0xFF8039C5);

  /// Deep purple — surface intermédiaire en dark only (centre du gradient
  /// radial du reader, base du disque NFC).
  static const Color accentDeep = Color(0xFF3E065F);

  // ---- Neutres ----
  static const Color black = Color(0xFF000000);
  static const Color blackLight = Color(0xFF0C0C0C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF3F4F1);

  // ---- Alpha ramp sur l'accent (dark) ----
  static const Color accent08 = Color(0x148E05C2); // rgba(142,5,194,.08)
  static const Color accent15 = Color(0x268E05C2); // rgba(142,5,194,.15)
  static const Color accent30 = Color(0x4D8E05C2); // rgba(142,5,194,.30)
  static const Color accent60 = Color(0x998E05C2); // rgba(142,5,194,.60)
  static const Color accent80 = Color(0xCC8E05C2); // rgba(142,5,194,.80)
  static const Color accent90 = Color(0xE68E05C2); // rgba(142,5,194,.90)

  // ---- Ramp de texte sur fond noir (dark) ----
  static const Color foregroundPrimaryDark = Color(0xFFFFFFFF);
  static const Color foregroundSecondaryDark = Color(0xB8FFFFFF); // 72%
  static const Color foregroundTertiaryDark = Color(0x7AFFFFFF); // 48%
  static const Color foregroundDisabledDark = Color(0x29FFFFFF); // 16%

  // ---- Ramp de texte sur fond off-white (light) ----
  static const Color foregroundPrimaryLight = Color(0xFF0C0C0C);
  static const Color foregroundSecondaryLight = Color(0xB30C0C0C); // 70%
  static const Color foregroundTertiaryLight = Color(0x7A0C0C0C); // 48%
  static const Color foregroundDisabledLight = Color(0x290C0C0C); // 16%

  // ---- Borders ----
  static const Color borderDark = Color(0x1AFFFFFF); // 10%
  static const Color borderLight = Color(0x1A0C0C0C);

  // ---- Variantes internes du canal accent (SUCCESS / ERROR disque) ----
  // Ce ne sont PAS des couleurs « vert » ou « rouge » — ce sont des variantes
  // pourpres du canal accent, utilisées uniquement dans le gradient radial du
  // disque NFC pour signaler l'état :
  //   - SUCCESS : accent poussé plus brillant (`#A511DA` → `#6A0393`).
  //   - ERROR   : accent dimmé plus sombre   (`#6A0391` → `#2E0545`).
  static const Color discGradientStart = accentDark; // #8E05C2
  static const Color discGradientEnd = accentDeep; // #3E065F

  static const Color discSuccessStart = Color(0xFFA511DA);
  static const Color discSuccessEnd = Color(0xFF6A0393);

  static const Color discErrorStart = Color(0xFF6A0391);
  static const Color discErrorEnd = Color(0xFF2E0545);

  // ---- Background radial gradient stops (reader idle / active) ----
  static const Color bgIdleCenter = Color(0xFF1F0330);
  static const Color bgIdleMid = Color(0xFF0A0115);
  static const Color bgActiveCenter = accentDeep; // #3E065F
  static const Color bgActiveMid1 = Color(0xFF1A0230);
  static const Color bgActiveMid2 = Color(0xFF050008);
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════════════════

/// Échelle typographique stricte du DS. DM Sans uniquement.
///
/// Les [TextStyle] finaux sont construits dans `spotbook_pos_theme.dart` via
/// `GoogleFonts.dmSans(...)` pour centraliser le chargement de la police.
abstract final class SpotbookTypographyDs {
  static const String fontFamily = 'DM Sans';

  // ---- Scale ----
  static const double textDisplay = 40; // hero number
  static const double textTitle = 28; // state title
  static const double textHeading = 22;
  static const double textBody = 17;
  static const double textBodySm = 16; // subtitle
  static const double textLabel = 14;
  static const double textBadge = 18; // amount badge
  static const double textCaption = 12;

  // ---- Weights ----
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // ---- Line heights ----
  static const double lineHeightTight = 1.1;
  static const double lineHeightBody = 1.45;

  // ---- Letter spacing (converti depuis em × fontSize) ----
  static const double letterSpacingDisplay = textDisplay * -0.02; // -0.80
  static const double letterSpacingTitle = textTitle * -0.01; // -0.28
}

// ═══════════════════════════════════════════════════════════════════════════
// SPACING (8pt grid)
// ═══════════════════════════════════════════════════════════════════════════

abstract final class SpotbookSpacingDs {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;
}

// ═══════════════════════════════════════════════════════════════════════════
// RADII
// ═══════════════════════════════════════════════════════════════════════════

abstract final class SpotbookRadiiDs {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20; // badge
  static const double xl = 28; // pill button
  static const double full = 9999;
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOWS — BoxShadow uniquement, JAMAIS de blur filter
// ═══════════════════════════════════════════════════════════════════════════

abstract final class SpotbookGlowsDs {
  /// `--sb-glow-soft: 0 0 40px 6px rgba(142,5,194,.35)`
  static const BoxShadow soft = BoxShadow(
    color: Color(0x598E05C2), // 35%
    blurRadius: 40,
    spreadRadius: 6,
  );

  /// `--sb-glow-medium: 0 0 60px 10px rgba(142,5,194,.55)`
  static const BoxShadow medium = BoxShadow(
    color: Color(0x8C8E05C2), // 55%
    blurRadius: 60,
    spreadRadius: 10,
  );

  /// `--sb-glow-intense: 0 0 90px 18px rgba(142,5,194,.80)`
  static const BoxShadow intense = BoxShadow(
    color: Color(0xCC8E05C2), // 80%
    blurRadius: 90,
    spreadRadius: 18,
  );

  /// Double-stack glow utilisé sur le disque en état `success`.
  /// Correspond au box-shadow inline dans `PulseNfcIndicator.jsx` :
  /// `0 0 90px 18px rgba(142,5,194,0.9), 0 0 40px 6px rgba(142,5,194,0.6)`.
  static const List<BoxShadow> discSuccess = [
    BoxShadow(
      color: Color(0xE68E05C2), // 90%
      blurRadius: 90,
      spreadRadius: 18,
    ),
    BoxShadow(
      color: Color(0x998E05C2), // 60%
      blurRadius: 40,
      spreadRadius: 6,
    ),
  ];

  /// Glow standard du disque (tous les autres états).
  static const List<BoxShadow> discDefault = [medium];
}

// ═══════════════════════════════════════════════════════════════════════════
// MOTION — durations + curves
// ═══════════════════════════════════════════════════════════════════════════

abstract final class SpotbookMotionDs {
  // ---- Durations (`--sb-dur-*`) ----
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pulse = Duration(milliseconds: 1200); // heartbeat
  static const Duration wave = Duration(milliseconds: 1800); // sonar ring
  static const Duration halo = Duration(milliseconds: 800); // inner halo
  static const Duration finalWave = Duration(milliseconds: 1100); // celebration
  static const Duration iconSuccess = Duration(milliseconds: 600); // elastic
  static const Duration spinner = Duration(milliseconds: 900); // processing
  static const Duration shakeStep = Duration(milliseconds: 100); // shake unit
  static const Duration shakeTotal = Duration(milliseconds: 300); // 3 × 100ms
  static const Duration hapticFlash = Duration(milliseconds: 220);
  static const Duration hapticHeavy = Duration(milliseconds: 280);
  static const Duration backgroundMorph = Duration(milliseconds: 600);
  static const Duration stateIn = Duration(milliseconds: 250);
  static const Duration seeking = Duration(milliseconds: 2400);

  // ---- Curves (portées 1-à-1 depuis CSS cubic-bezier) ----
  /// `cubic-bezier(0.2, 0, 0, 1)` — easing générique UI.
  static const Cubic easeStandard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// `cubic-bezier(0.165, 0.84, 0.44, 1)` — sonar scale, finalWave.
  static const Cubic easeOutQuart = Cubic(0.165, 0.84, 0.44, 1.0);

  /// `cubic-bezier(0.895, 0.03, 0.685, 0.22)` — sonar opacity fade-out.
  static const Cubic easeInQuart = Cubic(0.895, 0.03, 0.685, 0.22);

  /// `cubic-bezier(0.445, 0.05, 0.55, 0.95)` — heartbeat, halo.
  static const Cubic easeInOutSine = Cubic(0.445, 0.05, 0.55, 0.95);

  /// `cubic-bezier(0.175, 0.885, 0.32, 1.275)` — success icon entrance.
  static const Cubic easeElasticOut = Cubic(0.175, 0.885, 0.32, 1.275);

  // ---- Multiplicateurs de vitesse (PulseNfcIndicator.jsx ligne 8) ----
  /// État `readingCard` accélère toutes les couches d'un facteur 0.5.
  static const double readingCardSpeedMultiplier = 0.5;
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYOUT — constantes de positionnement du reader
// ═══════════════════════════════════════════════════════════════════════════

abstract final class SpotbookReaderLayoutDs {
  /// Offset du top row (close + amount) depuis le haut de l'écran.
  static const double topOffset = 60;

  /// Offset du bouton cancel depuis le bas.
  static const double bottomOffset = 48;

  /// Padding horizontal du top row.
  static const double topHorizontalPadding = 20;

  /// Diamètre du disque NFC central (et des rings sonar).
  static const double pulseDiscSize = 160;

  /// Diamètre du halo interne.
  static const double pulseHaloSize = 40;

  /// Gap vertical entre le disque et le bloc state (title + subtitle).
  static const double discToStateGap = 48;

  /// Taille du bouton close (top-left).
  static const double closeButtonSize = 40;

  /// Icône au cœur du disque en état idle / waiting / reading / processing.
  static const double iconSizeBase = 72;

  /// Icône au cœur du disque en état success (plus grande pour la célébration).
  static const double iconSizeSuccess = 84;

  /// Icône close (top-left) et icône cancel (inline).
  static const double iconSizeAffordance = 28;

  /// Icône glyph dans le bouton close (plus petite que l'affordance).
  static const double iconSizeCloseGlyph = 20;

  // ---- Sonar rings ----
  /// 4 rings avec phase offsets 0 / 0.25 / 0.5 / 0.75.
  static const List<double> sonarPhases = <double>[0.0, 0.25, 0.5, 0.75];

  /// Scale tween du ring : de 0.6 à 2.5.
  static const double sonarScaleBegin = 0.6;
  static const double sonarScaleEnd = 2.5;

  /// Opacity tween du ring : de 0.8 à 0.
  static const double sonarOpacityBegin = 0.8;
  static const double sonarOpacityEnd = 0.0;

  // ---- Heartbeat ----
  /// Scale tween heartbeat : de 1.0 à 1.08 (puis retour).
  static const double heartbeatScaleBegin = 1.0;
  static const double heartbeatScaleEnd = 1.08;

  // ---- Halo (counter-rhythm) ----
  /// Scale tween halo : de 0.5 à 1.2 (puis retour).
  static const double haloScaleBegin = 0.5;
  static const double haloScaleEnd = 1.2;

  // ---- Final wave (success) ----
  /// Scale tween final wave : de 1 à 8, opacity 0.9 à 0.
  static const double finalWaveScaleBegin = 1.0;
  static const double finalWaveScaleEnd = 8.0;
  static const double finalWaveOpacityBegin = 0.9;
  static const double finalWaveOpacityEnd = 0.0;

  // ---- Error shake ----
  /// Déplacement horizontal : ±8 px.
  static const double shakeOffsetPx = 8;

  // ---- Success icon entrance ----
  /// Scale tween elastic : 0 → 1.2 → 1 (géré par la curve [easeElasticOut]).
  static const double successIconScaleBegin = 0.0;
  static const double successIconScaleEnd = 1.0;

  // ---- Seeking icon ----
  /// Rotation en radians : ±3° (≈ ±0.0524 rad).
  static const double seekingRotationRadians = 3 * 3.141592653589793 / 180;

  // ---- Error state disc opacity ----
  /// Le disque est dimmé à 70% d'opacité en état error.
  static const double errorDiscOpacity = 0.70;

  // ---- State indicator ----
  /// Opacity du sous-titre (matches CSS `.sb-state-sub { opacity: 0.60 }`).
  static const double subtitleOpacity = 0.60;

  /// Min height du bloc state (pour éviter les sauts de layout).
  static const double stateBlockMinHeight = 90;

  /// Padding horizontal du bloc state.
  static const double stateBlockHorizontalPadding = 40;

  /// Largeur max du bloc state.
  static const double stateBlockMaxWidth = 480;
}
