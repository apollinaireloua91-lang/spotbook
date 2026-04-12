import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Wrapper that applies an interactive 3D tilt effect on touch.
///
/// The card tilts toward the touch point with a perspective transform,
/// giving a subtle parallax / depth feel.
class Card3DTilt extends StatefulWidget {
  const Card3DTilt({
    super.key,
    required this.child,
    this.maxAngle = 6.0,
    this.scaleFactor = 1.02,
  });

  final Widget child;

  /// Maximum tilt angle in degrees.
  final double maxAngle;

  /// Scale factor on touch (slight zoom-in).
  final double scaleFactor;

  @override
  State<Card3DTilt> createState() => _Card3DTiltState();
}

class _Card3DTiltState extends State<Card3DTilt> {
  double _rotateX = 0;
  double _rotateY = 0;
  double _scale = 1.0;

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final pos = details.localPosition;

    // Normalise touch position to -1..1
    final dx = (pos.dx / size.width - 0.5) * 2;
    final dy = (pos.dy / size.height - 0.5) * 2;

    setState(() {
      _rotateY = dx * widget.maxAngle * (3.14159 / 180);
      _rotateX = -dy * widget.maxAngle * (3.14159 / 180);
      _scale = widget.scaleFactor;
    });
  }

  void _onPanEnd(DragEndDetails _) => _reset();
  void _onPanCancel() => _reset();

  void _reset() {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(_rotateX)
          ..rotateY(_rotateY)
          ..scaleByVector3(Vector3(_scale, _scale, 1.0)),
        child: widget.child,
      ),
    );
  }
}
