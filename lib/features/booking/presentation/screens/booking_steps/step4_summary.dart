import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/app_config_provider.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/spotbook_card.dart';
import '../../../data/booking_notifier.dart';
import '../../../domain/service_addon_models.dart';

/// Step 4 — Summary.
/// Hero card with date/time, service breakdown, transparent fee lines,
/// and deposit amount the client pays now.
class Step4Summary extends ConsumerWidget {
  const Step4Summary({
    super.key,
    required this.state,
    required this.currency,
  });

  final BookingFlowState state;
  final String currency;

  String _fmt(double v) =>
      CurrencyFormatter.formatAmount(v, currency: currency);

  String _fmtDateLong() {
    if (state.selectedDate == null) return '—';
    final d = DateTime.parse(state.selectedDate!);
    final formatted = DateFormat('EEEE d MMMM', 'fr_FR').format(d);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _fmtTimeRange(int totalMinutes) {
    final slot = state.selectedSlot;
    if (slot == null) return '—';
    final startStr = slot.startTime.substring(0, 5);
    final parts = startStr.split(':');
    int h = int.parse(parts[0]);
    int m = int.parse(parts[1]) + totalMinutes;
    h += m ~/ 60;
    m = m % 60;
    final endStr =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    return '$startStr → $endStr';
  }

  String _fmtDuration(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    if (rem == 0) return '${h}h';
    return '${h}h${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = state.cart;
    final totalDuration = state.cartTotalDurationMinutes;
    final config = ref.watch(appConfigProvider).value ?? AppConfig.fallback;
    final serviceFee = config.serviceFeeClient;
    final servicesTotal = state.totalPrice;
    final deposit = (servicesTotal * 0.30 * 100).roundToDouble() / 100;
    final dueNow = deposit + serviceFee;
    final remainingOnSite = servicesTotal - deposit;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        _HeaderBlock(),
        const SizedBox(height: 20),
        // Hero card — date + time
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.violet.withValues(alpha: 0.14),
                AppColors.violet.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.violet.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroRow(
                icon: Icons.calendar_today_rounded,
                label: 'DATE',
                value: _fmtDateLong(),
              ),
              Divider(
                  height: 20,
                  thickness: 0.5,
                  color: AppColors.border.withValues(alpha: 0.4)),
              _HeroRow(
                icon: Icons.schedule_rounded,
                label: 'HEURE',
                value: _fmtTimeRange(totalDuration),
                secondary: _fmtDuration(totalDuration),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Breakdown card
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
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...cart.items.map((it) => _CartItemRow(
                    item: it,
                    currency: currency,
                  )),
              if (state.promoApplied) ...[
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  height: 0.5,
                  color: AppColors.border.withValues(alpha: 0.4),
                ),
                _TotalRow(
                  label: 'Promo (${state.promoCode?.code ?? ''})',
                  value: '-${_fmt(cart.subtotal - servicesTotal)}',
                  accent: AppColors.success,
                ),
              ],
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                height: 0.5,
                color: AppColors.border.withValues(alpha: 0.4),
              ),
              // Breakdown of "À payer maintenant"
              _TotalRow(
                label: 'Acompte (30%)',
                value: _fmt(deposit),
                muted: true,
              ),
              const SizedBox(height: 8),
              _TotalRow(
                label: 'Frais de service',
                value: _fmt(serviceFee),
                muted: true,
              ),
              const SizedBox(height: 14),
              // Hero line — what you pay now
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.violet.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: _TotalRow(
                  label: 'À payer maintenant',
                  value: _fmt(dueNow),
                  emphasis: true,
                ),
              ),
              const SizedBox(height: 10),
              _TotalRow(
                label: 'Solde sur place après RDV',
                value: _fmt(remainingOnSite),
                muted: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Trust markers
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              _TrustItem(
                icon: Icons.lock_outline,
                title: 'Paiement sécurisé',
                subtitle: 'Chiffré par Stripe · aucune donnée stockée',
              ),
              const SizedBox(height: 10),
              _TrustItem(
                icon: Icons.notifications_active_outlined,
                title: 'Rappels automatiques',
                subtitle: '24h et 30 min avant ton RDV',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presque fini !',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Vérifie ta réservation avant de payer',
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HeroRow extends StatelessWidget {
  const _HeroRow({
    required this.icon,
    required this.label,
    required this.value,
    this.secondary,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.violetClair, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        if (secondary != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              secondary!,
              style: GoogleFonts.dmSans(
                color: AppColors.violetClair,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item, required this.currency});
  final BookingCartItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.serviceName,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(item.servicePrice,
                    currency: currency),
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  color: AppColors.gris, size: 11),
              const SizedBox(width: 4),
              Text(
                '${item.serviceDurationMinutes} min',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (item.selectedAddons.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...item.selectedAddons.map((a) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.violetClair,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          a.name,
                          style: GoogleFonts.dmSans(
                            color: AppColors.grisClair,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '+${CurrencyFormatter.formatAmount(a.price, currency: currency)}',
                        style: GoogleFonts.dmSans(
                          color: AppColors.violetClair,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.muted = false,
    this.emphasis = false,
    this.accent,
  });

  final String label;
  final String value;
  final bool muted;
  final bool emphasis;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        accent ?? (muted ? AppColors.gris : AppColors.blanc);
    final valueColor = accent ??
        (emphasis ? AppColors.violetClair : AppColors.blanc);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasis
              ? GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                )
              : GoogleFonts.dmSans(
                  color: labelColor,
                  fontSize: 13,
                ),
        ),
        Text(
          value,
          style: emphasis
              ? GoogleFonts.sora(
                  color: valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )
              : GoogleFonts.dmSans(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.violetClair, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
