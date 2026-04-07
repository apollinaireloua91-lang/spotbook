import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/payment/data/payment_repository.dart';
import '../../../../shared/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// STRIPE CONNECT SCREEN — Pro bank account setup + dashboard
// ═════════════════════════════════════════════════════════════════════════════

class StripeConnectScreen extends ConsumerStatefulWidget {
  const StripeConnectScreen({super.key});

  @override
  ConsumerState<StripeConnectScreen> createState() =>
      _StripeConnectScreenState();
}

class _StripeConnectScreenState extends ConsumerState<StripeConnectScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isActionLoading = false;

  // Stripe Connect status
  String _status = 'not_connected'; // not_connected | pending | active
  bool _detailsSubmitted = false;
  bool _chargesEnabled = false;
  bool _payoutsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh status when returning from Stripe onboarding in browser
    if (state == AppLifecycleState.resumed) {
      _fetchStatus();
    }
  }

  Future<void> _fetchStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data =
          await ref.read(paymentRepositoryProvider).getStripeConnectStatus();
      if (!mounted) return;
      setState(() {
        _status = data['status'] as String? ?? 'not_connected';
        _detailsSubmitted = data['detailsSubmitted'] as bool? ?? false;
        _chargesEnabled = data['chargesEnabled'] as bool? ?? false;
        _payoutsEnabled = data['payoutsEnabled'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openStripeAction() async {
    setState(() => _isActionLoading = true);
    try {
      String url;

      if (_status == 'not_connected') {
        // First time → create account + onboarding link
        url = await ref
            .read(paymentRepositoryProvider)
            .createStripeConnectLink();
      } else {
        // Pending or active → dashboard already returns the right URL
        final data = await ref
            .read(paymentRepositoryProvider)
            .getStripeConnectStatus();
        url = data['url'] as String? ?? '';
      }

      if (url.isEmpty) throw Exception('No URL returned');

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        HapticFeedback.mediumImpact();
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open Stripe');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

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
            onPressed: () => context.pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
          ),
        ),
        title: Text(
          'Paiements',
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchStatus,
            icon: const Icon(Icons.refresh, size: 22),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            )
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              color: AppColors.violet,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  // ── Status card ──
                  _StatusCard(
                    status: _status,
                    detailsSubmitted: _detailsSubmitted,
                    chargesEnabled: _chargesEnabled,
                    payoutsEnabled: _payoutsEnabled,
                  ),

                  const SizedBox(height: 24),

                  // ── Main CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isActionLoading ? null : _openStripeAction,
                      icon: Icon(
                        _status == 'active'
                            ? Icons.dashboard_outlined
                            : Icons.account_balance_outlined,
                        size: 20,
                      ),
                      label: _isActionLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : Text(
                              _status == 'active'
                                  ? 'Accéder au tableau de bord Stripe'
                                  : _status == 'pending'
                                      ? 'Terminer la configuration'
                                      : 'Connecter mon compte bancaire',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        foregroundColor: AppColors.textOnPrimary,
                        disabledBackgroundColor:
                            AppColors.violet.withAlpha(128),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── How it works ──
                  Text(
                    'Comment ça fonctionne',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _StepTile(
                    number: '1',
                    title: 'Connectez votre compte',
                    subtitle:
                        'Renseignez vos coordonnées bancaires via Stripe, notre partenaire de paiement sécurisé.',
                  ),
                  _StepTile(
                    number: '2',
                    title: 'Recevez des réservations',
                    subtitle:
                        'Vos clients paient un acompte de 30% lors de la réservation.',
                  ),
                  _StepTile(
                    number: '3',
                    title: 'Recevez vos paiements',
                    subtitle:
                        'L\'acompte est viré automatiquement sur votre compte après chaque prestation confirmée.',
                  ),

                  const SizedBox(height: 28),

                  // ── Trust badges ──
                  _TrustBadge(
                    icon: Icons.lock_outline,
                    title: 'Transactions sécurisées SSL',
                    subtitle: 'Chiffrement PCI-DSS de bout en bout',
                  ),
                  const SizedBox(height: 10),
                  _TrustBadge(
                    icon: Icons.verified_user_outlined,
                    title: 'Stripe, leader mondial',
                    subtitle:
                        'Utilisé par des millions d\'entreprises dans le monde',
                  ),
                  const SizedBox(height: 10),
                  _TrustBadge(
                    icon: Icons.speed_outlined,
                    title: 'Virements rapides',
                    subtitle: 'Recevez votre argent en 2-7 jours ouvrés',
                  ),

                  const SizedBox(height: 28),

                  // ── Support link ──
                  Center(
                    child: GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('https://getspotbook.app/support#contact'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        'Besoin d\'aide ? Contacter le support',
                        style: GoogleFonts.dmSans(
                          color: AppColors.violet,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STATUS CARD
// ═════════════════════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.detailsSubmitted,
    required this.chargesEnabled,
    required this.payoutsEnabled,
  });

  final String status;
  final bool detailsSubmitted;
  final bool chargesEnabled;
  final bool payoutsEnabled;

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == 'active';
    final bool isPending = status == 'pending';

    final Color statusColor = isActive
        ? AppColors.success
        : isPending
            ? AppColors.warning
            : AppColors.grisInactif;

    final String statusLabel = isActive
        ? 'Compte actif'
        : isPending
            ? 'Configuration en cours'
            : 'Non configuré';

    final IconData statusIcon = isActive
        ? Icons.check_circle
        : isPending
            ? Icons.pending
            : Icons.circle_outlined;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.success.withAlpha(80)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Icon + status
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stripe Connect',
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: GoogleFonts.dmSans(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Checklist for pending/active
          if (isPending || isActive) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),
            _CheckItem(
              label: 'Informations soumises',
              done: detailsSubmitted,
            ),
            const SizedBox(height: 8),
            _CheckItem(
              label: 'Paiements activés',
              done: chargesEnabled,
            ),
            const SizedBox(height: 8),
            _CheckItem(
              label: 'Virements activés',
              done: payoutsEnabled,
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.success : AppColors.grisInactif,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: done ? AppColors.blanc : AppColors.gris,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STEP TILE
// ═════════════════════════════════════════════════════════════════════════════

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.dmSans(
                  color: AppColors.violet,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 13,
                    height: 1.4,
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

// ═════════════════════════════════════════════════════════════════════════════
// TRUST BADGE
// ═════════════════════════════════════════════════════════════════════════════

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}
