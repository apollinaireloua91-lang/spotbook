import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/spotbook_card.dart';
import '../../../data/booking_notifier.dart';

/// Step 4 — Review & extras. Shows the full cart breakdown + date/time,
/// plus room for promo code and (future) recurring/group toggles.
class Step4Summary extends StatelessWidget {
  const Step4Summary({
    super.key,
    required this.state,
    required this.currency,
  });

  final BookingFlowState state;
  final String currency;

  String _fmt(double v) =>
      CurrencyFormatter.formatAmount(v, currency: currency);

  String _fmtDate() {
    if (state.selectedDate == null) return '—';
    final d = DateTime.parse(state.selectedDate!);
    return DateFormat('EEEE d MMMM', 'fr_FR').format(d);
  }

  String _fmtTime() {
    final slot = state.selectedSlot;
    if (slot == null) return '—';
    return slot.startTime.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final cart = state.cart;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text(
          'Vérifie ta réservation',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        // Date/time card
        SpotbookCard(
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: _fmtDate(),
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                icon: Icons.access_time_rounded,
                label: 'Heure',
                value: _fmtTime(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Cart items breakdown
        SpotbookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: AppColors.violetClair, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Détail',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...cart.items.map((it) => _CartItemRow(
                    item: it,
                    currency: currency,
                  )),
              Divider(
                height: 20,
                thickness: 0.5,
                color: AppColors.border.withValues(alpha: 0.6),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sous-total',
                      style: GoogleFonts.dmSans(
                          color: AppColors.gris, fontSize: 13)),
                  Text(_fmt(cart.subtotal),
                      style: GoogleFonts.dmSans(
                          color: AppColors.gris, fontSize: 13)),
                ],
              ),
              if (state.promoApplied) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Promo (${state.promoCode?.code ?? ''})',
                        style: GoogleFonts.dmSans(
                            color: AppColors.success, fontSize: 13)),
                    Text('-${_fmt(cart.subtotal - state.totalPrice)}',
                        style: GoogleFonts.dmSans(
                            color: AppColors.success, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text(_fmt(state.totalPrice),
                      style: GoogleFonts.sora(
                          color: AppColors.violetClair,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.violetClair, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style:
              GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item, required this.currency});
  final dynamic item; // BookingCartItem — typed via static import
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.serviceName as String,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(
                    item.servicePrice as double,
                    currency: currency),
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '${item.serviceDurationMinutes} min',
            style: GoogleFonts.dmSans(
                color: AppColors.gris, fontSize: 12),
          ),
          if ((item.selectedAddons as List).isNotEmpty) ...[
            const SizedBox(height: 4),
            ...(item.selectedAddons as List).map((a) => Padding(
                  padding: const EdgeInsets.only(left: 10, top: 2),
                  child: Row(
                    children: [
                      Text('+ ',
                          style: GoogleFonts.dmSans(
                              color: AppColors.violetClair,
                              fontSize: 12)),
                      Expanded(
                        child: Text(
                          a.name as String,
                          style: GoogleFonts.dmSans(
                              color: AppColors.grisClair, fontSize: 12),
                        ),
                      ),
                      Text(
                        '+${CurrencyFormatter.formatAmount(a.price as double, currency: currency)}',
                        style: GoogleFonts.dmSans(
                            color: AppColors.violetClair, fontSize: 12),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
