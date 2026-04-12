import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class LikeAnimation extends StatefulWidget {
  const LikeAnimation({super.key});

  @override
  State<LikeAnimation> createState() => _LikeAnimationState();
}

class _LikeAnimationState extends State<LikeAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _heartController;
  late final AnimationController _particlesController;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;
  late final Animation<double> _particleProgress;

  static final _random = Random();

  // Generate random particle directions
  late final List<_Particle> _particles = List.generate(
    8,
    (_) => _Particle(
      angle: _random.nextDouble() * 2 * pi,
      distance: 60 + _random.nextDouble() * 40,
      size: 6 + _random.nextDouble() * 6,
      color: [AppColors.rose, AppColors.roseClair, Colors.white][
          _random.nextInt(3)],
    ),
  );

  @override
  void initState() {
    super.initState();

    // Heart animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.4)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
    ]).animate(_heartController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartController);

    // Particles animation
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particleProgress = CurvedAnimation(
      parent: _particlesController,
      curve: Curves.easeOut,
    );

    _heartController.forward();
    _particlesController.forward();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ─── Burst particles ───
          AnimatedBuilder(
            animation: _particleProgress,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleProgress.value,
                ),
              );
            },
          ),

          // ─── Main heart with glow ───
          AnimatedBuilder(
            animation: _heartController,
            builder: (context, child) {
              return Opacity(
                opacity: _heartOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _heartScale.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow behind heart
                      Icon(
                        Icons.favorite,
                        color: AppColors.rose.withAlpha(80),
                        size: 120,
                      ),
                      // Main heart
                      Icon(
                        Icons.favorite,
                        color: AppColors.rose,
                        size: 100,
                      ),
                      // White highlight
                      Positioned(
                        top: 36,
                        left: 56,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(140),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
  final double angle;
  final double distance;
  final double size;
  final Color color;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final dx = center.dx + cos(p.angle) * p.distance * progress;
      final dy = center.dy + sin(p.angle) * p.distance * progress;
      final radius = p.size * (1.0 - progress * 0.5);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
