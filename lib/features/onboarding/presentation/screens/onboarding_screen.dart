import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/theme/app_colors.dart';

/// Clé unique pour persister le flag « onboarding vu ». On écrit à la fois
/// dans SharedPreferences (source de vérité depuis 2026-04-21) et dans
/// Hive box 'settings' (compat descendante, lecteur fallback dans splash).
/// Voir splash_screen._navigateNext() pour la logique de migration.
const _onboardingSeenKey = 'onboarding_seen';

// ─── Page text data ────────────────────────────

class _PageText {
  const _PageText(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

const _pageTexts = [
  _PageText(
    'Découvrez des pros talentueux',
    'Trouvez les meilleurs professionnels près de chez vous.\nRegardez leur travail, lisez les avis, réservez instantanément.',
  ),
  _PageText(
    'Réservez en un clic',
    'Choisissez un service, sélectionnez un créneau,\nconfirmez votre réservation instantanément.',
  ),
  _PageText(
    'Développez votre activité',
    'Gérez vos réservations, suivez vos revenus\net atteignez de nouveaux clients chaque jour.',
  ),
];

// ─── Riverpod ──────────────────────────────────

class _PageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

final _pageProvider = NotifierProvider<_PageNotifier, int>(
  _PageNotifier.new,
  isAutoDispose: true,
);

// ─── Main Screen ───────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    HapticFeedback.mediumImpact();
    // Double-écriture :
    //  - SharedPreferences = source de vérité depuis la migration
    //    2026-04-21 (NSUserDefaults iOS, mieux aligné avec la convention
    //    plateforme + purgé à la désinstallation, comme Hive).
    //  - Hive = maintenu pour que les anciennes versions du splash qui
    //    liraient encore la box ne forcent pas l'onboarding à nouveau.
    //    À retirer dans une release future quand le rollback ne sera
    //    plus une préoccupation.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    await Hive.box('settings').put(_onboardingSeenKey, true);
    if (!mounted) return;
    context.go('/select-account-type');
  }

