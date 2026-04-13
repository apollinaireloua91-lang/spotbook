import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SpotbookCard extends StatelessWidget {
  const SpotbookCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
    this.highlightBorderColor,
  }) : _useGlass = false;

  /// Glassmorphism variant — frosted blur background, premium shadows.
  const SpotbookCard.glass({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
  })  : highlightBorderColor = null,
        _useGlass = true;

  /// Highlighted variant with optional selection state.
  const SpotbookCard.highlight({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
  })  : highlightBorderColor = null,
        _useGlass = false;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? highlightBorderColor;
  final bool _useGlass;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? (highlightBorderColor ?? AppColors.violet)
        : AppColors.border;

    if (_useGlass) {
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.violet.withAlpha(80)
                      : AppColors.glassBorder,
                  width: selected ? 1.5 : 0.5,
                ),
                boxShadow: AppColors.glassShadow,
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.5 : 0.5,
          ),
          boxShadow: AppColors.premiumCardShadow,
        ),
        child: child,
      ),
    );
  }
}
