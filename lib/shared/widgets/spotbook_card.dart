import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum SpotbookCardVariant { standard, glass, highlight }

class SpotbookCard extends StatefulWidget {
  const SpotbookCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.variant = SpotbookCardVariant.standard,
    this.selected = false,
  });

  const SpotbookCard.glass({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
  }) : variant = SpotbookCardVariant.glass;

  const SpotbookCard.highlight({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    required this.selected,
  }) : variant = SpotbookCardVariant.highlight;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final SpotbookCardVariant variant;
  final bool selected;

  @override
  State<SpotbookCard> createState() => _SpotbookCardState();
}

class _SpotbookCardState extends State<SpotbookCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _scaleCtrl.reverse();
  }

  void _onTapUp(TapUpDetails _) => _scaleCtrl.forward();
  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap != null
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: _decoration,
          child: widget.child,
        ),
      ),
    );

    if (widget.variant == SpotbookCardVariant.glass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: content,
        ),
      );
    }

    return content;
  }

  BoxDecoration get _decoration {
    switch (widget.variant) {
      case SpotbookCardVariant.standard:
        return BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        );
      case SpotbookCardVariant.glass:
        return BoxDecoration(
          color: AppColors.blanc.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.blanc.withValues(alpha: 0.12),
            width: 0.5,
          ),
        );
      case SpotbookCardVariant.highlight:
        return BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.selected ? AppColors.violet : AppColors.border,
            width: widget.selected ? 1.5 : 0.5,
          ),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        );
    }
  }
}
