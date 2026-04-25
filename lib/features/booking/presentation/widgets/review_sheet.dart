import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/confetti_overlay.dart';

/// Bottom sheet for leaving a review with star rating and comment.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({
    super.key,
    required this.bookingId,
    required this.proId,
    this.serviceName,
    required this.onSubmit,
  });

  final String bookingId;
  final String proId;
  final String? serviceName;
  final Future<bool> Function(int rating, String comment) onSubmit;

  /// Shows the review sheet as a modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required String proId,
    String? serviceName,
    required Future<bool> Function(int rating, String comment) onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(
        bookingId: bookingId,
        proId: proId,
        serviceName: serviceName,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _showConfetti = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _isSubmitting = true);

    final success = await widget.onSubmit(
      _rating,
      _commentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      HapticFeedback.heavyImpact();
      setState(() => _showConfetti = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.pop(true);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 60),
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          // SingleChildScrollView : le TextField (maxLines: 4) peut faire
          // déborder quand le clavier s'ouvre. Le scroll absorbe l'overflow.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                l.leaveReview,
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.serviceName != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.serviceName!,
                  style: TextStyle(
                    color: AppColors.gris,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = starIndex <= _rating;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _rating = starIndex);
                    },
                    child: _AnimatedStar(
                      isSelected: isSelected,
                      delay: Duration(milliseconds: index * 60),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Comment field
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: l.shareYourExperience,
                  hintStyle: TextStyle(
                    color: AppColors.gris.withAlpha(150),
                  ),
                  filled: true,
                  fillColor: AppColors.fond,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.violet,
                      width: 1.5,
                    ),
                  ),
                  counterStyle: TextStyle(color: AppColors.gris),
                ),
              ),

              const SizedBox(height: 20),

              // Submit button
              GestureDetector(
                onTap: _rating > 0 && !_isSubmitting ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _rating > 0
                        ? AppColors.violet
                        : AppColors.violet.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.blanc,
                            ),
                          )
                        : Text(
                            l.publishReview,
                            style: TextStyle(
                              color: AppColors.blanc,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),

        // Confetti overlay
        if (_showConfetti)
          Positioned.fill(
            child: ConfettiOverlay(
              onComplete: () {
                if (mounted) setState(() => _showConfetti = false);
              },
            ),
          ),
      ],
    );
  }
}

// ─── Animated star with staggered scale + color ──────────────────────────────

class _AnimatedStar extends StatefulWidget {
  const _AnimatedStar({
    required this.isSelected,
    this.delay = Duration.zero,
  });

  final bool isSelected;
  final Duration delay;

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _AnimatedStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            widget.isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 40,
            color: widget.isSelected
                ? AppColors.starGold
                : AppColors.gris.withAlpha(100),
          ),
        ),
      ),
    );
  }
}
