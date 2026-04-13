import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/moderation_repository.dart';
import '../../data/report_notifier.dart';

void showReportSheet(
  BuildContext context, {
  required String targetId,
  required String targetType,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(targetId: targetId, targetType: targetType),
  );
}

void showBlockConfirmDialog(
  BuildContext context, {
  required WidgetRef ref,
  required String userId,
  String? userName,
}) {
  final l = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l.blockUserConfirmTitle,
          style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 17, fontWeight: FontWeight.bold)),
      content: Text(
        l.blockUserConfirmMessage(userName ?? l.blockUserDefault),
        style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.cancel, style: GoogleFonts.dmSans(color: AppColors.gris)),
        ),
        TextButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await ref.read(moderationRepositoryProvider).blockUser(userId);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.blockUserBlocked),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          child: Text(l.block,
              style: GoogleFonts.dmSans(color: AppColors.error, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

class _ReportSheet extends ConsumerWidget {
  const _ReportSheet({required this.targetId, required this.targetType});
  final String targetId;
  final String targetType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final reasons = [
      l.reportReasonInappropriate,
      l.reportReasonSpam,
      l.reportReasonHarassment,
      l.reportReasonFakeProfile,
      l.reportReasonOther,
    ];
    final reportState = ref.watch(reportNotifierProvider).asData?.value ?? const ReportState();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          Text(l.report,
              style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(l.reportWhyReporting,
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14)),
          const SizedBox(height: 16),
          ...List.generate(reasons.length, (i) {
            final reason = reasons[i];
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: reportState.selectedReason == null || reportState.isSubmitting
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      try {
                        await ref.read(reportNotifierProvider.notifier).submitReport(
                              targetId: targetId,
                              targetType: targetType,
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l.reportSent),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.blanc,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(l.reportSubmitButton,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
