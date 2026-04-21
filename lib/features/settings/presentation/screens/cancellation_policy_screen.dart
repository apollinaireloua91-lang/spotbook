import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CANCELLATION POLICY SCREEN — Premium informational page for Pros
// ═════════════════════════════════════════════════════════════════════════════

class CancellationPolicyScreen extends ConsumerWidget {
  const CancellationPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
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
          l.cancellationPolicyTitle,
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
                    l.cancellationProtectTitle,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.cancellationProtectDescription,
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
              l.cancellationHowItWorks,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Rule 1 — More than 24h (full refund).
            // Aligné sur la policy `moderate` appliquée par l'Edge Function
            // `cancel-booking` (seuil 24h, 100 % > 24h, 50 % ≤ 24h).
            // Le 48h précédemment affiché correspond au délai de payout
            // Stripe — pas à la politique client — d'où la divergence
            // UI↔backend fermée ici.
            _PolicyRule(
              icon: Icons.check_circle,
              iconColor: AppColors.success,
              title: l.cancellationRuleMoreThan24hTitle,
              subtitle: l.cancellationRuleMoreThan24hSubtitle,
              description: l.cancellationRuleMoreThan24hDescription,
            ),
            const _TimelineLine(),

            // Rule 2 — Less than 24h (partial 50 % refund).
            // Pas d'« Aucun remboursement » : le backend applique 50 %,
            // icône/couleur warning (ambré) et non error — c'est un
            // remboursement partiel, pas une perte totale.
            _PolicyRule(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.warning,
              title: l.cancellationRuleLessThan24hTitle,
              subtitle: l.cancellationRuleLessThan24hSubtitle,
              description: l.cancellationRuleLessThan24hDescription,
            ),
            const _TimelineLine(),

            // Rule 3 — No show (business rule distincte, pas un palier
            // temporel, conservée telle quelle).
            _PolicyRule(
              icon: Icons.person_off,
              iconColor: AppColors.error.withAlpha(200),
              title: l.cancellationRuleNoShowTitle,
              subtitle: l.cancellationRuleNoShowSubtitle,
              description: l.cancellationRuleNoShowDescription,
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
                        l.cancellationIfYouCancel,
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
                    l.cancellationIfYouCancelDescription,
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
              l.cancellationKeyPoints,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _KeyFact(
              icon: Icons.access_time,
              text: l.cancellationFactBasedOnStart,
            ),
            _KeyFact(
              icon: Icons.payment,
              text: l.cancellationFactRefundDelay,
            ),
            _KeyFact(
              icon: Icons.gavel,
              text: l.cancellationFactDisputes,
            ),
            _KeyFact(
              icon: Icons.edit_note,
              text: l.cancellationFactReschedule,
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
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withAlpha(35),
                  iconColor.withAlpha(15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.violet.withAlpha(60),
              AppColors.violet.withAlpha(20),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(1),
        ),
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.violet),
          ),
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
