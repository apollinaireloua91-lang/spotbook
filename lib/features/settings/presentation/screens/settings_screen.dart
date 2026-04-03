import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../shared/utils/analytics_service.dart';

// ─── Analytics consent notifier ─────────────────────────────

class AnalyticsConsentNotifier extends AsyncNotifier<bool?> {
  @override
  Future<bool?> build() async {
    return AnalyticsService.instance.getConsent();
  }

  Future<void> setConsent(bool value) async {
    state = const AsyncValue.loading();
    await AnalyticsService.instance.setConsent(value);
    state = AsyncValue.data(value);
  }
}

final analyticsConsentProvider =
    AsyncNotifierProvider<AnalyticsConsentNotifier, bool?>(
  AnalyticsConsentNotifier.new,
);

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN — Shared, role-aware (Client / Pro)
// ═════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role =
        ref.read(authRepositoryProvider).currentUserRole ?? 'client';
    final isPro = role == 'pro';

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Paramètres',
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // ── Compte ──
          _SettingsSection(
            title: 'COMPTE',
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                label: 'Modifier le profil',
                onTap: () => context.push('/edit-profile'),
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                label: 'Changer le mot de passe',
                onTap: () => context.push('/change-password'),
              ),
            ],
          ),

          // ── Pro: Business ──
          if (isPro)
            _SettingsSection(
              title: 'BUSINESS',
              items: [
                _SettingsItem(
                  icon: Icons.build_outlined,
                  label: 'Gérer mes services',
                  onTap: () => context.push('/pro/services'),
                ),
                _SettingsItem(
                  icon: Icons.schedule_outlined,
                  label: 'Disponibilités',
                  onTap: () => context.push('/pro/availability'),
                ),
                _SettingsItem(
                  icon: Icons.qr_code,
                  label: 'Mon QR Code',
                  onTap: () => context.push('/pro/qr-code'),
                ),
                _SettingsItem(
                  icon: Icons.celebration_outlined,
                  label: 'Mes événements',
                  onTap: () => context.push('/pro/events'),
                ),
              ],
            ),

          // ── Pro: Réservations ──
          if (isPro)
            _SettingsSection(
              title: 'RÉSERVATIONS',
              items: [
                _SettingsItem(
                  icon: Icons.event_note_outlined,
                  label: 'Politique d\'annulation',
                  subtitle: 'Remboursement < 48h : acompte conservé',
                  onTap: () {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Politique d\'annulation', style: TextStyle(color: AppColors.blanc)),
                      content: const Text('Annulation < 48h avant le RDV : l\'acompte est conservé par le pro.\nAnnulation > 48h : remboursement intégral.', style: TextStyle(color: AppColors.gris)),
                      actions: [TextButton(onPressed: () => context.pop(), child: const Text('OK'))],
                    ));
                  },
                ),
                _SettingsItem(
                  icon: Icons.percent_outlined,
                  label: 'Commissions',
                  subtitle: '12% standard • 8% premium',
                  onTap: () {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Commissions Spotbook', style: TextStyle(color: AppColors.blanc)),
                      content: const Text('Réservations : 12% (8% pour les pros premium)\nÉvénements : 7%', style: TextStyle(color: AppColors.gris)),
                      actions: [TextButton(onPressed: () => context.pop(), child: const Text('OK'))],
                    ));
                  },
                ),
              ],
            ),

          // ── Pro: Paiements ──
          if (isPro)
            _SettingsSection(
              title: 'PAIEMENTS',
              items: [
                _SettingsItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Stripe Connect',
                  subtitle: 'Configurer les versements',
                  onTap: () => context.push('/pro/stripe-connect'),
                ),
                _SettingsItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Revenus & Statistiques',
                  onTap: () => context.push('/pro/revenue'),
                ),
                _SettingsItem(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Abonnement Pro',
                  onTap: () => context.push('/pro-subscription'),
                ),
              ],
            ),

          // ── Pro: Promo ──
          if (isPro)
            _SettingsSection(
              title: 'PROMOTIONS',
              items: [
                _SettingsItem(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Codes promo',
                  onTap: () => context.push('/promo-codes'),
                ),
                _SettingsItem(
                  icon: Icons.insights_outlined,
                  label: 'Statistiques sociales',
                  onTap: () => context.push('/pro-insights'),
                ),
              ],
            ),

          // ── Notifications ──
          _SettingsSection(
            title: 'NOTIFICATIONS',
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: 'Historique',
                onTap: () => context.push('/notifications'),
              ),
              _SettingsItem(
                icon: Icons.tune,
                label: 'Préférences',
                onTap: () => context.push('/notification-settings'),
              ),
            ],
          ),

          // ── Social ──
          _SettingsSection(
            title: 'SOCIAL',
            items: [
              _SettingsItem(
                icon: Icons.favorite_border,
                label: 'Favoris',
                onTap: () => context.push('/favorites'),
              ),
              _SettingsItem(
                icon: Icons.card_giftcard_outlined,
                label: 'Parrainage',
                onTap: () => context.push('/referral'),
              ),
              _SettingsItem(
                icon: Icons.block,
                label: 'Utilisateurs bloqués',
                onTap: () => context.push('/blocked-users'),
              ),
            ],
          ),

          // ── Privacy / RGPD ──
          const _AnalyticsConsentTile(),

          // ── Support ──
          _SettingsSection(
            title: 'SUPPORT',
            items: [
              _SettingsItem(
                icon: Icons.help_outline,
                label: 'Centre d\'aide',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Centre d\'aide bientôt disponible'), backgroundColor: AppColors.surface));
                },
              ),
              _SettingsItem(
                icon: Icons.email_outlined,
                label: 'Nous contacter',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('support@spotbook.app'), backgroundColor: AppColors.surface));
                },
              ),
            ],
          ),

          // ── Légal ──
          _SettingsSection(
            title: 'LÉGAL',
            items: [
              _SettingsItem(
                icon: Icons.description_outlined,
                label: 'Conditions d\'utilisation',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conditions d\'utilisation bientôt disponibles'), backgroundColor: AppColors.surface));
                },
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Politique de confidentialité',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Politique de confidentialité bientôt disponible'), backgroundColor: AppColors.surface));
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Logout ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Se déconnecter ?',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'Vous serez redirigé vers l\'écran de connexion.',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.dmSans(
                            color: AppColors.gris,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pop(true),
                        child: Text(
                          'Déconnexion',
                          style: GoogleFonts.dmSans(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error),
                ),
                child: Center(
                  child: Text(
                    'Se déconnecter',
                    style: GoogleFonts.dmSans(
                      color: AppColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Delete account ──
          Center(
            child: GestureDetector(
              onTap: () => context.push('/delete-account'),
              child: Text(
                'Supprimer mon compte',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            title,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS ITEM — supports optional subtitle
// ═════════════════════════════════════════════════════════════════════════════

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blanc, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.gris, size: 14),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ANALYTICS CONSENT — RGPD
// ═════════════════════════════════════════════════════════════════════════════

class _AnalyticsConsentTile extends ConsumerWidget {
  const _AnalyticsConsentTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(analyticsConsentProvider);
    return _SettingsSection(
      title: 'CONFIDENTIALITÉ',
      items: [
        _ConsentItem(consentAsync: consentAsync),
      ],
    );
  }
}

class _ConsentItem extends ConsumerWidget {
  const _ConsentItem({required this.consentAsync});

  final AsyncValue<bool?> consentAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: consentAsync.when(
        data: (value) => Row(
          children: [
            const Icon(Icons.analytics_outlined,
                color: AppColors.blanc, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics (RGPD)',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Initialisé uniquement après consentement.',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value ?? false,
              activeTrackColor: AppColors.violet,
              inactiveTrackColor: AppColors.surfaceAlt,
              onChanged: (v) async {
                HapticFeedback.mediumImpact();
                await ref
                    .read(analyticsConsentProvider.notifier)
                    .setConsent(v);
              },
            ),
          ],
        ),
        loading: () => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceAlt,
          child: Container(height: 42, color: AppColors.surface),
        ),
        error: (_, __) => Text(
          'Erreur chargement consentement',
          style: GoogleFonts.dmSans(
            color: AppColors.error,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
