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
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Auto-shimmer for gradient/primary buttons
    if (widget.variant == SpotbookButtonVariant.gradient ||
        widget.variant == SpotbookButtonVariant.primary) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _shimmerController.repeat(period: const Duration(seconds: 4));
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Border? border;
    final Gradient? gradient;
    final List<BoxShadow> shadows;
    final bool hasShimmer;

    switch (widget.variant) {
      case SpotbookButtonVariant.primary:
        bg = Colors.transparent;
        fg = Colors.white;
        border = null;
        gradient = AppColors.gradientAccent;
        shadows = AppColors.primaryButtonShadow;
        hasShimmer = true;
      case SpotbookButtonVariant.secondary:
        bg = AppColors.surface;
        fg = AppColors.blanc;
        border = Border.all(color: AppColors.border);
        gradient = null;
        shadows = const [];
        hasShimmer = false;
      case SpotbookButtonVariant.outlined:
        bg = Colors.transparent;
        fg = AppColors.blanc;
        border = Border.all(color: AppColors.border);
        gradient = null;
        shadows = const [];
        hasShimmer = false;
      case SpotbookButtonVariant.destructive:
        bg = AppColors.error.withAlpha(20);
        fg = AppColors.error;
        border = Border.all(color: AppColors.error.withAlpha(60));
        gradient = null;
        shadows = const [];
        hasShimmer = false;
      case SpotbookButtonVariant.gradient:
        bg = Colors.transparent;
        fg = Colors.white;
        border = null;
        gradient = AppColors.gradientAccent;
        shadows = AppColors.primaryButtonShadow;
        hasShimmer = true;
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
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          final scale = 1.0 - (_scaleController.value * 0.04);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: widget.width ?? double.infinity,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: border,
            boxShadow: shadows,
          ),
          child: Stack(
            children: [
              // Shimmer sweep for premium buttons
              if (hasShimmer && !widget.isLoading)
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    return Positioned.fill(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          final offset = _shimmerController.value * 3 - 1;
                          return LinearGradient(
                            begin: Alignment(offset, 0),
                            end: Alignment(offset + 1, 0),
                            colors: [
                              Colors.white.withAlpha(0),
                              Colors.white.withAlpha(30),
                              Colors.white.withAlpha(0),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Content
              Center(
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
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
