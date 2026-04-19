import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../data/booking_notifier.dart';

/// Step 3 — Time slot picker. Lists available slots for the selected date.
/// Highlights slots that fit the total cart duration (multi-service).
class Step3Time extends StatelessWidget {
  const Step3Time({
    super.key,
    required this.notifier,
    required this.state,
    required this.totalDurationMinutes,
  });

  final BookingFlowNotifier notifier;
  final BookingFlowState state;
  final int totalDurationMinutes;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.timeSlots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final slots =
        state.timeSlots.where((s) => s.isAvailable).toList();
    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_filled,
                  color: AppColors.gris, size: 48),
              const SizedBox(height: 12),
              Text('Aucun créneau disponible',
                  style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Tous les créneaux de cette date sont pris. Choisis une autre date.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    color: AppColors.gris, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text(
          'Choisis une heure',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        if (totalDurationMinutes > 0)
          Text(
            'Tes services prendront ${_fmtDuration(totalDurationMinutes)} au total',
            style:
                GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = state.selectedSlot?.id == slot.id;
            final timeLabel = slot.startTime.substring(0, 5);
            final isLastFew = slots.length <= 3;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                notifier.selectSlot(slot);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.violet
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.violet
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeLabel,
                      style: GoogleFonts.dmSans(
                        color: isSelected
                            ? Colors.white
                            : AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLastFew) ...[
                      const SizedBox(width: 6),
                      Text(
                        '🔥',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _fmtDuration(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    if (rem == 0) return '${h}h';
    return '${h}h$rem';
  }
}
