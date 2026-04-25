import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_config_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COMMISSIONS SCREEN — Premium breakdown of Spotbook fees for Pros
// ═════════════════════════════════════════════════════════════════════════════

class CommissionsScreen extends ConsumerWidget {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final cfg = ref.watch(appConfigProvider).value ?? AppConfig.fallback;

    final bookingPct = (cfg.commissionBookings * 100).round();
    final eventPct = (cfg.commissionEvents * 100).round();
    final cateringPct = (cfg.commissionCatering * 100).round();

    // Example calculation
    const examplePrice = 100.0;
    final exampleCommission = examplePrice * cfg.commissionBookings;
    final examplePro = examplePrice - exampleCommission;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.retourLabel,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          l.commissionsTitle,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.isDark
                      ? [AppColors.violetDarkGradient, AppColors.violetDarkGradientEnd]
                      : [
                          AppColors.violet.withAlpha(20),
                          AppColors.violet.withAlpha(8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.percent, color: AppColors.violet, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    l.commissionsTransparentPricing,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.commissionsDescription,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Commission breakdown ──
            Text(
              l.commissionsRates,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),

            _CommissionCard(
              icon: Icons.content_cut,
              title: l.commissionsServiceBookings,
              rate: '$bookingPct%',
              description: l.commissionsServiceBookingsDesc,
              example: l.commissionsExampleService(
                  100, (100 - bookingPct).toStringAsFixed(0)),
              color: AppColors.violet,
            ),
            const SizedBox(height: 12),

            _CommissionCard(
              icon: Icons.confirmation_number,
              title: l.commissionsEventTickets,
              rate: '$eventPct%',
              description: l.commissionsEventTicketsDesc,
              example: l.commissionsExampleTicket(
                  50, (50 - 50 * eventPct / 100).toStringAsFixed(0)),
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),

            _CommissionCard(
              icon: Icons.restaurant,
              title: l.commissionsCateringDeposits,
              rate: '$cateringPct%',
              description: l.commissionsCateringDesc,
              example: l.commissionsExampleCatering(
                  200, (200 - 200 * cateringPct / 100).toStringAsFixed(0)),
              color: AppColors.success,
            ),

            const SizedBox(height: 28),

            // ── Client fee ──
            Text(
              l.commissionsClientServiceFee,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        CurrencyFormatter.formatAmount(cfg.serviceFeeClient),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.commissionsFixedFeePerBooking,
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.commissionsFixedFeeDescription,
                          style: GoogleFonts.dmSans(
                            color: AppColors.gris,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Payment example ──
            Text(
              l.commissionsDetailedExample,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _ExampleRow(
                    label: l.commissionsServicePrice,
                    value: CurrencyFormatter.formatAmount(examplePrice),
                  ),
                  _ExampleRow(
                    label: l.commissionsSpotbookCommission(bookingPct),
                    value: '-${CurrencyFormatter.formatAmount(exampleCommission)}',
                    isNegative: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.border, height: 1),
                  ),
                  _ExampleRow(
                    label: l.commissionsYouReceive,
                    value: CurrencyFormatter.formatAmount(examplePro),
                    isBold: true,
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),
                  _ExampleRow(
                    label: l.commissionsClientPaysService,
                    value: CurrencyFormatter.formatAmount(examplePrice),
                  ),
                  _ExampleRow(
                    label: l.commissionsClientPaysFee,
                    value: '+${CurrencyFormatter.formatAmount(cfg.serviceFeeClient)}',
                  ),
                  const SizedBox(height: 4),
                  _ExampleRow(
                    label: l.commissionsClientTotal,
                    value: CurrencyFormatter.formatAmount(
                        examplePrice + cfg.serviceFeeClient),
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Payout info ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance,
                          color: AppColors.violet, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l.commissionsPayouts,
                        style: GoogleFonts.dmSans(
                          color: AppColors.violet,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.commissionsPayoutsDescription,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CommissionCard — a single commission rate card
// ─────────────────────────────────────────────────────────────────────────────

class _CommissionCard extends StatelessWidget {
  const _CommissionCard({
    required this.icon,
    required this.title,
    required this.rate,
    required this.description,
    required this.example,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String rate;
  final String description;
  final String example;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withAlpha(35),
                  color.withAlpha(15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.dmSans(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rate,
                        style: GoogleFonts.dmSans(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  example,
                  style: GoogleFonts.dmSans(
                    color: AppColors.violet,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExampleRow — label + value row in the example breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isNegative = false,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final bool isBold;
  final bool isNegative;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: isBold ? AppColors.blanc : AppColors.gris,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: isNegative
                  ? AppColors.error
                  : (isPrimary ? AppColors.violet : AppColors.blanc),
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
