import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/promo_repository.dart';

class _ReferralState {
  const _ReferralState({
    this.code,
    this.referralCount = 0,
    this.totalCredits = 0,
    this.isLoading = true,
  });
  final String? code;
  final int referralCount;
  final double totalCredits;
  final bool isLoading;

  _ReferralState copyWith({
    String? code,
    int? referralCount,
    double? totalCredits,
    bool? isLoading,
  }) =>
      _ReferralState(
        code: code ?? this.code,
        referralCount: referralCount ?? this.referralCount,
        totalCredits: totalCredits ?? this.totalCredits,
        isLoading: isLoading ?? this.isLoading,
      );
}

class _ReferralNotifier extends Notifier<_ReferralState> {
  @override
  _ReferralState build() {
    _load();
    return const _ReferralState();
  }

  Future<void> _load() async {
    final repo = ref.read(promoRepositoryProvider);
    final code = await repo.getReferralCode();
    final count = await repo.getReferralCount();
    final credits = await repo.getTotalCredits();
    state = state.copyWith(
      code: code,
      referralCount: count,
      totalCredits: credits,
      isLoading: false,
    );
  }
}

final _referralProvider = NotifierProvider<_ReferralNotifier, _ReferralState>(
  _ReferralNotifier.new,
  isAutoDispose: true,
);

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_referralProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text('Parrainage',
            style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.blanc, strokeWidth: 2)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Icon(Icons.card_giftcard, color: AppColors.blanc, size: 56),
                  const SizedBox(height: 16),
                  const Text('Parrainez, gagnez !',
                      style: TextStyle(color: AppColors.blanc, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Invitez vos amis et recevez 10 CA\$ de crédit pour chaque inscription validée.',
                    style: TextStyle(color: AppColors.gris, fontSize: 15, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Code card
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
                        const Text('Votre code',
                            style: TextStyle(color: AppColors.gris, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          state.code ?? '---',
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    if (state.code != null) {
                                      Clipboard.setData(ClipboardData(text: state.code!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Code copié !'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, color: AppColors.blanc, size: 18),
                                  label: const Text('Copier',
                                      style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.w500)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    SharePlus.instance.share(
                                      ShareParams(
                                        text: 'Rejoins Spotbook avec mon code ${state.code} et gagne 10 CA\$ de crédit ! 🎉',
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Partager',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.blanc,
                                    foregroundColor: AppColors.fond,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Parrainages',
                          value: '${state.referralCount}',
                          icon: Icons.people_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Crédits gagnés',
                          value: '${state.totalCredits.toStringAsFixed(0)} CA\$',
                          icon: Icons.monetization_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gris, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(color: AppColors.blanc, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.gris, fontSize: 13)),
        ],
      ),
    );
  }
}
