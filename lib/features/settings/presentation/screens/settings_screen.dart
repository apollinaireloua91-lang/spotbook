import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/app_config_provider.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context)!;
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
          l.settings,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
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
      ),
      body: ListView(
        children: [
          // ── Compte ──
          _SettingsSection(
            title: l.settingsSectionAccount,
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                label: l.editProfile,
                onTap: () => context.push('/edit-profile'),
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                label: l.settingsChangePassword,
                onTap: () => context.push('/change-password'),
              ),
            ],
          ),

          // ── Pro: Business ──
          if (isPro)
            _SettingsSection(
              title: l.settingsSectionBusiness,
              items: [
                _SettingsItem(
                  icon: Icons.build_outlined,
                  label: l.settingsManageServices,
                  onTap: () => context.push('/pro/services'),
                ),
                _SettingsItem(
                  icon: Icons.schedule_outlined,
                  label: l.settingsAvailability,
                  onTap: () => context.push('/pro/availability'),
                ),
                _SettingsItem(
                  icon: Icons.qr_code,
                  label: l.settingsMyQrCode,
                  onTap: () => context.push('/pro/qr-code'),
                ),
                _SettingsItem(
                  icon: Icons.celebration_outlined,
                  label: l.settingsMyEvents,
                  onTap: () => context.push('/pro/events'),
                ),
              ],
            ),

          // ── Pro: Réservations ──
          if (isPro)
            _SettingsSection(
              title: l.settingsSectionBookings,
              items: [
                _SettingsItem(
                  icon: Icons.event_note_outlined,
                  label: l.settingsCancellationPolicy,
                  subtitle: l.settingsCancellationPolicySubtitle,
                  onTap: () => context.push('/pro/settings/cancellation'),
                ),
                _SettingsItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l.settingsDepositSettings,
                  subtitle: l.settingsDepositSettingsSubtitle,
                  onTap: () => context.push('/pro/settings/deposit'),
                ),
                _SettingsItem(
                  icon: Icons.request_quote_outlined,
                  label: l.settingsQuotes,
                  subtitle: l.settingsQuotesSubtitle,
                  onTap: () => context.push('/pro/soumissions'),
                ),
                _SettingsItem(
                  icon: Icons.percent_outlined,
                  label: l.settingsCommissions,
                  subtitle: l.settingsCommissionsSubtitle(
                    (cfg.commissionBookings * 100).round(),
                    (cfg.commissionEvents * 100).round(),
                    cfg.serviceFeeClient.toStringAsFixed(2),
                  ),
                  onTap: () => context.push('/pro/settings/commissions'),
                ),
              ],
            ),

          // ── Pro: Paiements ──
          if (isPro)
            _SettingsSection(
              title: l.settingsSectionPayments,
              items: [
                _SettingsItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Stripe Connect',
                  subtitle: l.settingsConfigurePayments,
                  onTap: () => context.push('/pro/stripe-connect'),
                ),
                _SettingsItem(
                  icon: Icons.bar_chart_rounded,
                  label: l.settingsRevenueStats,
                  onTap: () => context.push('/pro/revenue'),
                ),
              ],
            ),

          // ── Notifications ──
          _SettingsSection(
            title: l.settingsSectionNotifications,
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: l.settingsHistory,
                onTap: () => context.push('/notifications'),
              ),
              _SettingsItem(
                icon: Icons.tune,
                label: l.settingsPreferences,
                onTap: () => context.push('/notification-settings'),
              ),
            ],
          ),

          // ── Preferences ──
          _SettingsSection(
            title: l.settingsSectionPreferences,
            items: [
              _SettingsItem(
                icon: Icons.language_outlined,
                label: l.settingsLanguage,
                onTap: () => context.push('/language-settings'),
              ),
              if (isPro)
                _SettingsItem(
                  icon: Icons.star_outline,
                  label: l.settingsMyReviews,
                  onTap: () => context.push('/review'),
                ),
            ],
          ),

          // ── Support ──
          _SettingsSection(
            title: l.settingsSectionSupport,
            items: [
              _SettingsItem(
                icon: Icons.email_outlined,
                label: l.settingsContactUs,
                onTap: () => launchUrl(
                  Uri.parse('https://getspotbook.app/support#contact'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),

          // ── Légal ──
          _SettingsSection(
            title: l.settingsSectionLegal,
            items: [
              _SettingsItem(
                icon: Icons.description_outlined,
                label: l.termsOfService,
                onTap: () => launchUrl(
                  Uri.parse('https://getspotbook.app/terms'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: l.privacyPolicy,
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
                      l.logoutConfirmTitle,
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      l.logoutConfirmMessage,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          l.cancel,
                          style: GoogleFonts.dmSans(
                            color: AppColors.gris,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          l.logout,
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
                    l.logout,
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
                l.deleteAccount,
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

