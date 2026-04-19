import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../data/booking_notifier.dart';
import '../../../domain/booking_models.dart';

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

  /// Returns only slots where there are enough CONSECUTIVE free 15-min slots
  /// to cover the total booking duration. For a 90-min booking, that's 6
  /// contiguous 15-min slots starting at the picked time.
  ///
  /// Conservative: if `totalDurationMinutes` is 0 (cart empty — shouldn't
  /// happen at step 3), we return all available slots.
  List<TimeSlotModel> _filterByDuration(List<TimeSlotModel> availableSlots) {
    if (totalDurationMinutes <= 0) return availableSlots;

    // Build an index of available slots by HH:mm for fast lookup
    final availableTimes = <String>{};
    for (final s in availableSlots) {
      availableTimes.add(s.startTime.substring(0, 5));
    }

    int slotsNeeded = (totalDurationMinutes / 15).ceil();
    if (slotsNeeded < 1) slotsNeeded = 1;

    final result = <TimeSlotModel>[];
    for (final slot in availableSlots) {
      final startStr = slot.startTime.substring(0, 5);
      final parts = startStr.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      bool ok = true;
      for (var i = 1; i < slotsNeeded; i++) {
        m += 15;
        if (m >= 60) {
          m -= 60;
          h += 1;
        }
        if (h >= 24) {
          ok = false;
          break;
        }
        final next =
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        if (!availableTimes.contains(next)) {
          ok = false;
          break;
        }
      }
      if (ok) result.add(slot);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.timeSlots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final allAvailable =
        state.timeSlots.where((s) => s.isAvailable).toList();
    // Filter to only slots that can fit the total cart duration
    final slots = _filterByDuration(allAvailable);
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
