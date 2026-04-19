import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../data/booking_notifier.dart';

/// Step 2 — Date picker. Shows a calendar-like grid of available dates
/// for the next 30 days. Tap to select.
class Step2Date extends StatefulWidget {
  const Step2Date({
    super.key,
    required this.notifier,
    required this.state,
  });

  final BookingFlowNotifier notifier;
  final BookingFlowState state;

  @override
  State<Step2Date> createState() => _Step2DateState();
}

class _Step2DateState extends State<Step2Date> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.state.availableDates.isEmpty) {
        widget.notifier.loadDates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (s.isLoading && s.availableDates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.availableDates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined,
                  color: AppColors.gris, size: 48),
              const SizedBox(height: 12),
              Text('Aucune date disponible',
                  style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Ce pro n\'a pas de créneaux dans les 30 prochains jours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    color: AppColors.gris, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Group by month
    final dates =
        s.availableDates.map((d) => DateTime.parse(d)).toList()..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text(
          'Choisis une date',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${dates.length} dates disponibles',
          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: dates.map((d) {
            final iso = DateFormat('yyyy-MM-dd').format(d);
            final isSelected = s.selectedDate == iso;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.notifier.selectDate(iso);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 76,
                height: 88,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.violet : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.violet
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E('fr_FR').format(d).toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color:
                            isSelected ? Colors.white : AppColors.gris,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: GoogleFonts.sora(
                        color: isSelected
                            ? Colors.white
                            : AppColors.blanc,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.MMM('fr_FR').format(d),
                      style: GoogleFonts.dmSans(
                        color:
                            isSelected ? Colors.white : AppColors.gris,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
