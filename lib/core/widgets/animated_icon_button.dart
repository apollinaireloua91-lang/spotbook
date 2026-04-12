import 'package:flutter/material.dart';

import '../theme/spotbook_colors.dart';

/// Bouton icône avec animation scale au tap.
///
/// ```dart
/// AnimatedIconButton(
///   icon: Icons.favorite,
///   size: 28,
///   onTap: () => toggleLike(),
///   badge: hasNotification,
/// )
/// ```
class AnimatedIconButton extends StatefulWidget {
  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.onTap,
    this.badge = false,
    this.badgeColor,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  /// Affiche un point de notification.
  final bool badge;
  final Color? badgeColor;

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.size,
                color: widget.color ?? SpotbookColors.white,
              ),
              if (widget.badge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.badgeColor ?? SpotbookColors.rose,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
