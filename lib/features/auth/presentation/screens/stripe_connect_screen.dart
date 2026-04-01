import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../profile/data/provider_settings_repository.dart';

class _StripeConnectState {
  const _StripeConnectState({this.isLoading = false});
  final bool isLoading;
  _StripeConnectState copyWith({bool? isLoading}) =>
      _StripeConnectState(isLoading: isLoading ?? this.isLoading);
}

class _StripeConnectNotifier extends Notifier<_StripeConnectState> {
  @override
  _StripeConnectState build() => const _StripeConnectState();

  Future<String?> startOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(providerSettingsRepositoryProvider);
      final url = await repo.fetchStripeConnectOnboardingUrl();
      state = state.copyWith(isLoading: false);
      return url;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return null;
    }
  }
}

final _stripeConnectProvider =
    NotifierProvider<_StripeConnectNotifier, _StripeConnectState>(
  _StripeConnectNotifier.new,
  isAutoDispose: true,
);

class StripeConnectScreen extends ConsumerWidget {
  const StripeConnectScreen({super.key});

  Future<void> _openStripeOnboarding(BuildContext context, WidgetRef ref) async {
    final url = await ref.read(_stripeConnectProvider.notifier).startOnboarding();
    if (!context.mounted) return;
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } else {
      context.go('/pro');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_stripeConnectProvider);

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
        title: const Text(
          'Configurer vos reversements',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.surfaceAlt,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.blanc,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Via Stripe Connect',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Spotbook utilise Stripe pour garantir des paiements rapides et sécurisés directement sur votre compte bancaire.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gris,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: s.isLoading ? null : () => _openStripeOnboarding(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blanc,
                    foregroundColor: AppColors.fond,
                    disabledBackgroundColor: AppColors.surfaceAlt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: s.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.blanc,
                          ),
                        )
                      : const Text(
                          'Connecter avec Stripe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const Spacer(),
              _trustBadge(
                Icons.lock,
                'Transactions sécurisées SSL',
                'Cryptage de bout en bout conforme PCI',
              ),
              const SizedBox(height: 12),
              _trustBadge(
                Icons.verified_user,
                'Vérification Spotbook Pro',
                'Identité confirmée et protégée',
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('mailto:support@spotbook.app'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(
                  'Besoin d\'aide ? Contactez le support',
                  style: TextStyle(color: AppColors.gris, fontSize: 13, decoration: TextDecoration.underline, decorationColor: AppColors.gris),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}
