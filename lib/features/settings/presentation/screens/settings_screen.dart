import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../auth/data/auth_repository.dart';

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

/// Réglages client (route `/client/profile/settings`) ou legacy `/settings`.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _supportEmail = 'support@spotbook.app';
  static const _termsUrl = 'https://spotbook.app/terms';
  static const _privacyUrl = 'https://spotbook.app/privacy';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final role = ref.read(authRepositoryProvider).currentUserRole ?? 'client';
    final isPro = role == 'pro';

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.blanc, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'COMPTE',
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                label: 'Modifier le profil',
                onTap: () => context.push(
                  isPro ? '/pro/profile/edit' : '/client/profile/edit',
                ),
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                label: 'Changer le mot de passe',
                onTap: () => context.push(
                  isPro
                      ? '/pro/profile/settings/change-password'
                      : '/client/profile/settings/change-password',
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'SÉCURITÉ',
            items: [
              _SettingsItem(
                icon: Icons.fingerprint,
                label: 'Biométrie',
                onTap: () => _showBiometricsInfo(context),
              ),
            ],
          ),
          _SettingsSection(
            title: 'NOTIFICATIONS',
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: 'Historique des notifications',
                onTap: () => context.push(
                  isPro ? '/pro/notifications' : '/client/notifications',
                ),
              ),
              _SettingsItem(
                icon: Icons.tune,
                label: 'Préférences de notification',
                onTap: () => context.push('/notification-settings'),
              ),
            ],
          ),
          if (isPro)
            _SettingsSection(
              title: 'PRO',
              items: [
                _SettingsItem(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Codes promo',
                  onTap: () => context.push('/pro/profile/promo-codes'),
                ),
                _SettingsItem(
                  icon: Icons.insights_outlined,
                  label: 'Statistiques',
                  onTap: () => context.push('/pro/analytics'),
                ),
              ],
            ),
          if (!isPro)
            _SettingsSection(
              title: 'SOCIAL',
              items: [
                _SettingsItem(
                  icon: Icons.favorite_border,
                  label: 'Favoris',
                  onTap: () => context.push('/client/profile/favorites'),
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
          if (isPro) const _AnalyticsConsentTile(),
          if (isPro)
            _SettingsSection(
              title: 'PAIEMENT',
              items: [
                _SettingsItem(
                  icon: Icons.credit_card_outlined,
                  label: 'Moyens de paiement',
                  onTap: () => _showPaymentsInfo(context),
                ),
              ],
            ),
          if (isPro)
            _SettingsSection(
              title: 'CONFIDENTIALITÉ',
              items: [
                _SettingsItem(
                  icon: Icons.visibility_outlined,
                  label: 'Visibilité du profil',
                  onTap: () => _showPrivacyInfo(context),
                ),
              ],
            ),
          _SettingsSection(
            title: 'LANGUE',
            items: [
              _SettingsItem(
                icon: Icons.language,
                label: l10n.settingsLanguageMenuLabel,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(
                    isPro
                        ? '/pro/profile/settings/language'
                        : '/client/profile/settings/language',
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'SUPPORT',
            items: [
              _SettingsItem(
                icon: Icons.help_outline,
                label: 'Centre d\'aide',
                onTap: () => _openUrl(context, _termsUrl),
              ),
              _SettingsItem(
                icon: Icons.email_outlined,
                label: 'Nous contacter',
                onTap: () => _openMail(context),
              ),
            ],
          ),
          _SettingsSection(
            title: 'LÉGAL',
            items: [
              _SettingsItem(
                icon: Icons.description_outlined,
                label: 'Conditions d\'utilisation',
                onTap: () => _openUrl(context, _termsUrl),
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Politique de confidentialité',
                onTap: () => _openUrl(context, _privacyUrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                try {
                  await ref.read(authRepositoryProvider).signOut();
                } catch (e) {
                  debugPrint('[settings] signOut error ignored: $e');
                }
                if (context.mounted) context.go('/auth/login');
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error),
                ),
                child: const Center(
                  child: Text(
                    'Se déconnecter',
                    style: TextStyle(
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
          Center(
            child: GestureDetector(
              onTap: () => context.push('/delete-account'),
              child: const Text(
                'Supprimer mon compte',
                style: TextStyle(
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

  static Future<void> _openUrl(BuildContext context, String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'Impossible d\'ouvrir le lien',
            style: TextStyle(color: AppColors.blanc),
          ),
        ),
      );
    }
  }

  static Future<void> _openMail(BuildContext context) async {
    HapticFeedback.lightImpact();
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Aide Spotbook'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static void _showBiometricsInfo(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Biométrie',
          style: TextStyle(color: AppColors.blanc),
        ),
        content: const Text(
          'Tu peux activer Face ID ou l’empreinte dans les réglages système de ton téléphone pour sécuriser l’accès à Spotbook. Une option dédiée dans l’app arrive bientôt.',
          style: TextStyle(color: AppColors.gris, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.blanc)),
          ),
        ],
      ),
    );
  }

  static void _showPaymentsInfo(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Paiement',
          style: TextStyle(color: AppColors.blanc),
        ),
        content: const Text(
          'Les réservations et billets sont payés en toute sécurité via Stripe dans l’app (carte enregistrée au moment du paiement). Pour modifier une carte, refais un achat : la nouvelle carte pourra être enregistrée.',
          style: TextStyle(color: AppColors.gris, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.blanc)),
          ),
        ],
      ),
    );
  }

  static void _showPrivacyInfo(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confidentialité',
          style: TextStyle(color: AppColors.blanc),
        ),
        content: const Text(
          'Ton profil et ton activité sont protégés selon notre politique de confidentialité. Tu peux gérer le consentement analytics dans la section ci-dessous.',
          style: TextStyle(color: AppColors.gris, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.blanc)),
          ),
        ],
      ),
    );
  }

}

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
            style: const TextStyle(
              color: AppColors.gris,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.blanc, fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gris, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsConsentTile extends ConsumerWidget {
  const _AnalyticsConsentTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(analyticsConsentProvider);
    return _SettingsSection(
      title: 'ANALYTICS',
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
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: consentAsync.when(
        data: (value) => Row(
          children: [
            const Icon(Icons.analytics_outlined,
                color: AppColors.blanc, size: 22),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics (RGPD)',
                    style: TextStyle(color: AppColors.blanc, fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Initialisé uniquement après consentement.',
                    style: TextStyle(color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: value ?? false,
              activeTrackColor: AppColors.blanc,
              inactiveTrackColor: AppColors.surfaceAlt,
              onChanged: (v) async {
                HapticFeedback.mediumImpact();
                await ref.read(analyticsConsentProvider.notifier).setConsent(v);
              },
            ),
          ],
        ),
        loading: () => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceAlt,
          child: Container(height: 42, color: AppColors.surface),
        ),
        error: (_, __) => const Text(
          'Erreur chargement consentement',
          style: TextStyle(color: AppColors.error, fontSize: 13),
        ),
      ),
    );
  }
}
