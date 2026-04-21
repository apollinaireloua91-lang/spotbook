# spotbook Design System — Port vers Flutter

> **Source de vérité** : `design_reference/spotbook_design_system/` (skill `spotbook-design`, `user-invocable: true`).
> **Règle d'or** : on ne ré-invente rien — on porte fidèlement. Tout écart est documenté comme « compromis » dans la dernière section.

---

## 0. Règles strictes non-négociables (extraites de `SKILL.md` + `README.md`)

1. **Palette 3 couleurs strictes.**
   - Accent pourpre : `#8E05C2` (dark) / `#8039C5` (light).
   - Deep purple `#3E065F` : surface intermédiaire **dark only** (centre du gradient radial, base du disque NFC).
   - Neutres : `#000000` / `#0C0C0C` pour noirs, `#FFFFFF` / `#F3F4F1` pour blancs.
   - **Toute autre couleur est un bug.** Pas de vert, pas de rouge. Succès = accent *plus brillant* (`#A511DA` → `#6A0393` dans le gradient success uniquement, variante interne de l'accent). Erreur = accent dimmé à 70% opacité + gradient plus sombre `#6A0391` → `#2E0545`.

2. **Typographie : DM Sans exclusivement** (400 / 500 / 600 / 700). Pas de fallback à Sora. Letter-spacing titres `−0.01em` à `−0.02em`, body line-height 1.45, titles 1.1.

3. **Copy** : français, sentence case (`Prêt à encaisser`, pas `Prêt À Encaisser`). Pas d'emoji, pas de `!`, pas de « vous » de politesse. Impératif implicite. Client référencé comme « le client ».

4. **Glows via `BoxShadow` uniquement.** **Jamais** de `BackdropFilter`, `ImageFilter.blur`, `BackdropFilter.blur`. Jamais.

5. **60 fps garanti.** `RepaintBoundary` autour de chaque couche animée. Animations via `AnimationController` dédié par couche, curves CSS cubic-bezier portées à l'identique.

6. **Motion = signature de marque.** Les 3 couches du disque NFC (sonar + heartbeat + halo contre-rythme) ne sont pas optionnelles — c'est *l'identité* visuelle de l'écran de lecture.

7. **Iconographie** : Material Icons (Rounded) natifs Flutter — `Icons.contactless_outlined`, `Icons.nfc`, `Icons.check_rounded`, `Icons.close_rounded`. Taille : 72 px (core), 84 px (success), 28 px (affordances), 20 px (close). Blanc pur, pas de variantes colorées.

8. **Reduced motion** : sous `MediaQuery.of(context).disableAnimations`, toutes les durées animées sont ramenées à 4 s (match `@media (prefers-reduced-motion: reduce)`).

---

## 1. Tokens CSS → constantes Dart

Mapping 1 ligne / 1 ligne. Cible : `lib/core/theme/spotbook_tokens.dart`.

### Couleurs

| CSS token | Valeur | Dart constante |
|---|---|---|
| `--sb-accent` | `#8E05C2` | `SpotbookColors.accentDark` |
| `--sb-accent-light` | `#8039C5` | `SpotbookColors.accentLight` |
| `--sb-accent-deep` | `#3E065F` | `SpotbookColors.accentDeep` |
| `--sb-black` | `#000000` | `SpotbookColors.black` |
| `--sb-black-light` | `#0C0C0C` | `SpotbookColors.blackLight` |
| `--sb-white` | `#FFFFFF` | `SpotbookColors.white` |
| `--sb-off-white` | `#F3F4F1` | `SpotbookColors.offWhite` |
| `--sb-accent-08` | `rgba(142,5,194,0.08)` | `SpotbookColors.accentDark.withValues(alpha: .08)` (getter `accent08`) |
| `--sb-accent-15` | `rgba(142,5,194,0.15)` | `accent15` |
| `--sb-accent-30` | `rgba(142,5,194,0.30)` | `accent30` |
| `--sb-accent-60` | `rgba(142,5,194,0.60)` | `accent60` |
| `--sb-accent-80` | `rgba(142,5,194,0.80)` | `accent80` |
| `--sb-fg-1` (dark) | `rgba(255,255,255,1)` | `foregroundPrimaryDark` |
| `--sb-fg-2` (dark) | `rgba(255,255,255,0.72)` | `foregroundSecondaryDark` |
| `--sb-fg-3` (dark) | `rgba(255,255,255,0.48)` | `foregroundTertiaryDark` |
| `--sb-fg-4` (dark) | `rgba(255,255,255,0.16)` | `foregroundDisabledDark` |
| `--sb-fg-1` (light) | `rgba(12,12,12,1)` | `foregroundPrimaryLight` |
| `--sb-fg-2` (light) | `rgba(12,12,12,0.70)` | `foregroundSecondaryLight` |
| `--sb-fg-3` (light) | `rgba(12,12,12,0.48)` | `foregroundTertiaryLight` |
| `--sb-fg-4` (light) | `rgba(12,12,12,0.16)` | `foregroundDisabledLight` |
| `--sb-border` (dark) | `rgba(255,255,255,0.10)` | `borderDark` |
| `--sb-border` (light) | `rgba(12,12,12,0.10)` | `borderLight` |

**Gradient success (interne au disque, SUCCESS state uniquement)** :
- Centre `#A511DA` → bord `#6A0393`. C'est une *variante interne du canal accent pourpre*, pas une nouvelle couleur.

**Gradient error (interne au disque, ERROR state uniquement)** :
- Centre `#6A0391` → bord `#2E0545`. Même canal, dimmé.

### Typographie

| CSS token | Valeur | Dart |
|---|---|---|
| `--sb-font` | `DM Sans` | `SpotbookTypography.fontFamily = 'DM Sans'` |
| `--sb-text-display` | 40 px | `textDisplay = 40` |
| `--sb-text-title` | 28 px | `textTitle = 28` |
| `--sb-text-heading` | 22 px | `textHeading = 22` |
| `--sb-text-body` | 17 px | `textBody = 17` |
| `--sb-text-body-sm` | 16 px | `textBodySm = 16` |
| `--sb-text-label` | 14 px | `textLabel = 14` |
| `--sb-text-badge` | 18 px | `textBadge = 18` |
| `--sb-text-caption` | 12 px | `textCaption = 12` |
| `--sb-w-regular/medium/semibold/bold` | 400/500/600/700 | `weightRegular/Medium/Semibold/Bold = FontWeight.w400/500/600/700` |
| `--sb-lh-tight` | 1.1 | `lineHeightTight = 1.1` |
| `--sb-lh-body` | 1.45 | `lineHeightBody = 1.45` |
| letter-spacing display | `−0.02em` | `letterSpacingDisplay = 40 * -0.02 = -0.8` |
| letter-spacing title | `−0.01em` | `letterSpacingTitle = 28 * -0.01 = -0.28` |

Les TextStyle prêts-à-l'emploi (`sbDisplay`, `sbTitle`, `sbHeading`, `sbBody`, `sbSubtitle`, `sbLabel`, `sbBadge`, `sbCaption`) sont construits dans `SpotbookTypography` via `GoogleFonts.dmSans(...)`.

### Spacing (8pt grid)

| CSS | Dart |
|---|---|
| `--sb-s-1` 4 | `SpotbookSpacing.s1 = 4` |
| `--sb-s-2` 8 | `s2 = 8` |
| `--sb-s-3` 12 | `s3 = 12` |
| `--sb-s-4` 16 | `s4 = 16` |
| `--sb-s-5` 24 | `s5 = 24` |
| `--sb-s-6` 32 | `s6 = 32` |
| `--sb-s-7` 48 | `s7 = 48` |
| `--sb-s-8` 64 | `s8 = 64` |

### Radii

| CSS | Dart |
|---|---|
| `--sb-r-sm` 8 | `SpotbookRadii.sm = 8` |
| `--sb-r-md` 14 | `md = 14` |
| `--sb-r-lg` 20 | `lg = 20` (badge) |
| `--sb-r-xl` 28 | `xl = 28` (bouton pill) |
| `--sb-r-full` 9999 | `full = 9999` |

### Glows (BoxShadow)

| CSS | Dart (`SpotbookGlows`) |
|---|---|
| `--sb-glow-soft` `0 0 40px 6px rgba(142,5,194,0.35)` | `soft = BoxShadow(blurRadius: 40, spreadRadius: 6, color: accentDark.withValues(alpha: .35))` |
| `--sb-glow-medium` `0 0 60px 10px rgba(142,5,194,0.55)` | `medium = BoxShadow(blurRadius: 60, spreadRadius: 10, color: accentDark.withValues(alpha: .55))` |
| `--sb-glow-intense` `0 0 90px 18px rgba(142,5,194,0.80)` | `intense = BoxShadow(blurRadius: 90, spreadRadius: 18, color: accentDark.withValues(alpha: .80))` |

### Motion — durations & curves

| CSS token | Valeur | Dart |
|---|---|---|
| `--sb-dur-fast` | 120 ms | `SpotbookMotion.fast = Duration(milliseconds: 120)` |
| `--sb-dur-base` | 250 ms | `base = 250ms` |
| `--sb-dur-slow` | 400 ms | `slow = 400ms` |
| `--sb-dur-pulse` | 1200 ms | `pulse = 1200ms` |
| `--sb-dur-wave` | 1800 ms | `wave = 1800ms` |
| — | 800 ms (halo) | `halo = 800ms` |
| — | 1100 ms (finalWave) | `finalWave = 1100ms` |
| — | 600 ms (iconSuccess) | `iconSuccess = 600ms` |
| — | 100 ms × 3 (shake) | `shake = 100ms`, répété 3× |
| — | 900 ms (spinner) | `spinner = 900ms` |
| — | 220 ms (haptic flash) | `hapticFlash = 220ms` |
| `--sb-ease-standard` | `cubic-bezier(0.2,0,0,1)` | `easeStandard = Cubic(0.2, 0.0, 0.0, 1.0)` |
| `--sb-ease-out-quart` | `cubic-bezier(0.165,0.84,0.44,1)` | `easeOutQuart = Cubic(0.165, 0.84, 0.44, 1.0)` |
| `--sb-ease-in-quart` | `cubic-bezier(0.895,0.03,0.685,0.22)` | `easeInQuart = Cubic(0.895, 0.03, 0.685, 0.22)` |
| `--sb-ease-in-out-sine` | `cubic-bezier(0.445,0.05,0.55,0.95)` | `easeInOutSine = Cubic(0.445, 0.05, 0.55, 0.95)` |
| `--sb-ease-elastic-out` | `cubic-bezier(0.175,0.885,0.32,1.275)` | `easeElasticOut = Cubic(0.175, 0.885, 0.32, 1.275)` |

> Flutter `Cubic(...)` accepte des x∈[0,1] et y∈ℝ (peut dépasser). L'élastique `y=1.275` est donc valide.

---

## 2. CSS `@keyframes` → `AnimationController` Flutter

Chaque keyframe est porté en un controller dédié. **Un controller par couche animée.** Les Tweens lisent les valeurs CSS à l'identique.

### `pulseRing` (4 sonar rings)

- **CSS** : `scale 0.6 → 2.5`, `opacity 0.8 → 0`, linear, 1800 ms, 4 rings phase-offset `0 / 0.25 / 0.5 / 0.75`.
- **Flutter** :
  - `AnimationController(vsync: ..., duration: SpotbookMotion.wave)..repeat()`
  - Scale tween : `Tween(begin: 0.6, end: 2.5).chain(CurveTween(curve: SpotbookMotion.easeOutQuart))` — le README impose `ease-out-quart` sur scale, `ease-in-quart` sur opacity (CSS dit `linear` mais README fait autorité sur l'intention).
  - Opacity tween : `Tween(begin: 0.8, end: 0.0).chain(CurveTween(curve: SpotbookMotion.easeInQuart))`.
  - 4 rings : `Stack` de 4 widgets, chacun enveloppé dans un `AnimatedBuilder(animation: controller)` qui lit `(controller.value + phase) % 1.0` avec `phase ∈ {0, 0.25, 0.5, 0.75}`.
  - **Performance** : un *seul* `AnimationController` partagé par les 4 rings, chaque ring applique son offset de phase au moment du read. `RepaintBoundary` par ring.

### `pulseBeat` (heartbeat disc)

- **CSS** : `scale 1.0 → 1.08 → 1.0`, `cubic-bezier(0.445,0.05,0.55,0.95)` (= ease-in-out-sine), 1200 ms, infinite.
- **Flutter** : `AnimationController(duration: SpotbookMotion.pulse)..repeat(reverse: true)` avec `Tween(begin: 1.0, end: 1.08).chain(CurveTween(curve: SpotbookMotion.easeInOutSine))`. Le `reverse: true` reproduit le `0% → 50% → 100%` sur moitié de durée.

### `pulseHalo` (inner halo contre-rythme)

- **CSS** : `scale 0.5 → 1.2`, `cubic-bezier(0.445,0.05,0.55,0.95)`, 800 ms.
- **Flutter** : `AnimationController(duration: SpotbookMotion.halo)..repeat(reverse: true)`, `Tween(0.5, 1.2)` + `easeInOutSine`. Halo est un `Container` 40×40 circulaire avec accent fill + `BoxShadow(blurRadius: 60, spreadRadius: 10, color: accent80)`. Pas de blur filter — juste le shadow.

### `finalWave` (célébration success)

- **CSS** : `scale 1 → 8`, `opacity 0.9 → 0`, `cubic-bezier(0.165,0.84,0.44,1)` (ease-out-quart), 1100 ms, `forwards`.
- **Flutter** : `AnimationController(duration: SpotbookMotion.finalWave)..forward()`, *one-shot*. Scale + opacity Tweens chained sur `easeOutQuart`. Widget de 160×160 circulaire avec `RadialGradient(center: center, colors: [accent60, transparent])`. Spawn au moment du `success`, dispose après complétion.

### `pulseSpinner` (processing)

- **CSS** : rotation `360°` linéaire, 900 ms.
- **Flutter** : `CustomPaint` avec un arc (`Canvas.drawArc`) + `RotationTransition(turns: controller)` où controller est `..repeat()` sur 900 ms. Arc de ~40/85 sur la circonférence (matches `strokeDasharray="40 85"`), stroke blanc 3 px, linecap round.

### `shake` (erreur)

- **CSS** : `translateX 0 → −8px → 8px → 0`, 100 ms × 3.
- **Flutter** : `AnimationController(duration: 300ms)` (100 ms × 3). Tween en `TweenSequence` : 4 étapes (0, −8, 8, 0) sur intervals 0-25%, 25-75%, 75-100%. `Transform.translate(offset: Offset(dx, 0))` sur le wrapper disc.

### `seeking` (icône contactless en idle)

- **CSS** : `rotate(−3deg → 3deg)`, ease-in-out, infinite 2400 ms.
- **Flutter** : `AnimationController(duration: 2400ms)..repeat(reverse: true)` + `Transform.rotate(angle: tween)` avec `Tween(-3°, 3°)` convertis en radians (`-3 * pi / 180`).

### `iconEnter` (icône mount/change)

- **CSS** : `opacity 0 → 1`, `scale 0.8 → 1`, 300 ms ease-out.
- **Flutter** : wrapper l'icône dans `AnimatedSwitcher(duration: 300ms, transitionBuilder: ScaleTransition + FadeTransition)`. Le `key` change à chaque changement de glyph (contactless / check / close) → force le replay.

### `iconSuccess` (check elastic-out entrance)

- **CSS** : `scale 0 → 1.2 → 1`, `cubic-bezier(0.175,0.885,0.32,1.275)`, 600 ms, `forwards`.
- **Flutter** : `AnimationController(duration: SpotbookMotion.iconSuccess)..forward()` + `Tween(0.0, 1.0)` sur `easeElasticOut`. La courbe elastic gère naturellement le dépassement à 1.2 puis retour à 1.0. One-shot.

### `stateIn` (title/subtitle fade)

- **CSS** : `opacity 0 → endOpacity` (1 pour title, 0.6 pour sub), `scale 0.95 → 1`, 250 ms ease-out.
- **Flutter** : `AnimatedSwitcher(duration: 250ms, transitionBuilder: fade + scale)` avec `key` = `state`. Target opacity = `Opacity` wrapper (1.0 ou 0.6).

### `hapticFlash` / `hapticHeavy` (visual stand-in)

- **CSS** : `inset box-shadow` flash radial, 220 ms / 280 ms.
- **Flutter** : *pas besoin de porter le flash visuel*. Côté Flutter on déclenche le vrai `HapticFeedback.selectionClick()` / `.lightImpact()` / `.heavyImpact()` / `.mediumImpact()` via le package `flutter/services.dart`. Le flash visuel était un stand-in HTML pour un vrai haptique — on a le vrai ici.

### Mapping état → haptique (depuis `PosReaderPage.jsx`)

| State | `flutter/services.dart` |
|---|---|
| `waitingForCard` | `HapticFeedback.selectionClick()` |
| `readingCard` | `HapticFeedback.lightImpact()` |
| `success` | `HapticFeedback.heavyImpact()` |
| `error` | `HapticFeedback.mediumImpact()` |

### Accélération `readingCard`

- `PulseNfcIndicator.jsx` ligne 8 : `const speed = state === 'readingCard' ? 0.5 : 1;`
- Flutter : multiplicateur appliqué aux durées des 3 controllers (wave, beat, halo). Implémentation : `controller.duration = Duration(milliseconds: baseMs ~/ (state == readingCard ? 2 : 1))` puis `controller.repeat()`.

### Arrêts par état (`stopOuter`)

- `processing`, `success`, `error` → `stopOuter = true` → **sonar rings supprimés du Stack** (pas juste mis en pause — carrément démontés pour libérer les tickers).
- `success` + `error` → `pulse-disc` `animation-play-state: paused` → `controller.stop()`.

---

## 3. Gradients radiaux

### Background `sb-reader`

- **Idle** : `radial-gradient(circle at 50% 50%, #1F0330 0%, #0A0115 45%, #000 100%)`.
- **Active** : `radial-gradient(circle at 50% 48%, #3E065F 0%, #1A0230 38%, #050008 70%, #000 100%)`.
- **Transition** : `background 600ms ease-standard`.
- **Flutter** : `AnimatedContainer(duration: 600ms, curve: easeStandard, decoration: BoxDecoration(gradient: RadialGradient(...)))`. `RadialGradient` accepte `stops: [0.0, 0.38, 0.70, 1.0]` et `center: Alignment(0, -0.04)` (50% x, 48% y → y = 2*(0.48 - 0.5) = −0.04 en Flutter alignment space, qui va −1 à +1).

### Disc interne

- **Default** : `radial-gradient(circle at center, #8E05C2 0%, #3E065F 100%)`.
- **Success** : `radial-gradient(circle at center, #A511DA 0%, #6A0393 100%)`.
- **Error** : `radial-gradient(circle at center, #6A0391 0%, #2E0545 100%)`.
- **Transition background** : 250 ms ease.
- **Flutter** : `AnimatedContainer(duration: 250ms)` + `BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [...]))`. Les 3 variantes sont des constantes de `SpotbookTokens`.

---

## 4. JSX components → Flutter widgets

| JSX file | Flutter file | Type |
|---|---|---|
| `PulseNfcIndicator.jsx` | `lib/features/pos/presentation/widgets/pulse_nfc_indicator.dart` | `StatefulWidget` (plusieurs `AnimationController`) |
| `ReaderChrome.jsx` (`AmountBadge`) | `lib/features/pos/presentation/widgets/amount_badge.dart` | `StatelessWidget` |
| `ReaderChrome.jsx` (`CloseButton`) | `lib/features/pos/presentation/widgets/close_icon_button.dart` | `StatelessWidget` |
| `ReaderChrome.jsx` (`ReaderStateIndicator`) | `lib/features/pos/presentation/widgets/reader_state_indicator.dart` | `StatelessWidget` avec `AnimatedSwitcher` |
| `ReaderChrome.jsx` (`CancelButton`) | `lib/features/pos/presentation/widgets/cancel_button.dart` | `StatelessWidget` |
| `PosReaderPage.jsx` | `lib/features/pos/presentation/pages/pos_reader_page.dart` | `ConsumerStatefulWidget` — consomme `posPaymentProvider` |
| (copies FR `STATE_COPY`) | `lib/features/pos/presentation/_state_copy.dart` | Map const |
| `ios-frame.jsx` | — | Pas porté (frame simulateur web, inutile en natif) |

---

## 5. ThemeData

- `SpotbookTheme.dark()` : `brightness: dark`, `scaffoldBackgroundColor: black`, `primaryColor: accentDark`, `colorScheme: ColorScheme.dark(primary: accentDark, surface: accentDeep, onSurface: white, onPrimary: white, error: accentDark.withValues(alpha: .70))` *(erreur = accent dimmé, zéro rouge)*, `textTheme: SpotbookTypography.buildTextTheme(isDark: true)`.
- `SpotbookTheme.light()` : `brightness: light`, `scaffoldBackgroundColor: white`, `primaryColor: accentLight`, `colorScheme: ColorScheme.light(primary: accentLight, surface: offWhite, onSurface: blackLight, onPrimary: white, error: accentLight.withValues(alpha: .70))`, `textTheme: ... isDark: false`.
- `DM Sans` chargé via `google_fonts: ^6.x` (déjà dans `pubspec.yaml` — à vérifier). On **ne** déclare **pas** un asset local à moins d'un build offline.

---

## 6. Copies FR exactes (depuis `ReaderChrome.jsx`)

```dart
const kSbStateCopy = <PosReaderState, ({String title, String? sub})>{
  PosReaderState.initializing:   (title: 'Initialisation…', sub: null),
  PosReaderState.ready:          (title: 'Prêt à encaisser', sub: null),
  PosReaderState.waitingForCard: (title: 'Approchez la carte du client', sub: 'Ou présentez le téléphone du client au dos de votre iPhone'),
  PosReaderState.readingCard:    (title: 'Lecture en cours', sub: 'Ne bougez pas l\u2019appareil'),
  PosReaderState.processing:     (title: 'Traitement du paiement', sub: 'Confirmation auprès de la banque'),
  PosReaderState.succeeded:      (title: 'Paiement réussi', sub: null),
  PosReaderState.failed:         (title: 'Une erreur est survenue', sub: 'Carte non lue — réessayez'),
};
```

⚠️ `PosReaderState` côté Flutter (`lib/features/pos/domain/pos_models.dart`) a aussi `discoveringReaders`, `connectingReader`, `readerReady`, `collectingPaymentMethod`, `canceled` qui ne sont pas dans le JSX. On mappe :
- `discoveringReaders` / `connectingReader` → copie `ready` (micro-phase transitoire).
- `readerReady` → `ready`.
- `collectingPaymentMethod` → `waitingForCard`.
- `canceled` → on quitte la page (pas d'état UI dédié).

---

## 7. Rendu chrome (top/center/bottom)

Layout absolu CSS → `Stack` Flutter avec `SafeArea`-aware positioning.

- **Top row** : `Positioned(top: 60, left: 20, right: 20)` avec `Row(mainAxisAlignment: spaceBetween)` → `CloseIconButton` + `AmountBadge`.
- **Center** : `Positioned.fill` + `Align(alignment: center)` → `Column(mainAxisSize: min, children: [PulseNfcIndicator, SizedBox(height: 48), ReaderStateIndicator])`.
- **Bottom** : `Positioned(bottom: 48, left: 0, right: 0)` + `Center(child: CancelButton(disabled: state.isProcessingOrSucceeded))`.
- Root : `AnimatedContainer` (gradient idle ⇄ active), `Material(color: transparent)` pour ripples si jamais.

---

## 8. Compromis (écarts assumés)

1. **CSS `animation-timing-function: linear` sur `pulseRing`** vs **README impose `ease-out-quart` sur scale, `ease-in-quart` sur opacity.** Le README est plus précis, on suit le README. Documenté ici pour trace.
2. **`pulse-spinner` SVG avec `strokeDasharray`** : porté en `CustomPaint` avec `Path` + `drawPath`. Proportions `40/85` = arc de `~106°` (`40 / (2π·20) · 360°`). On dessine donc un arc d'environ 106° sur 360°.
3. **`haptic-flash` visuel** : non porté. Remplacé par vrais `HapticFeedback.*` natifs, meilleure UX en production.
4. **Google Fonts DM Sans** : chargé au runtime via `google_fonts`. Le premier affichage peut avoir un flash si pas de cache local. On accepte (cohérent avec le reste du projet qui charge déjà Sora via google_fonts). Si besoin : `GoogleFonts.config.allowRuntimeFetching = false` + assets locaux `fonts/DMSans-*.ttf` dans `pubspec.yaml`. **À ne faire que si l'équipe valide l'ajout d'assets**.
5. **Debug panel** (`DebugStateBar`) : non porté en v1 — c'est un helper de démo web. On peut l'ajouter plus tard via un widget debug conditionné à `kDebugMode`.
6. **`ios-frame.jsx`** : non pertinent en Flutter natif.
7. **`RadialGradient` Flutter center** : mappe `50% 48%` en `Alignment(0, -0.04)`. Différence imperceptible à l'écran mais notée pour exactitude.
8. **Inset haptic box-shadow CSS** : pas de `BoxShadow(inset: true)` en Flutter standard. Si on voulait le flash inset, il faudrait un `ShaderMask` radial. Non porté — on a le vrai haptique natif.

---

## 9. Checklist de conformité (à cocher avant chaque PR POS-DS)

- [ ] Aucune couleur hex brute dans un Widget — tout via `SpotbookColors.*`.
- [ ] Aucun `BackdropFilter` / `ImageFilter.blur` / `.blur` dans le diff.
- [ ] Aucune couleur verte (#..C.., #..E..) ni rouge (#E.., #F..) — sauf `SpotbookColors.white` et `.black`.
- [ ] Toutes les animations dans une `RepaintBoundary`.
- [ ] Toutes les copies en sentence case français, pas d'emoji, pas de `!`.
- [ ] `DM Sans` uniquement (aucun `GoogleFonts.sora`, `.poppins`, etc. dans les écrans POS).
- [ ] `flutter analyze` = 0.
- [ ] Testé sur simulateur iOS + appareil Android avec `MediaQuery disableAnimations = true` (reduced motion).

---

## 10. Références croisées

- CSS tokens : `design_reference/spotbook_design_system/colors_and_type.css`
- CSS keyframes : `design_reference/spotbook_design_system/ui_kits/pos/reader.css`
- JSX source : `design_reference/spotbook_design_system/ui_kits/pos/{PulseNfcIndicator,ReaderChrome,PosReaderPage}.jsx`
- Règles strictes : `design_reference/spotbook_design_system/SKILL.md` + `README.md`
- Preview HTML (à lancer dans un navigateur pour voir la référence finale) : `design_reference/spotbook_design_system/ui_kits/pos/index.html`
