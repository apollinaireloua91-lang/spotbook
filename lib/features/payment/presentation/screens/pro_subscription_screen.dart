import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/payment_repository.dart';

class _SubState {
  const _SubState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;
  _SubState copyWith({bool? isLoading, String? error}) =>
      _SubState(isLoading: isLoading ?? this.isLoading, error: error);
}

class _SubNotifier extends Notifier<_SubState> {
  @override
  _SubState build() => const _SubState();

  Future<String?> subscribe() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final url =
          await ref.read(paymentRepositoryProvider).createProSubscription();
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final _subProvider = NotifierProvider<_SubNotifier, _SubState>(
  _SubNotifier.new,
  isAutoDispose: true,
);

class ProSubscriptionScreen extends ConsumerWidget {
  const ProSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_subProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text(
          'Spotbook Pro',
          style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.star, color: AppColors.blanc, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Go Premium',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Boost your business with exclusive benefits.',
              style: TextStyle(color: AppColors.gris, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _FeatureTile(
              icon: Icons.percent,
              title: 'Reduced commission to 8%',
              subtitle: 'Instead of 12% on each booking.',
            ),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.verified,
              title: 'Premium Badge',
              subtitle: 'Displayed on your profile and videos.',
            ),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.trending_up,
              title: 'Priority visibility',
              subtitle: 'Appear first in search results.',
            ),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.auto_awesome,
              title: 'Priority visibility',
              subtitle: 'Your videos get boosted in the feed.',
            ),
            const SizedBox(height: 32),
            if (state.error != null) ...[
              Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '29',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          ' CA\$/month',
                          style: TextStyle(color: AppColors.gris, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              final url = await ref
                                  .read(_subProvider.notifier)
                                  .subscribe();
                              if (url != null && context.mounted) {
                                context.push('/subscription-checkout',
                                    extra: url);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blanc,
                        foregroundColor: AppColors.fond,
                        disabledBackgroundColor: AppColors.surfaceAlt,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.gris, strokeWidth: 2),
                            )
                          : const Text(
                              'Subscribe',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cancel anytime. No commitment.',
              style: TextStyle(color: AppColors.gris, fontSize: 12),
            ),
            const SizedBox(height: 32),
          ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.blanc, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.gris, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
