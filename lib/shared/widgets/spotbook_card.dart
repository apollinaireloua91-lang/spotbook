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
  });

  /// Highlighted variant with optional selection state.
  const SpotbookCard.highlight({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
  }) : highlightBorderColor = null;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? highlightBorderColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? (highlightBorderColor ?? AppColors.violet)
        : AppColors.border;

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
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
