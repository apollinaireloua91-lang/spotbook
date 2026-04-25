import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/profile_models.dart';

/// Hero section — "Members' Passport" editorial composition.
///
/// Aurora radial gradient backdrop, oversized gradient-ringed avatar,
/// confident Sora display of the member name, capped-letter member tag,
/// and an italic editorial bio slot.
class ProfileHero extends StatefulWidget {
  const ProfileHero({super.key, required this.profile});

  final ClientProfile profile;

  @override
  State<ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<ProfileHero>
    with TickerProviderStateMixin {
  late final AnimationController _auroraCtrl;
  late final AnimationController _revealCtrl;

  @override
  void initState() {
    super.initState();
    // Slow aurora drift — subtle backdrop motion, never distracting.
    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    // One-shot stagger for the hero reveal.
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _auroraCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  String? _handle(ClientProfile p) {
    if (p.username != null && p.username!.isNotEmpty) return p.username;
    if (p.email.contains('@')) return p.email.split('@').first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.profile;
    final handle = _handle(p);

    // Staggered reveal curves for each hero block.
    final avatarFade = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    final nameFade = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
    );
    final chipFade = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
    );
    final bioFade = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Aurora backdrop — drifting radial halo behind the avatar.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _auroraCtrl,
                builder: (context, _) {
                  final t = _auroraCtrl.value;
                  final dx = (0.5 + 0.08 * _wobble(t));
                  final dy = (0.25 + 0.04 * _wobble(t + 0.33));
                  return CustomPaint(
                    painter: _AuroraPainter(
                      center: Alignment(
                        (dx - 0.5) * 2,
                        (dy - 0.5) * 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 14),

              // ── Avatar — dual gradient ring + soft glow ──
              FadeTransition(
                opacity: avatarFade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                    CurvedAnimation(
                      parent: avatarFade,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: _AvatarRing(profile: p),
                ),
              ),

              const SizedBox(height: 18),

              // ── Name — oversized Sora display ──
              FadeTransition(
                opacity: nameFade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(nameFade),
                  child: Text(
                    p.fullName.isEmpty ? '—' : p.fullName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      height: 1.05,
                    ),
                  ),
                ),
              ),

              if (handle != null) ...[
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: nameFade,
                  child: Text(
                    '@$handle',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Member tag — capped letter-spaced + hairline gradient ring ──
              FadeTransition(
                opacity: chipFade,
                child: const _MemberTag(),
              ),

              // ── Bio — editorial italic paragraph ──
              FadeTransition(
                opacity: bioFade,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18, left: 12, right: 12),
                  child: (p.bio != null && p.bio!.trim().isNotEmpty)
                      ? _BioQuote(bio: p.bio!.trim())
                      : Text(
                          l.addBioHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: AppColors.grisInactif,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                ),
              ),

              // ── Location line ──
              if (p.city != null && p.city!.isNotEmpty) ...[
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: bioFade,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.place_outlined,
                          color: AppColors.gris, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        p.city!.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  // Smooth [-1, 1] oscillation for aurora drift.
  double _wobble(double t) {
    final x = t % 1.0;
    return (x < 0.5 ? x * 2 : 2 - x * 2) * 2 - 1;
  }
}

// ─── Avatar with gradient halo + soft glow ────────────────────────────────────

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientAccent,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withAlpha(90),
            blurRadius: 36,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.rose.withAlpha(45),
            blurRadius: 48,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.fond,
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: profile.avatarUrl != null
              ? CachedNetworkImage(
                  imageUrl: profile.avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      _InitialsDisc(name: profile.fullName),
                  errorWidget: (_, __, ___) =>
                      _InitialsDisc(name: profile.fullName),
                )
              : _InitialsDisc(name: profile.fullName),
        ),
      ),
    );
  }
}

class _InitialsDisc extends StatelessWidget {
  const _InitialsDisc({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '·';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withAlpha(180),
            AppColors.rose.withAlpha(140),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.sora(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
        ),
      ),
    );
  }
}

// ─── Member tag — hairline gradient outline, capped letter-spaced ──────────────

class _MemberTag extends StatelessWidget {
  const _MemberTag();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Gradient outline via nested containers — 1.2px hairline that reads
    // sharper than Border.all with a gradient color at this size.
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.violet.withAlpha(200),
            AppColors.rose.withAlpha(160),
          ],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.violetClair,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violetClair.withAlpha(160),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l.memberBadge.toUpperCase(),
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bio — editorial pull-quote treatment ─────────────────────────────────────

class _BioQuote extends StatelessWidget {
  const _BioQuote({required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left ornamental accent
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 10),
          child: Container(
            width: 2,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.gradientAccentVertical,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Flexible(
          child: Text(
            bio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: AppColors.blanc.withAlpha(210),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
              letterSpacing: 0.05,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Aurora backdrop painter ──────────────────────────────────────────────────

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.center});

  final Alignment center;

  @override
  void paint(Canvas canvas, Size size) {
    // Two stacked radial glows (violet over rose) with gentle blur.
    final rect = Offset.zero & size;
    final c = center.alongSize(size);

    // Violet halo — brighter, tighter
    final violetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.violet.withAlpha(80),
          AppColors.violet.withAlpha(24),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.55))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawRect(rect, violetPaint);

    // Rose halo — wider, softer
    final rosePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.rose.withAlpha(40),
          AppColors.rose.withAlpha(12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: c.translate(size.width * 0.15, size.height * 0.1),
          radius: size.width * 0.7,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawRect(rect, rosePaint);

    // Subtle grain — very light noise to add texture.
    _drawGrain(canvas, size);
  }

  void _drawGrain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(4)
      ..style = PaintingStyle.fill;
    // Deterministic pseudo-noise: sparse dots, low alpha.
    // Only draw a few dozen — this is decorative, not perf-critical.
    for (int i = 0; i < 40; i++) {
      final x = (i * 97) % size.width.toInt();
      final y = (i * 53) % size.height.toInt();
      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.center != center;
}

