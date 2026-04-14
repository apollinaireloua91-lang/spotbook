import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// TikTok-style double-tap heart animation.
///
/// Appears at tap position, scales up with bounce, bursts particles,
/// then fades out. Calls [onComplete] when done so the parent can
/// remove it from the widget tree.
class LikeAnimation extends StatefulWidget {
  const LikeAnimation({super.key, this.onComplete});

  final VoidCallback? onComplete;

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

  // Slight random rotation for each heart (-15° to +15°)
  late final double _rotation = (_random.nextDouble() - 0.5) * 0.5;

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

    // Heart animation — pop in, hold, fade out
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
    ]).animate(_heartController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
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

    // Notify parent when animation finishes
    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
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

          // ─── Main heart with glow + random rotation ───
          AnimatedBuilder(
            animation: _heartController,
            builder: (context, child) {
              return Opacity(
                opacity: _heartOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _heartScale.value,
                  child: Transform.rotate(
                    angle: _rotation,
                    child: const _HeartIcon(),
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

/// The heart icon with glow + white highlight.
class _HeartIcon extends StatelessWidget {
  const _HeartIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow behind heart
        Icon(
          Icons.favorite,
          color: AppColors.rose.withAlpha(80),
          size: 110,
        ),
        // Main heart
        Icon(
          Icons.favorite,
          color: AppColors.rose,
          size: 90,
        ),
        // White highlight
        Positioned(
          top: 34,
          left: 52,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(150),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
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
