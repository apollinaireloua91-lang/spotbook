import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/spotbook_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card3DTilt — effet 3D tilt au touch sur n'importe quel widget enfant.
// ─────────────────────────────────────────────────────────────────────────────

/// Ajoute un effet 3D tilt interactif au touch.
///
/// Le widget enfant pivote en X/Y en suivant la position du doigt,
/// puis revient élastiquement au repos quand le doigt est levé.
///
/// ```dart
/// Card3DTilt(
///   child: SpotbookCard(child: Text('Hello')),
/// )
/// ```
class Card3DTilt extends StatefulWidget {
  const Card3DTilt({
    super.key,
    required this.child,
    this.maxAngle = 8.0,
  });

  final Widget child;

  /// Angle maximum de rotation en degrés.
  final double maxAngle;

  @override
  State<Card3DTilt> createState() => _Card3DTiltState();
}

class _Card3DTiltState extends State<Card3DTilt>
    with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  Offset _startTilt = Offset.zero;
  late final AnimationController _returnController;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        final t = Curves.easeOutBack.transform(_returnController.value);
        setState(() {
          _tilt = Offset.lerp(_startTilt, Offset.zero, t)!;
        });
      });
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _returnController.stop();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final pos = details.localPosition;
    setState(() {
      _tilt = Offset(
        ((pos.dx / size.width) - 0.5) * 2,
        -((pos.dy / size.height) - 0.5) * 2,
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    _startTilt = _tilt;
    _returnController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final maxRad = widget.maxAngle * math.pi / 180;
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tilt.dy * maxRad)
          ..rotateY(_tilt.dx * maxRad),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ParallaxScrollEffect — parallax basé sur la position dans le viewport.
// ─────────────────────────────────────────────────────────────────────────────

/// Ajoute un décalage parallax à un widget dans un Scrollable.
///
/// Les items proches du centre du viewport bougent moins ;
/// ceux en bord bougent plus — créant un effet de profondeur.
///
/// ```dart
/// ListView.builder(
///   itemBuilder: (_, i) => ParallaxScrollEffect(
///     child: MyCard(),
///   ),
/// )
/// ```
class ParallaxScrollEffect extends StatelessWidget {
  const ParallaxScrollEffect({
    super.key,
    required this.child,
    this.factor = 0.3,
  });

  final Widget child;

  /// Intensité du parallax (0 = aucun, 1 = fort).
  final double factor;

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return child;

    return AnimatedBuilder(
      animation: scrollable.position,
      builder: (context, child) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) return child!;

        final screenHeight = MediaQuery.sizeOf(context).height;
        final posInViewport = box.localToGlobal(Offset.zero).dy;
        final normalized = (posInViewport / screenHeight - 0.5) * 2;
        final offset = normalized * 20 * factor;

        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlowPulse — animation glow / pulse sur les CTA importants.
// ─────────────────────────────────────────────────────────────────────────────

/// Ajoute un halo pulsant autour du widget enfant.
///
/// ```dart
/// GlowPulse(
///   child: ElevatedButton(onPressed: () {}, child: Text('Réserver')),
/// )
/// ```
class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.child,
    this.glowColor,
    this.borderRadius = 12.0,
  });

  final Widget child;
  final Color? glowColor;
  final double borderRadius;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.glowColor ?? SpotbookColors.violet;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = Curves.easeInOut.transform(_controller.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha((40 + glow * 65).round()),
                blurRadius: 12 + glow * 12,
                spreadRadius: glow * 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FlipCard3D — animation flip 3D pour les billets / QR codes.
// ─────────────────────────────────────────────────────────────────────────────

/// Flip 3D entre une face avant et une face arrière.
///
/// ```dart
/// final flipKey = GlobalKey<FlipCard3DState>();
///
/// FlipCard3D(
///   key: flipKey,
///   front: TicketFront(),
///   back: QRCodeWidget(),
/// )
///
/// // Déclencher le flip :
/// flipKey.currentState?.flip();
/// ```
class FlipCard3D extends StatefulWidget {
  const FlipCard3D({
    super.key,
    required this.front,
    required this.back,
  });

  final Widget front;
  final Widget back;

  @override
  State<FlipCard3D> createState() => FlipCard3DState();
}

class FlipCard3DState extends State<FlipCard3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        final pastHalf = _controller.value >= 0.5;
        if (pastHalf != !_showFront) {
          setState(() => _showFront = !pastHalf);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Déclenche le flip 3D.
  void flip() {
    if (_controller.isAnimating) return;
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: _showFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FloatingParticles — particules violettes flottantes subtiles.
// ─────────────────────────────────────────────────────────────────────────────

/// Overlay de particules violettes semi-transparentes qui flottent lentement.
///
/// ```dart
/// Stack(
///   children: [
///     FeedContent(),
///     const Positioned.fill(child: FloatingParticles()),
///   ],
/// )
/// ```
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({
    super.key,
    this.particleCount = 15,
  });

  final int particleCount;

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = List.generate(widget.particleCount, (_) => _Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle()
      : x = _rng.nextDouble(),
        y = _rng.nextDouble(),
        radius = 2 + _rng.nextDouble() * 3,
        dx = (_rng.nextDouble() - 0.5) * 0.3,
        dy = (_rng.nextDouble() - 0.5) * 0.2,
        phase = _rng.nextDouble() * math.pi * 2,
        paint = Paint()
          ..color = SpotbookColors.violet
              .withAlpha((12 + _rng.nextInt(14))) // 0.05–0.10 opacity
          ..style = PaintingStyle.fill;

  static final _rng = math.Random();
  final double x, y, radius, dx, dy, phase;
  final Paint paint;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    for (final p in particles) {
      final px = (p.x + math.sin(t + p.phase) * p.dx * 0.5) * size.width;
      final py = (p.y + math.cos(t + p.phase * 0.7) * p.dy * 0.5) * size.height;
      canvas.drawCircle(Offset(px, py), p.radius, p.paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
