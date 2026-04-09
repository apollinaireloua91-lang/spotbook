import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_config_provider.dart';
import '../../../../shared/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COMMISSIONS SCREEN — Premium breakdown of Spotbook fees for Pros
// ═════════════════════════════════════════════════════════════════════════════

class CommissionsScreen extends ConsumerWidget {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          label: 'Back',
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
          'Spotbook Commissions',
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
                      ? [const Color(0xFF3E065F), const Color(0xFF700B97)]
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
                    'Transparent pricing',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Spotbook takes a small commission on each transaction to maintain the platform. Here\'s the full breakdown.',
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
              'Commission rates',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),

            _CommissionCard(
              icon: Icons.content_cut,
              title: 'Service bookings',
              rate: '$bookingPct%',
              description:
                  'Applied to the total service price when a client books through Spotbook.',
              example:
                  'A \$100 service → You receive \$${(100 - bookingPct).toStringAsFixed(0)}',
              color: AppColors.violet,
            ),
            const SizedBox(height: 12),

            _CommissionCard(
              icon: Icons.confirmation_number,
              title: 'Event tickets',
              rate: '$eventPct%',
              description:
                  'Applied to each ticket sold for your events on the platform.',
              example:
                  'A \$50 ticket → You receive \$${(50 - 50 * eventPct / 100).toStringAsFixed(0)}',
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),

            _CommissionCard(
              icon: Icons.restaurant,
              title: 'Catering deposits',
              rate: '$cateringPct%',
              description:
                  'Same rate as service bookings, applied to catering orders.',
              example:
                  'A \$200 order → You receive \$${(200 - 200 * cateringPct / 100).toStringAsFixed(0)}',
              color: AppColors.success,
            ),

            const SizedBox(height: 28),

            // ── Client fee ──
            Text(
              'Client service fee',
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
                        '\$${cfg.serviceFeeClient.toStringAsFixed(2)}',
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
                          'Fixed fee per booking',
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This fee is charged directly to the client on top of your service price. It does NOT come out of your earnings.',
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
              'Example breakdown',
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
                    label: 'Service price',
                    value: '\$${examplePrice.toStringAsFixed(2)}',
                  ),
                  _ExampleRow(
                    label: 'Spotbook commission ($bookingPct%)',
                    value: '-\$${exampleCommission.toStringAsFixed(2)}',
                    isNegative: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.border, height: 1),
                  ),
                  _ExampleRow(
                    label: 'You receive',
                    value: '\$${examplePro.toStringAsFixed(2)}',
                    isBold: true,
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),
                  _ExampleRow(
                    label: 'Client pays (service)',
                    value: '\$${examplePrice.toStringAsFixed(2)}',
                  ),
                  _ExampleRow(
                    label: 'Client pays (service fee)',
                    value: '+\$${cfg.serviceFeeClient.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 4),
                  _ExampleRow(
                    label: 'Client total',
                    value:
                        '\$${(examplePrice + cfg.serviceFeeClient).toStringAsFixed(2)}',
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
                        'Payouts',
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
                    'Your earnings are transferred to your Stripe Connect account automatically. Payouts are processed daily and typically arrive within 2-3 business days.',
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
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
