import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/booking_models.dart';

class PersonCountPicker extends StatelessWidget {
  const PersonCountPicker({
    super.key,
    required this.service,
    required this.count,
    required this.onChanged,
    this.selectedExtras = const {},
  });

  final ServiceModel service;
  final int count;
  final ValueChanged<int> onChanged;
  final Set<String> selectedExtras;

  @override
  Widget build(BuildContext context) {
    final min = service.minPersons ?? 1;
    final max = service.maxPersons ?? 100;
    final pricePerPerson = service.pricePerPerson ?? service.price;

    // Calculate extras cost per person
    double extrasPerPerson = 0;
    for (final extra in service.extraOptions) {
      if (selectedExtras.contains(extra.id)) {
        extrasPerPerson += extra.pricePerPerson;
      }
    }

    final totalPerPerson = pricePerPerson + extrasPerPerson;
    final totalPrice = totalPerPerson * count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of people',
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$min–$max people',
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        // Counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterButton(
                icon: Icons.remove,
                enabled: count > min,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(count - 1);
                },
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add,
                enabled: count < max,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(count + 1);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Price breakdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _PriceRow(
                label: 'Price per person',
                value: '${pricePerPerson.toStringAsFixed(0)} \$',
              ),
              if (extrasPerPerson > 0) ...[
                const SizedBox(height: 8),
                _PriceRow(
                  label: 'Options per person',
                  value: '+${extrasPerPerson.toStringAsFixed(0)} \$',
                ),
              ],
              const SizedBox(height: 8),
              _PriceRow(
                label: '$count personnes',
                value: '× ${totalPerPerson.toStringAsFixed(0)} \$',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.border, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${totalPrice.toStringAsFixed(0)} \$',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.violet.withAlpha(30)
              : AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.violet : AppColors.gris.withAlpha(80),
          size: 22,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
