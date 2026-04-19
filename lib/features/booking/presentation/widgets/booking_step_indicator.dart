import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';

/// Horizontal progress indicator for the 6-step booking flow.
/// Shows filled dots for completed steps, a pulsating dot for current,
/// and empty circles for upcoming steps.
class BookingStepIndicator extends StatelessWidget {
  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String>? labels;

  static const List<String> _defaultLabels = [
    'Service',
    'Date',
    'Heure',
    'Résumé',
    'Paiement',
  ];

  @override
  Widget build(BuildContext context) {
    final lbls = labels ?? _defaultLabels.take(totalSteps).toList();
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final isDone = i < currentStep;
            final isActive = i == currentStep;
            return Expanded(
              child: Row(
                children: [
                  _StepDot(isDone: isDone, isActive: isActive, index: i + 1),
                  if (i < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.violet
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (i) {
            final isActive = i == currentStep;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  lbls[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: isActive
                        ? AppColors.violetClair
                        : AppColors.gris.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.isDone,
    required this.isActive,
    required this.index,
  });

  final bool isDone;
  final bool isActive;
  final int index;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    if (isDone) {
      bg = AppColors.violet;
      border = AppColors.violet;
    } else if (isActive) {
      bg = AppColors.violet;
      border = AppColors.violetClair;
    } else {
      bg = Colors.transparent;
      border = AppColors.border;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text(
                '$index',
                style: GoogleFonts.dmSans(
                  color: isActive ? Colors.white : AppColors.gris,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
