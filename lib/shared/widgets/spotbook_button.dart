import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum SpotbookButtonVariant { primary, secondary, outlined, ghost, destructive }

class SpotbookButton extends StatefulWidget {
  const SpotbookButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SpotbookButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  const SpotbookButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SpotbookButtonVariant.primary;

  const SpotbookButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SpotbookButtonVariant.secondary;

  const SpotbookButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SpotbookButtonVariant.outlined;

  const SpotbookButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SpotbookButtonVariant.ghost;

  const SpotbookButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SpotbookButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final SpotbookButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  @override
  State<SpotbookButton> createState() => _SpotbookButtonState();
}

class _SpotbookButtonState extends State<SpotbookButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse();
  void _onTapUp(TapUpDetails _) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Border? border;

    switch (widget.variant) {
      case SpotbookButtonVariant.primary:
        bg = AppColors.blanc;
        fg = AppColors.fond;
        border = null;
      case SpotbookButtonVariant.secondary:
        bg = AppColors.surfaceAlt;
        fg = AppColors.blanc;
        border = Border.all(color: AppColors.border);
      case SpotbookButtonVariant.outlined:
        bg = Colors.transparent;
        fg = AppColors.blanc;
        border = Border.all(color: AppColors.blanc);
      case SpotbookButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.blanc;
        border = null;
      case SpotbookButtonVariant.destructive:
        bg = AppColors.error.withValues(alpha: 0.1);
        fg = AppColors.error;
        border = null;
    }

    final bool isPill = widget.variant == SpotbookButtonVariant.primary;
    final double radius = isPill ? 28 : 12;
    final double height = isPill ? 56 : 48;

    return GestureDetector(
      onTapDown: widget.isLoading ? null : _onTapDown,
      onTapUp: widget.isLoading ? null : _onTapUp,
      onTapCancel: widget.isLoading ? null : _onTapCancel,
      onTap: widget.isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: border,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: fg, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: isPill ? 0.2 : 0,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
