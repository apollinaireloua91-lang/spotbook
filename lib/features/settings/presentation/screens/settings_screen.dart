import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.read(authRepositoryProvider).currentUserRole ?? 'client';

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(children: [
        _SettingsSection(title: 'ACCOUNT', items: [
          _SettingsItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () => context.push('/edit-profile')),
          _SettingsItem(icon: Icons.lock_outline, label: 'Change Password', onTap: () {}),
        ]),
        _SettingsSection(title: 'SECURITY', items: [
          _SettingsItem(icon: Icons.fingerprint, label: 'Biometrics', onTap: () {}),
        ]),
        _SettingsSection(title: 'NOTIFICATIONS', items: [
          _SettingsItem(icon: Icons.notifications_outlined, label: 'Notification History', onTap: () => context.push('/notifications')),
          _SettingsItem(icon: Icons.tune, label: 'Notification Preferences', onTap: () => context.push('/notification-settings')),
        ]),
        if (role == 'pro')
          _SettingsSection(title: 'PROMO CODES', items: [
            _SettingsItem(icon: Icons.confirmation_number_outlined, label: 'Manage Promo Codes', onTap: () => context.push('/promo-codes')),
            _SettingsItem(icon: Icons.insights_outlined, label: 'Pro Insights', onTap: () => context.push('/pro-insights')),
          ]),
        _SettingsSection(title: 'SOCIAL', items: [
          _SettingsItem(icon: Icons.favorite_border, label: 'Favorites', onTap: () => context.push('/favorites')),
          _SettingsItem(icon: Icons.card_giftcard_outlined, label: 'Referral', onTap: () => context.push('/referral')),
          _SettingsItem(icon: Icons.block, label: 'Blocked Users', onTap: () => context.push('/blocked-users')),
        ]),
        const _AnalyticsConsentTile(),
        _SettingsSection(title: 'SUPPORT', items: [
          _SettingsItem(icon: Icons.help_outline, label: 'Help Center', onTap: () {}),
          _SettingsItem(icon: Icons.email_outlined, label: 'Contact Us', onTap: () {}),
        ]),
        _SettingsSection(title: 'LEGAL', items: [
          _SettingsItem(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
          _SettingsItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
        ]),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            child: Container(height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error)),
              child: const Center(child: Text('Log Out', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w600)))),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: GestureDetector(
          onTap: () => context.push('/delete-account'),
          child: const Text('Delete my account', style: TextStyle(color: AppColors.gris, fontSize: 14, decoration: TextDecoration.underline)),
        )),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 8), child: Text(title, style: const TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2))),
      ...items,
    ]);
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
        child: Row(children: [
          Icon(icon, color: AppColors.blanc, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.blanc, fontSize: 15))),
          const Icon(Icons.arrow_forward_ios, color: AppColors.gris, size: 14),
        ]),
      ),
    );
  }
}

class _AnalyticsConsentTile extends ConsumerWidget {
  const _AnalyticsConsentTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(analyticsConsentProvider);
    return _SettingsSection(title: 'CONFIDENTIALITÉ', items: [
      _ConsentItem(consentAsync: consentAsync),
    ]);
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
            const Icon(Icons.analytics_outlined, color: AppColors.blanc, size: 22),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics (RGPD)', style: TextStyle(color: AppColors.blanc, fontSize: 15)),
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
