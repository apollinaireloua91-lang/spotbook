import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/spotbook_card.dart';
import '../../../data/booking_notifier.dart';

/// Step 5 — Payment.
/// MVP: delegates to existing Stripe flow. Full multi-service server-side
/// booking creation is a follow-up commit.
class Step5Payment extends StatelessWidget {
  const Step5Payment({
    super.key,
    required this.state,
    required this.notifier,
    required this.currency,
  });

  final BookingFlowState state;
  final BookingFlowNotifier notifier;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text(
          'Paiement',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SpotbookCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total à payer',
                      style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text(
                    CurrencyFormatter.formatAmount(state.totalPrice,
                        currency: currency),
                    style: GoogleFonts.sora(
                      color: AppColors.violetClair,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.construction_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paiement Stripe multi-service : en cours de finalisation. Le backend atomique pour créer un booking avec plusieurs services + extras sera livré dans le prochain commit.',
                        style: GoogleFonts.dmSans(
                          color: AppColors.grisClair,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
