import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';

/// Big 80px heart that appears at tap position with elasticOut animation.
/// If [position] is null, defaults to center of parent.
class DoubleTapHeart extends StatefulWidget {
  const DoubleTapHeart({
    super.key,
    required this.onDismissed,
    this.position,
  });

  final VoidCallback onDismissed;
  final Offset? position;

  @override
  State<DoubleTapHeart> createState() => _DoubleTapHeartState();
}

class _DoubleTapHeartState extends State<DoubleTapHeart>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  late final List<_ParticleAnim> _particles;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // elasticOut for that satisfying bounce
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 35),
    ]).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.elasticOut,
    ));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_mainCtrl);

    // 6 mini particle hearts
    final rng = Random();
    _particles = List.generate(6, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + rng.nextInt(200)),
      );
      final angle = (i / 6) * 2 * pi + rng.nextDouble() * 0.5;
      final distance = 40.0 + rng.nextDouble() * 30;
      return _ParticleAnim(
        controller: ctrl,
        dx: cos(angle) * distance,
        dy: sin(angle) * distance,
        size: 12.0 + rng.nextDouble() * 10,
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
        ),
        offset: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
        ),
      );
    });

    _mainCtrl.forward();
    for (final p in _particles) {
      p.controller.forward();
    }

    _mainCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainCtrl,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Particle hearts
            for (final p in _particles)
              AnimatedBuilder(
                animation: p.controller,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(
                      p.dx * p.offset.value,
                      p.dy * p.offset.value,
                    ),
                    child: Opacity(
                      opacity: p.opacity.value,
                      child: Icon(
                        Icons.favorite,
                        color: AppColors.rose,
                        size: p.size,
                      ),
                    ),
                  );
                },
              ),
            // Main heart — 80px with elasticOut
            Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Icon(
                  Icons.favorite,
                  color: AppColors.rose,
                  size: 80,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ParticleAnim {
  const _ParticleAnim({
    required this.controller,
    required this.dx,
    required this.dy,
    required this.size,
    required this.opacity,
    required this.offset,
  });

  final AnimationController controller;
  final double dx;
  final double dy;
  final double size;
  final Animation<double> opacity;
  final Animation<double> offset;
}
