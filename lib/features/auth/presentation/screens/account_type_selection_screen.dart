import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';

class _RoleNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String role) => state = role;
}

final _selectedRoleProvider =
    NotifierProvider<_RoleNotifier, String?>(_RoleNotifier.new);

class AccountTypeSelectionScreen extends ConsumerStatefulWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  ConsumerState<AccountTypeSelectionScreen> createState() =>
      _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState
    extends ConsumerState<AccountTypeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _auroraCtrl;
  late final AnimationController _revealCtrl;

  late final Animation<double> _eyebrowAnim;
  late final Animation<double> _titleAnim;
  late final Animation<double> _subtitleAnim;
  late final Animation<double> _clientAnim;
  late final Animation<double> _proAnim;
  late final Animation<double> _ctaAnim;

  @override
  void initState() {
    super.initState();
    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    Animation<double> band(double start, double end) => CurvedAnimation(
          parent: _revealCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

    _eyebrowAnim = band(0.0, 0.45);
    _titleAnim = band(0.1, 0.55);
    _subtitleAnim = band(0.2, 0.65);
    _clientAnim = band(0.3, 0.8);
    _proAnim = band(0.4, 0.9);
    _ctaAnim = band(0.55, 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCtrl.forward());
  }

  @override
  void dispose() {
    _auroraCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selectedRole = ref.watch(_selectedRoleProvider);

    void confirm() {
      if (selectedRole == null) return;
      HapticFeedback.mediumImpact();
      context.go('/signup/$selectedRole');
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient aurora backdrop
          AnimatedBuilder(
            animation: _auroraCtrl,
            builder: (_, __) => CustomPaint(
              painter: _AuroraPainter(progress: _auroraCtrl.value),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Eyebrow — caps label with dot + gradient bar
                  _RevealFade(
                    animation: _eyebrowAnim,
                    child: const _Eyebrow(),
                  ),

                  const SizedBox(height: 28),

                  _RevealSlide(
                    animation: _titleAnim,
                    child: Text(
                      l.authWelcomeTitle,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        height: 1.05,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _RevealSlide(
                    animation: _subtitleAnim,
                    child: Text(
                      l.authSelectAccountType,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  _RevealSlide(
                    animation: _clientAnim,
                    child: _RoleCard(
                      icon: Icons.explore_outlined,
                      tag: 'CLIENT',
                      title: l.authRoleClient,
                      subtitle: l.authRoleClientSubtitle,
                      description: l.authRoleClientDescription,
                      isSelected: selectedRole == 'client',
                      accent: AppColors.violet,
                      accentLight: AppColors.violetClair,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(_selectedRoleProvider.notifier)
                            .select('client');
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  _RevealSlide(
                    animation: _proAnim,
                    child: _RoleCard(
                      icon: Icons.workspace_premium_outlined,
                      tag: 'PROFESSIONAL',
                      title: l.authRolePro,
                      subtitle: l.authRoleProSubtitle,
                      description: l.authRoleProDescription,
                      isSelected: selectedRole == 'pro',
                      accent: AppColors.rose,
                      accentLight: AppColors.roseClair,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(_selectedRoleProvider.notifier).select('pro');
                      },
                    ),
                  ),

                  const Spacer(),

                  _RevealSlide(
                    animation: _ctaAnim,
                    child: _ContinueCta(
                      enabled: selectedRole != null,
                      label: l.buttonContinue,
                      onPressed: confirm,
                    ),
                  ),
                  const SizedBox(height: 18),

                  _RevealFade(
                    animation: _ctaAnim,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        behavior: HitTestBehavior.opaque,
                        child: RichText(
                          text: TextSpan(
                            text: l.authAlreadyHaveAccount,
                            style: GoogleFonts.dmSans(
                              color: AppColors.gris,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: l.login,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.violetClair,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reveal helpers ─────────────────────────────────────────────────────────

class _RevealFade extends StatelessWidget {
  const _RevealFade({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(opacity: animation.value, child: child),
    );
  }
}

class _RevealSlide extends StatelessWidget {
  const _RevealSlide({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, c) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 16),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

// ─── Eyebrow ────────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 2,
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'SPOTBOOK — ENROLLMENT',
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.6,
          ),
        ),
      ],
    );
  }
}

// ─── Role card ──────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isSelected,
    required this.accent,
    required this.accentLight,
    required this.onTap,
  });

  final IconData icon;
  final String tag;
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final Color accent;
  final Color accentLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        // Outer wrapper = gradient outline when selected
        padding: EdgeInsets.all(isSelected ? 1.2 : 0.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isSelected
              ? LinearGradient(
                  colors: [accent, accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.blanc.withAlpha(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withAlpha(70),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            color: AppColors.surfaceAlt.withAlpha(isSelected ? 240 : 180),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                icon: icon,
                accent: accent,
                accentLight: accentLight,
                isSelected: isSelected,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caps role tag — the editorial signature
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? accentLight : AppColors.gris,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tag,
                          style: GoogleFonts.dmSans(
                            color: isSelected
                                ? accentLight
                                : AppColors.grisInactif,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        color: AppColors.grisClair,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris.withAlpha(170),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Discreet selection indicator — hairline circle w/ dot
              _SelectionDot(isSelected: isSelected, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.accent,
    required this.accentLight,
    required this.isSelected,
  });

  final IconData icon;
  final Color accent;
  final Color accentLight;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isSelected
              ? [accent, accentLight]
              : [
                  AppColors.blanc.withAlpha(22),
                  AppColors.blanc.withAlpha(10),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSelected
              ? accentLight.withAlpha(120)
              : AppColors.blanc.withAlpha(30),
          width: 0.6,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withAlpha(100),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: isSelected ? AppColors.blanc : AppColors.grisClair,
        size: 24,
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.isSelected, required this.accent});
  final bool isSelected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accent : AppColors.blanc.withAlpha(40),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        scale: isSelected ? 1 : 0,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent,
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(160),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Continue CTA ───────────────────────────────────────────────────────────

class _ContinueCta extends StatelessWidget {
  const _ContinueCta({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: enabled
            ? AppColors.gradientAccent
            : LinearGradient(colors: [
                AppColors.blanc.withAlpha(20),
                AppColors.blanc.withAlpha(10),
              ]),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.violet.withAlpha(120),
                  blurRadius: 32,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: enabled
                        ? AppColors.blanc
                        : AppColors.blanc.withAlpha(110),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: enabled
                      ? AppColors.blanc
                      : AppColors.blanc.withAlpha(110),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Aurora backdrop ────────────────────────────────────────────────────────

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Base black wash already handled by scaffold bg.
    final t = progress * 2 * math.pi;

    // Violet halo — upper-left drift
    final violetCenter = Offset(
      size.width * (0.18 + 0.08 * math.sin(t)),
      size.height * (0.12 + 0.05 * math.cos(t)),
    );
    final violetPaint = Paint()
      ..color = AppColors.violet.withAlpha(85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(violetCenter, size.width * 0.55, violetPaint);

    // Rose halo — lower-right drift, counter phase
    final roseCenter = Offset(
      size.width * (0.85 + 0.07 * math.sin(t + math.pi)),
      size.height * (0.82 + 0.04 * math.cos(t + math.pi)),
    );
    final rosePaint = Paint()
      ..color = AppColors.rose.withAlpha(55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140);
    canvas.drawCircle(roseCenter, size.width * 0.5, rosePaint);

    // Violet-clair accent — mid right
    final accentCenter = Offset(
      size.width * (0.9 + 0.04 * math.cos(t * 0.7)),
      size.height * (0.38 + 0.06 * math.sin(t * 0.7)),
    );
    final accentPaint = Paint()
      ..color = AppColors.violetClair.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(accentCenter, size.width * 0.35, accentPaint);

    // Subtle film grain — sparse dots
    final grainPaint = Paint()..color = AppColors.blanc.withAlpha(6);
    final rand = math.Random(7);
    for (var i = 0; i < 120; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.5, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

