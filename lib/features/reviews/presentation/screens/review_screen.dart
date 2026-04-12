import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../data/review_repository.dart';

class _ReviewState {
  const _ReviewState({this.rating = 0, this.isSubmitting = false, this.submitted = false});
  final int rating;
  final bool isSubmitting;
  final bool submitted;

  _ReviewState copyWith({int? rating, bool? isSubmitting, bool? submitted}) =>
      _ReviewState(
        rating: rating ?? this.rating,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submitted: submitted ?? this.submitted,
      );
}

class _ReviewNotifier extends Notifier<_ReviewState> {
  @override
  _ReviewState build() => const _ReviewState();

  void setRating(int r) => state = state.copyWith(rating: r);

  Future<void> submit({
    required String bookingId,
    required String proId,
    String? comment,
  }) async {
    if (state.rating == 0) return;
    state = state.copyWith(isSubmitting: true);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.createReview(
        bookingId: bookingId,
        proId: proId,
        rating: state.rating,
        comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
      );
      await AnalyticsService.instance.capture('review_submitted', properties: {
        'booking_id': bookingId,
        'pro_id': proId,
        'rating': state.rating,
      });
      state = state.copyWith(isSubmitting: false, submitted: true);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final _reviewProvider = NotifierProvider<_ReviewNotifier, _ReviewState>(
  _ReviewNotifier.new,
  isAutoDispose: true,
);

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.bookingId, required this.proId, this.serviceName});
  final String bookingId;
  final String proId;
  final String? serviceName;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_reviewProvider);

    if (state.submitted) {
      return Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 64),
                const SizedBox(height: 20),
                Text('Thank you for your review!',
                    style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Your feedback helps other users.',
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blanc,
                      foregroundColor: AppColors.fond,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text('Leave a review',
            style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 32),
            if (widget.serviceName != null) ...[
              Text(widget.serviceName!,
                  style: TextStyle(color: AppColors.gris, fontSize: 15)),
              const SizedBox(height: 8),
            ],
            Text('How was your appointment?',
                style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= state.rating;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(_reviewProvider.notifier).setRating(starIndex);
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.0 : 0.85,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isSelected ? AppColors.blanc : AppColors.gris,
                        size: 48,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabel(state.rating),
              style: TextStyle(color: AppColors.gris, fontSize: 14),
            ),
            const SizedBox(height: 32),
            // Comment
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _commentCtrl,
              builder: (context, value, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _commentCtrl,
                      maxLines: 4,
                      maxLength: 300,
                      style: TextStyle(color: AppColors.blanc, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Share your experience (optional)',
                        hintStyle: TextStyle(color: AppColors.gris),
                        filled: true,
                        fillColor: AppColors.surface,
                        counterStyle: TextStyle(color: AppColors.gris),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.rating == 0 || state.isSubmitting
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        try {
                          await ref.read(_reviewProvider.notifier).submit(
                                bookingId: widget.bookingId,
                                proId: widget.proId,
                                comment: _commentCtrl.text,
                              );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blanc,
                  foregroundColor: AppColors.fond,
                  disabledBackgroundColor: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isSubmitting
                    ? Shimmer.fromColors(
                        baseColor: AppColors.surface,
                        highlightColor: AppColors.surfaceAlt,
                        child: Container(
                          width: 64,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      )
                    : Text('Submit', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Disappointing';
      case 2:
        return 'Average';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}
