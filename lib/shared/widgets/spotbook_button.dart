import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum SpotbookButtonVariant { primary, secondary, outlined, destructive, gradient }

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

  const SpotbookButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SpotbookButtonVariant.destructive;

  const SpotbookButton.gradient({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = SpotbookButtonVariant.gradient;

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
      lowerBound: 0.95,
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
    final Gradient? gradient;
    final List<BoxShadow> shadows;

    switch (widget.variant) {
      case SpotbookButtonVariant.primary:
        bg = Colors.transparent;
        fg = Colors.white;
        border = null;
        gradient = AppColors.gradientAccent;
        shadows = [
          BoxShadow(
            color: AppColors.violet.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
      case SpotbookButtonVariant.secondary:
        bg = AppColors.surface;
        fg = AppColors.blanc;
        border = Border.all(color: AppColors.border);
        gradient = null;
        shadows = const [];
      case SpotbookButtonVariant.outlined:
        bg = Colors.transparent;
        fg = AppColors.blanc;
        border = Border.all(color: AppColors.border);
        gradient = null;
        shadows = const [];
      case SpotbookButtonVariant.destructive:
        bg = AppColors.error.withAlpha(20);
        fg = AppColors.error;
        border = Border.all(color: AppColors.error.withAlpha(60));
        gradient = null;
        shadows = const [];
      case SpotbookButtonVariant.gradient:
        bg = Colors.transparent;
        fg = Colors.white;
        border = null;
        gradient = AppColors.gradientAccent;
        shadows = [
          BoxShadow(
            color: AppColors.violet.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onPressed?.call();
            },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width ?? double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: border,
            boxShadow: shadows,
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
                        style: GoogleFonts.dmSans(
                          color: fg,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
