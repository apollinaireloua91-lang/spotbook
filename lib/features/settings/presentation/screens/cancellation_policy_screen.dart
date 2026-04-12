import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CANCELLATION POLICY SCREEN — Premium informational page for Pros
// ═════════════════════════════════════════════════════════════════════════════

class CancellationPolicyScreen extends StatelessWidget {
  const CancellationPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Cancellation Policy',
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
            // ── Header explanation ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.violet.withAlpha(51)),
              ),
              child: Column(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.violet, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Protect your time & revenue',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our cancellation policy ensures you\'re compensated for last-minute cancellations while remaining fair to clients.',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Timeline visual ──
            Text(
              'How it works',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Rule 1 — More than 48h
            _PolicyRule(
              icon: Icons.check_circle,
              iconColor: AppColors.success,
              title: 'More than 48 hours before',
              subtitle: 'Full refund to client',
              description:
                  'The client receives a complete refund of their deposit. No fees are charged.',
            ),
            const _TimelineLine(),

            // Rule 2 — Between 24h and 48h
            _PolicyRule(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.warning,
              title: 'Between 24h and 48h before',
              subtitle: '50% of deposit retained',
              description:
                  'You keep 50% of the deposit as compensation. The remaining 50% is refunded to the client.',
            ),
            const _TimelineLine(),

            // Rule 3 — Less than 24h
            _PolicyRule(
              icon: Icons.block,
              iconColor: AppColors.error,
              title: 'Less than 24 hours before',
              subtitle: '100% of deposit retained',
              description:
                  'You keep the entire deposit. The client is not eligible for a refund.',
            ),
            const _TimelineLine(),

            // Rule 4 — No show
            _PolicyRule(
              icon: Icons.person_off,
              iconColor: AppColors.error.withAlpha(200),
              title: 'No-show',
              subtitle: '100% of deposit retained',
              description:
                  'If the client doesn\'t show up, you keep the full deposit. The booking is marked as completed.',
            ),

            const SizedBox(height: 28),

            // ── Pro cancellation ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withAlpha(51)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'If you cancel',
                        style: GoogleFonts.dmSans(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you cancel a booking, the client receives a full refund regardless of timing. Repeated cancellations may affect your visibility on the platform.',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Key facts ──
            Text(
              'Key facts',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const _KeyFact(
              icon: Icons.access_time,
              text: 'Policy is based on booking start time',
            ),
            const _KeyFact(
              icon: Icons.payment,
              text: 'Refunds are processed within 5-10 business days',
            ),
            const _KeyFact(
              icon: Icons.gavel,
              text: 'Disputes are handled by Spotbook support',
            ),
            const _KeyFact(
              icon: Icons.edit_note,
              text: 'Rescheduling is free up to 24h before',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PolicyRule — a single cancellation rule card
// ─────────────────────────────────────────────────────────────────────────────

class _PolicyRule extends StatelessWidget {
  const _PolicyRule({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimelineLine — vertical connector between rules
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineLine extends StatelessWidget {
  const _TimelineLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Container(
        width: 2,
        height: 20,
        color: AppColors.border,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _KeyFact — icon + text row
// ─────────────────────────────────────────────────────────────────────────────

class _KeyFact extends StatelessWidget {
  const _KeyFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
