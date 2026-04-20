import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/spotbook_button.dart';

/// Sticky footer shown at the bottom of every booking-flow step (except confirmation).
/// Displays: cart summary (service count + duration + subtotal) and a primary CTA.
class BookingStepFooter extends StatelessWidget {
  const BookingStepFooter({
    super.key,
    required this.cartSubtotal,
    required this.cartServiceCount,
    required this.cartDurationMinutes,
    required this.currency,
    required this.canProceed,
    required this.nextLabel,
    required this.onNext,
    this.amountOverride,
    this.amountLabelOverride,
  });

  final double cartSubtotal;
  final int cartServiceCount;
  final int cartDurationMinutes;
  final String currency;
  final bool canProceed;
  final String nextLabel;
  final VoidCallback onNext;

  /// When set, replaces the cart subtotal display with this amount.
  /// Used on the summary step to show "À payer maintenant" instead of cart total.
  final double? amountOverride;
  final String? amountLabelOverride;

  String _durationLabel(int m) {
    if (m <= 0) return '—';
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    if (rem == 0) return '${h}h';
    return '${h}h${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasSummary = cartServiceCount > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSummary) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amountLabelOverride ??
                            '$cartServiceCount service${cartServiceCount > 1 ? 's' : ''}'
                                ' · ${_durationLabel(cartDurationMinutes)}',
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatAmount(
                            amountOverride ?? cartSubtotal,
                            currency: currency),
                        style: GoogleFonts.sora(
                          color: amountOverride != null
                              ? AppColors.violetClair
                              : AppColors.blanc,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SpotbookButton.primary(
                    label: nextLabel,
                    onPressed: canProceed ? onNext : null,
                  ),
                ),
              ],
            ),
          ] else
            SpotbookButton.primary(
              label: nextLabel,
              onPressed: canProceed ? onNext : null,
            ),
        ],
      ),
    );
  }
}
