import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../data/booking_notifier.dart';
import '../../../domain/booking_models.dart';

/// Step 3 — Time slot picker, Squire-style.
///
/// Slots are grouped by period (Matin / Après-midi / Soirée) with collapsible
/// headers showing the count of available slots. Each chip is spacious and
/// clearly tappable. A "popular" badge appears on the first 3 slots of each
/// afternoon to create gentle social proof without being pushy.
///
/// Multi-service filtering: only slots where enough consecutive 15-min slots
/// exist to cover the total cart duration are shown — no dead-end taps.
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

  /// Filter slots to only those that have `totalDurationMinutes` of consecutive
  /// 15-min availability.
  List<TimeSlotModel> _filterByDuration(List<TimeSlotModel> availableSlots) {
    if (totalDurationMinutes <= 0) return availableSlots;

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

  String _fmtDuration(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    if (rem == 0) return '${h}h';
    return '${h}h$rem';
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.timeSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.violetClair,
                strokeWidth: 2.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des créneaux...',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final allAvailable =
        state.timeSlots.where((s) => s.isAvailable).toList();
    final slots = _filterByDuration(allAvailable);

    if (slots.isEmpty) {
      return _EmptyState(
        title: 'Aucun créneau disponible',
        subtitle: state.timeSlots.isEmpty
            ? 'Ce pro n\'a pas d\'horaires sur cette date.'
            : totalDurationMinutes > 60
                ? 'Aucun créneau libre pour une durée de ${_fmtDuration(totalDurationMinutes)}. Essaie un autre jour ou réduis ta sélection.'
                : 'Tous les créneaux sont pris. Choisis une autre date.',
      );
    }

    // Group slots by period
    final morning = <TimeSlotModel>[];
    final afternoon = <TimeSlotModel>[];
    final evening = <TimeSlotModel>[];
    for (final slot in slots) {
      final hour = int.parse(slot.startTime.substring(0, 2));
      if (hour < 12) {
        morning.add(slot);
      } else if (hour < 17) {
        afternoon.add(slot);
      } else {
        evening.add(slot);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        _Header(
          totalDurationMinutes: totalDurationMinutes,
          fmtDuration: _fmtDuration,
          availableCount: slots.length,
        ),
        const SizedBox(height: 24),
        if (morning.isNotEmpty)
          _PeriodSection(
            title: 'Matin',
            icon: Icons.wb_sunny_outlined,
            accent: AppColors.warning,
            slots: morning,
            selectedSlotId: state.selectedSlot?.id,
            onTap: (s) {
              HapticFeedback.selectionClick();
              notifier.selectSlot(s);
            },
          ),
        if (afternoon.isNotEmpty) ...[
          if (morning.isNotEmpty) const SizedBox(height: 20),
          _PeriodSection(
            title: 'Après-midi',
            icon: Icons.wb_twilight,
            accent: AppColors.violetClair,
            slots: afternoon,
            selectedSlotId: state.selectedSlot?.id,
            highlightPopular: true,
            onTap: (s) {
              HapticFeedback.selectionClick();
              notifier.selectSlot(s);
            },
          ),
        ],
        if (evening.isNotEmpty) ...[
          if (morning.isNotEmpty || afternoon.isNotEmpty)
            const SizedBox(height: 20),
          _PeriodSection(
            title: 'Soirée',
            icon: Icons.nights_stay_outlined,
            accent: AppColors.rose,
            slots: evening,
            selectedSlotId: state.selectedSlot?.id,
            lastFewUrgency: evening.length <= 3,
            onTap: (s) {
              HapticFeedback.selectionClick();
              notifier.selectSlot(s);
            },
          ),
        ],
      ],
    );
  }
}

// ─── Header (hero area) ──────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.totalDurationMinutes,
    required this.fmtDuration,
    required this.availableCount,
  });

  final int totalDurationMinutes;
  final String Function(int) fmtDuration;
  final int availableCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisis ton heure',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.schedule_rounded,
                color: AppColors.violetClair, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                totalDurationMinutes > 0
                    ? 'Durée totale : ${fmtDuration(totalDurationMinutes)}  ·  $availableCount créneaux libres'
                    : '$availableCount créneaux libres',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Period section (Morning / Afternoon / Evening) ──────────────────────

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.slots,
    required this.onTap,
    this.selectedSlotId,
    this.highlightPopular = false,
    this.lastFewUrgency = false,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<TimeSlotModel> slots;
  final ValueChanged<TimeSlotModel> onTap;
  final String? selectedSlotId;
  final bool highlightPopular;
  final bool lastFewUrgency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${slots.length}',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (lastFewUrgency) ...[
                const SizedBox(width: 8),
                Text(
                  '🔥 Dernières places',
                  style: GoogleFonts.dmSans(
                    color: AppColors.rose,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(slots.length, (i) {
            final slot = slots[i];
            final isSelected = selectedSlotId == slot.id;
            final isPopular = highlightPopular && i < 3;
            return _SlotChip(
              slot: slot,
              isSelected: isSelected,
              isPopular: isPopular,
              onTap: () => onTap(slot),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.isPopular,
    required this.onTap,
  });

  final TimeSlotModel slot;
  final bool isSelected;
  final bool isPopular;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = slot.startTime.substring(0, 5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.violet : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.violet
                : AppColors.border.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: GoogleFonts.dmSans(
                color: isSelected ? Colors.white : AppColors.blanc,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (isPopular && !isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.star_rounded,
                  color: AppColors.starGold, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.access_time_rounded,
                  color: AppColors.gris.withValues(alpha: 0.7), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
