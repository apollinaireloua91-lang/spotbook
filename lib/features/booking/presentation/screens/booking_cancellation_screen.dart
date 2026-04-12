import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/booking_notifier.dart';

class BookingCancellationScreen extends ConsumerWidget {
  const BookingCancellationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientBookingsProvider);

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
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Cancel booking',
          style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            Text(
              'Cancellation policy',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _PolicyRow(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              text:
                  'More than 48h before appointment: full deposit refund.',
            ),
            const SizedBox(height: 12),
            _PolicyRow(
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              text:
                  'Less than 48h before appointment: the pro retains the deposit. No refund.',
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withAlpha(50)),
              ),
              child: Text(
                'This action is irreversible. Do you confirm the cancellation?',
                style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            if (state.cancellationError != null) ...[
              const SizedBox(height: 12),
              Text(
                state.cancellationError!,
                style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.isCancelling
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        final success = await ref
                            .read(clientBookingsProvider.notifier)
                            .cancelBooking(bookingId);
                        if (success && context.mounted) {
                          context.pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.blanc,
                  disabledBackgroundColor: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isCancelling
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.blanc, strokeWidth: 2),
                      )
                    : Text('Confirm cancellation',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: state.isCancelling ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blanc,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back', style: GoogleFonts.dmSans()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.dmSans(color: AppColors.grisClair, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
