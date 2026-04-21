import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
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
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
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
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withAlpha(30),
                        AppColors.success.withAlpha(10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withAlpha(40),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                ),
                const SizedBox(height: 24),
                Text(l.reviewThankYou,
                    style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l.reviewFeedbackHelps,
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15, height: 1.4), textAlign: TextAlign.center),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.primaryButtonShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l.reviewDone, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
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
          label: l.retourLabel,
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
        title: Text(l.reviewLeaveReview,
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
            Text(l.reviewHowWasAppointment,
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
                      child: Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warning.withAlpha(60),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              )
                            : null,
                        child: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isSelected ? AppColors.warning : AppColors.gris,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(state.rating),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: state.rating > 0
                      ? AppColors.warning.withAlpha(20)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: state.rating > 0
                        ? AppColors.warning.withAlpha(60)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  _ratingLabel(state.rating),
                  style: GoogleFonts.dmSans(
                    color: state.rating > 0 ? AppColors.warning : AppColors.gris,
                    fontSize: 14,
                    fontWeight: state.rating > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
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
                        hintText: l.reviewShareExperience,
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: state.rating > 0 && !state.isSubmitting
                      ? AppColors.gradientAccent
                      : null,
                  color: state.rating == 0 || state.isSubmitting
                      ? AppColors.surfaceAlt
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: state.rating > 0 && !state.isSubmitting
                      ? AppColors.primaryButtonShadow
                      : null,
                ),
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
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(l.reviewSubmit, style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: state.rating > 0 ? Colors.white : AppColors.gris,
                        )),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    final l = AppLocalizations.of(context)!;
    switch (rating) {
      case 1:
        return l.reviewRating1;
      case 2:
        return l.reviewRating2;
      case 3:
        return l.reviewRating3;
      case 4:
        return l.reviewRating4;
      case 5:
        return l.reviewRating5;
      default:
        return l.reviewTapToRate;
    }
  }
}
