import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;

  static List<Color> get _colors => [
    AppColors.violet,
    AppColors.rose,
    AppColors.violetClair,
    AppColors.roseClair,
    AppColors.success,
    AppColors.warning,
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(40, (_) {
      return _ConfettiParticle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.3,
        speed: 0.4 + rng.nextDouble() * 0.6,
        drift: (rng.nextDouble() - 0.5) * 0.3,
        rotation: rng.nextDouble() * pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 6,
        size: 6 + rng.nextDouble() * 6,
        color: _colors[rng.nextInt(_colors.length)],
        isCircle: rng.nextBool(),
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            size: MediaQuery.sizeOf(context),
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.isCircle,
  });

  final double x;
  final double delay;
  final double speed;
  final double drift;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress - p.delay).clamp(0.0, 1.0) / (1.0 - p.delay);
      if (t <= 0) continue;

      final opacity = t < 0.8 ? 1.0 : (1.0 - t) / 0.2;
      final paint = Paint()..color = p.color.withAlpha((opacity * 255).toInt());

      final x = (p.x + p.drift * t) * size.width;
      final y = t * p.speed * size.height;
      final angle = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
