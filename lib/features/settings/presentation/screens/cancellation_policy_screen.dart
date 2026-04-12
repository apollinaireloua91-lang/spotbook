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
          'Politique d\'annulation',
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
                    'Protégez votre temps et vos revenus',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notre politique d\'annulation vous protège contre les annulations de dernière minute tout en restant équitable envers les clients.',
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
              'Comment ça fonctionne',
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
              title: 'Plus de 48 heures avant',
              subtitle: 'Remboursement intégral au client',
              description:
                  'Le client reçoit un remboursement complet de son acompte. Aucun frais n\'est facturé.',
            ),
            const _TimelineLine(),

            // Rule 2 — Between 24h and 48h
            _PolicyRule(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.warning,
              title: 'Entre 24h et 48h avant',
              subtitle: '50% de l\'acompte conservé',
              description:
                  'Vous conservez 50% de l\'acompte en compensation. Les 50% restants sont remboursés au client.',
            ),
            const _TimelineLine(),

            // Rule 3 — Less than 24h
            _PolicyRule(
              icon: Icons.block,
              iconColor: AppColors.error,
              title: 'Moins de 24 heures avant',
              subtitle: '100% de l\'acompte conservé',
              description:
                  'Vous conservez la totalité de l\'acompte. Le client n\'est pas éligible à un remboursement.',
            ),
            const _TimelineLine(),

            // Rule 4 — No show
            _PolicyRule(
              icon: Icons.person_off,
              iconColor: AppColors.error.withAlpha(200),
              title: 'Absence',
              subtitle: '100% de l\'acompte conservé',
              description:
                  'Si le client ne se présente pas, vous conservez la totalité de l\'acompte. La réservation est marquée comme terminée.',
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
                        'Si vous annulez',
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
                    'Si vous annulez une réservation, le client reçoit un remboursement intégral quel que soit le délai. Les annulations répétées peuvent affecter votre visibilité sur la plateforme.',
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
              'Points clés',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const _KeyFact(
              icon: Icons.access_time,
              text: 'La politique est basée sur l\'heure de début du rendez-vous',
            ),
            const _KeyFact(
              icon: Icons.payment,
              text: 'Les remboursements sont traités sous 5 à 10 jours ouvrables',
            ),
            const _KeyFact(
              icon: Icons.gavel,
              text: 'Les litiges sont gérés par le support Spotbook',
            ),
            const _KeyFact(
              icon: Icons.edit_note,
              text: 'Le report est gratuit jusqu\'à 24h avant le rendez-vous',
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
