import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';

/// Encart d'information affiché côté client quand `payment_mode == 'deposit'`
/// et qu'un solde reste à régler en mains propres au pro le jour du RDV.
///
/// Tap to Pay (mek_stripe_terminal) est désactivé en v1.0 — l'encaissement
/// sur place se fait uniquement par virement Interac ou cash. Le pro reçoit
/// 100 % du solde réglé en mains propres (la commission a déjà été prélevée
/// sur l'acompte).
///
/// Trois surfaces d'affichage :
///   1. step5_payment.dart       — pré-paiement (récap avant Pay)
///   2. step6_confirmation.dart  — post-paiement (succès)
///   3. booking_detail_screen    — vue client tant que `remaining_payment_status != 'paid_on_site'`
class OnSiteBalanceNotice extends StatelessWidget {
  const OnSiteBalanceNotice({
    super.key,
    required this.depositAmount,
    required this.serviceFee,
    required this.remainingAmount,
    required this.currency,
  });

  final double depositAmount;
  final double serviceFee;
  final double remainingAmount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    String fmt(double v) =>
        CurrencyFormatter.formatAmount(v, currency: currency);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.violet.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Paiement en ligne',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Line(label: 'Acompte réglé', value: fmt(depositAmount)),
          _Line(label: 'Frais de service', value: fmt(serviceFee)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Solde à régler au pro le jour du RDV',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Line(
            label: 'Montant restant',
            value: fmt(remainingAmount),
            valueColor: AppColors.violetClair,
            emphasize: true,
          ),
          _Line(label: 'Moyens acceptés', value: 'virement Interac, cash'),
          const SizedBox(height: 8),
          Text(
            'Le pro reçoit 100 % du solde payé en mains propres.',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 11.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.grisClair,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: valueColor ?? AppColors.blanc,
              fontSize: emphasize ? 14 : 12,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
