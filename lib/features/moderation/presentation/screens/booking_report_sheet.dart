import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/report_notifier.dart';

/// [targetType] = `booking`, [targetId] = UUID du RDV.
void showBookingReportSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String bookingId,
}) {
  ref.read(reportNotifierProvider.notifier).reset();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingReportSheet(bookingId: bookingId),
  );
}

class _BookingReportSheet extends ConsumerStatefulWidget {
  const _BookingReportSheet({required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<_BookingReportSheet> createState() => _BookingReportSheetState();
}

class _BookingReportSheetState extends ConsumerState<_BookingReportSheet> {
  static const _reasons = [
    'Inappropriate behavior',
    'No-show / absence',
    'Payment or refund issue',
    'Service did not match listing',
    'Harassment or threats',
    'Other',
  ];

  final _detailsCtrl = TextEditingController();

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportNotifierProvider).asData?.value ?? const ReportState();
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gris,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Report this booking',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Why are you reporting this booking? Details help the moderation team.',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 16),
              ...List.generate(_reasons.length, (i) {
                final reason = _reasons[i];
                final isSelected = reportState.selectedReason == reason;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(reportNotifierProvider.notifier).selectReason(reason);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceAlt : AppColors.fond,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.blanc : AppColors.border,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: GoogleFonts.dmSans(
                        color: isSelected ? AppColors.blanc : AppColors.gris,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Details (optional, max 500 characters)',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsCtrl,
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(color: AppColors.blanc, fontSize: 15),
                cursorColor: AppColors.blanc,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.fond,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.blanc, width: 1),
                  ),
                  hintText: 'Context, dates, exchanges…',
                  hintStyle: TextStyle(color: AppColors.gris.withValues(alpha: 0.7)),
                  counterStyle: const TextStyle(color: AppColors.gris),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: reportState.selectedReason == null || reportState.isSubmitting
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          final details = _detailsCtrl.text.trim();
                          try {
                            await ref.read(reportNotifierProvider.notifier).submitReport(
                                  targetId: widget.bookingId,
                                  targetType: 'booking',
                                  details: details.isEmpty ? null : details,
                                );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Report submitted. Thank you, review within 24h.',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.blanc,
                    disabledBackgroundColor: AppColors.surfaceAlt,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: reportState.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.blanc,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit report',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