  void _next() {
    HapticFeedback.selectionClick();
    _pc.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(_pageProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Stack(
        children: [
          // ── Pages with 3D rotation transition ──
          PageView.builder(
            controller: _pc,
            onPageChanged: (i) =>
                ref.read(_pageProvider.notifier).set(i),
            itemCount: 3,
            itemBuilder: (_, i) => AnimatedBuilder(
              animation: _pc,
              builder: (_, child) {
                double v = 0;
                if (_pc.position.haveDimensions) {
                  v = ((i - (_pc.page ?? i.toDouble())) * 0.04)
                      .clamp(-1.0, 1.0);
                }
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(v),
                  child: child,
                );
              },
              child: const [
                _DiscoverPage(),
                _BookPage(),
                _GrowPage(),
              ][i],
            ),
          ),

          // ── Top bar ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, left: 20),
              child: Text(
                'Spotbook',
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // ── Bottom overlay: gradient + text + dots + buttons ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomOverlay(
              page: page,
              onSkip: _complete,
              onNext: () {
                HapticFeedback.lightImpact();
                if (page < 2) {
                  _next();
                } else {
                  _complete();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Overlay ────────────────────────────

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({
    required this.page,
    required this.onSkip,
    required this.onNext,
  });

  final int page;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final data = _pageTexts[page];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.fond.withAlpha(0),
            AppColors.fond.withAlpha(230),
            AppColors.fond,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 48, 24, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Column(
                key: ValueKey(page),
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris.withAlpha(200),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: active ? AppColors.gradientAccent : null,
                    color: active ? null : AppColors.gris.withAlpha(60),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Skip + Next / Get Started
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Passer',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onNext,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: page == 2 ? 28 : 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        page < 2 ? 'Suivant' : 'Commencer',
                        key: ValueKey(page < 2),
                        style: GoogleFonts.dmSans(
                          color: AppColors.blanc,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PAGE 1 — DISCOVER TALENTED PROS
// ═══════════════════════════════════════════════

class _DiscoverPage extends StatefulWidget {
  const _DiscoverPage();

  @override
  State<_DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<_DiscoverPage>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Violet radial gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 0.8,
              colors: [
                AppColors.violet.withAlpha(38),
                AppColors.fond,
              ],
            ),
          ),
        ),

        // Glowing constellation dots
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => CustomPaint(
              painter: _GlowDotsPainter(progress: _glow.value),
            ),
          ),
        ),

        // Floating pro cards
        _floatingCard(
          top: 120,
          left: 24,
          phase: 0.0,
          child: _proCard(
            'Kevin B.',
            'Barber',
            '\u2702\uFE0F',
            AppColors.rose,
          ),
        ),
        _floatingCard(
          top: 250,
          right: 16,
          phase: 0.33,
          child: _proCard(
            'Studio MTL',
            'Photo',
            '\uD83D\uDCF8',
            AppColors.violet,
          ),
        ),
        _floatingCard(
          top: 380,
          left: 40,
          phase: 0.66,
          child: _proCard(
            'Coach E.',
            'Fitness',
            '\uD83C\uDFCB\uFE0F',
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _floatingCard({
    double? top,
    double? left,
    double? right,
    required double phase,
    required Widget child,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _float,
        builder: (_, c) => Transform.translate(
          offset: Offset(0, sin((_float.value + phase) * 2 * pi) * 8),
          child: c,
        ),
        child: child,
      ),
    );
  }

  static Widget _proCard(
    String name,
    String category,
    String emoji,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blanc.withAlpha(15)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                category,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Glowing dots painter ──────────────────────

class _GlowDotsPainter extends CustomPainter {
  _GlowDotsPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 35; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.6 + size.height * 0.05;
      final baseR = 1.5 + rng.nextDouble() * 2;
      final phase = rng.nextDouble() * 2 * pi;
      final pulse = (sin(progress * 2 * pi + phase) + 1) / 2;
      final r = baseR * (0.5 + 0.5 * pulse);
      final a = (30 + 50 * pulse).toInt();

      // Glow halo
      canvas.drawCircle(
        Offset(x, y),
        r * 3,
        Paint()
          ..color = AppColors.violet.withAlpha(a ~/ 2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 2),
      );
      // Solid core
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = AppColors.violetClair.withAlpha(a + 30),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlowDotsPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════
// PAGE 2 — BOOK IN ONE TAP
// ═══════════════════════════════════════════════

class _BookPage extends StatefulWidget {
  const _BookPage();

  @override
  State<_BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<_BookPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tilt;

  @override
  void initState() {
    super.initState();
    _tilt = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Rose radial gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 0.7,
              colors: [
                AppColors.rose.withAlpha(30),
                AppColors.fond,
              ],
            ),
          ),
        ),

        // 3D tilting phone
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: AnimatedBuilder(
              animation: _tilt,
              builder: (_, child) {
                final t =
                    Curves.easeInOut.transform(_tilt.value) * 0.1 - 0.05;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(t)
                    ..rotateX(-0.02),
                  child: child,
                );
              },
              child: _phoneMockup(),
            ),
          ),
        ),

        // Pulsing check badge
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          right: 36,
          child: const _PulsingBadge(),
        ),
      ],
    );
  }

  Widget _phoneMockup() {
    return Container(
      width: 220,
      height: 420,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.blanc.withAlpha(20),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withAlpha(38),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: _bookingContent(),
      ),
    );
  }

  Widget _bookingContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Pro header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    '\u2702\uFE0F',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kevin Barber',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Premium Cut',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Service card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.fond.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fade & Design',
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '45 min',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '\$35',
                      style: GoogleFonts.dmSans(
                        color: AppColors.violetClair,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Time slots
          Text(
            'Aujourd\'hui',
            style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _slot('10:00', false),
              const SizedBox(width: 6),
              _slot('11:30', true),
              const SizedBox(width: 6),
              _slot('14:00', false),
            ],
          ),

          const Spacer(),

          // Book button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.gradientAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Réserver',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _slot(String time, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.violet.withAlpha(38)
            : AppColors.fond.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.violet : AppColors.border,
        ),
      ),
      child: Text(
        time,
        style: GoogleFonts.dmSans(
          color: selected ? AppColors.violetClair : AppColors.gris,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ─── Pulsing check badge ───────────────────────

class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge();

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) =>
          Transform.scale(scale: 0.9 + 0.1 * _pulse.value, child: child),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withAlpha(100),
              blurRadius: 20,
            ),
          ],
        ),
        child: Icon(
          Icons.check_rounded,
          color: AppColors.blanc,
          size: 28,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PAGE 3 — GROW YOUR BUSINESS
// ═══════════════════════════════════════════════

class _GrowPage extends StatefulWidget {
  const _GrowPage();

  @override
  State<_GrowPage> createState() => _GrowPageState();
}

class _GrowPageState extends State<_GrowPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Green radial gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 0.7,
              colors: [
                AppColors.success.withAlpha(25),
                AppColors.fond,
              ],
            ),
          ),
        ),

        // 3D dashboard card
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(-0.03),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.blanc.withAlpha(15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withAlpha(25),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Revenue header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Revenus',
                          style: GoogleFonts.dmSans(
                            color: AppColors.gris,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Ce mois-ci',
                          style: GoogleFonts.dmSans(
                            color: AppColors.grisInactif,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Animated counter
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: _entry,
                        builder: (_, __) {
                          final v =
                              Curves.easeOutCubic.transform(_entry.value);
                          final n = (2847 * v).toInt();
                          return Text(
                            '\$${_formatNumber(n)}',
                            style: GoogleFonts.sora(
                              color: AppColors.blanc,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Animated bar chart
                    _buildBarChart(),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniStat(
                          value: '24',
                          label: 'Réservations',
                          color: AppColors.violet,
                        ),
                        _MiniStat(
                          value: '4.8',
                          label: 'Note',
                          color: AppColors.ratingAmber,
                        ),
                        _MiniStat(
                          value: '156',
                          label: 'Abonnés',
                          color: AppColors.rose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    const values = [0.4, 0.6, 0.3, 0.8, 0.5, 0.9, 0.7];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _entry,
        builder: (_, __) {
          final progress = Curves.easeOutCubic.transform(_entry.value);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final delay = i / 7.0;
              final barProgress =
                  ((progress - delay * 0.3) / 0.7).clamp(0.0, 1.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24,
                    height: 80 * values[i] * barProgress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.violet, AppColors.rose],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i],
                    style: GoogleFonts.dmSans(
                      color: AppColors.grisInactif,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
  }
}

// ─── Mini stat widget ──────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.sora(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
