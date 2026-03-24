import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SpotbookCardVariant { standard, glass, highlight }

class SpotbookCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final content = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: _decoration,
        child: child,
      ),
    );

    if (variant == SpotbookCardVariant.glass) {
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
    switch (variant) {
      case SpotbookCardVariant.standard:
        return BoxDecoration(
          color: const Color(0xFF0D0D0D),
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
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.blanc : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.blanc.withValues(alpha: 0.06),
                    blurRadius: 12,
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
