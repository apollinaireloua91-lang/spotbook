import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/app_config_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../auth/data/auth_repository.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN — Shared, role-aware (Client / Pro)
// ═════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final role =
        ref.read(authRepositoryProvider).currentUserRole ?? 'client';
    final isPro = role == 'pro';
    final cfg = ref.watch(appConfigProvider).value ?? AppConfig.fallback;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Paramètres',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
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
              title: 'ENTREPRISE',
              items: [
                _SettingsItem(
                  icon: Icons.build_outlined,
                  label: 'Gérer les services',
                  onTap: () => context.push('/pro/services'),
                ),
                _SettingsItem(
                  icon: Icons.schedule_outlined,
                  label: 'Disponibilité',
                  onTap: () => context.push('/pro/availability'),
                ),
                _SettingsItem(
                  icon: Icons.qr_code,
                  label: 'Mon code QR',
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
                  subtitle: 'Règles et délais de remboursement',
                  onTap: () => context.push('/pro/settings/cancellation'),
                ),
                _SettingsItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Paramètres d\'acompte',
                  subtitle: 'Configurer le pourcentage d\'acompte',
                  onTap: () => context.push('/pro/settings/deposit'),
                ),
                _SettingsItem(
                  icon: Icons.request_quote_outlined,
                  label: 'Soumissions',
                  subtitle: 'Gérer les demandes de soumission',
                  onTap: () => context.push('/pro/soumissions'),
                ),
                _SettingsItem(
                  icon: Icons.percent_outlined,
                  label: 'Commissions',
                  subtitle: 'Réservations ${(cfg.commissionBookings * 100).round()}% · Événements ${(cfg.commissionEvents * 100).round()}% · Frais \$${cfg.serviceFeeClient.toStringAsFixed(2)}',
                  onTap: () => context.push('/pro/settings/commissions'),
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
                  subtitle: 'Configurer les paiements',
                  onTap: () => context.push('/pro/stripe-connect'),
                ),
                _SettingsItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Revenus & Stats',
                  onTap: () => context.push('/pro/revenue'),
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

          // ── Preferences ──
          _SettingsSection(
            title: 'PRÉFÉRENCES',
            items: [
              _SettingsItem(
                icon: Icons.language_outlined,
                label: 'Langue',
                onTap: () => context.push('/language-settings'),
              ),
              if (isPro)
                _SettingsItem(
                  icon: Icons.star_outline,
                  label: 'Mes avis',
                  onTap: () => context.push('/review'),
                ),
            ],
          ),

          // ── Support ──
          _SettingsSection(
            title: 'SUPPORT',
            items: [
              _SettingsItem(
                icon: Icons.email_outlined,
                label: 'Nous contacter',
                onTap: () => launchUrl(
                  Uri.parse('https://getspotbook.app/support#contact'),
                  mode: LaunchMode.externalApplication,
                ),
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
                onTap: () => launchUrl(
                  Uri.parse('https://getspotbook.app/terms'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Politique de confidentialité',
                onTap: () => launchUrl(
                  Uri.parse('https://getspotbook.app/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
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
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Déconnexion ?',
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
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.dmSans(
                            color: AppColors.gris,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
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
                  try {
                    await ref.read(authRepositoryProvider).signOut();
                  } catch (e) {
                    debugPrint('[settings] signOut error ignored: $e');
                  }
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
                    'Déconnexion',
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
        decoration: BoxDecoration(
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
            Icon(Icons.arrow_forward_ios,
                color: AppColors.gris, size: 14),
          ],
        ),
      ),
    );
  }
}

