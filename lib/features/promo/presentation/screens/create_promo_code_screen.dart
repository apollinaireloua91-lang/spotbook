import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/promo_repository.dart';
import '../../domain/promo_models.dart';

class _PromoListState {
  const _PromoListState({this.codes = const [], this.isLoading = true, this.isCreating = false});
  final List<PromoCodeDetail> codes;
  final bool isLoading;
  final bool isCreating;
  _PromoListState copyWith({List<PromoCodeDetail>? codes, bool? isLoading, bool? isCreating}) =>
      _PromoListState(
        codes: codes ?? this.codes,
        isLoading: isLoading ?? this.isLoading,
        isCreating: isCreating ?? this.isCreating,
      );
}

class _PromoListNotifier extends Notifier<_PromoListState> {
  @override
  _PromoListState build() {
    _load();
    return const _PromoListState();
  }

  Future<void> _load() async {
    final repo = ref.read(promoRepositoryProvider);
    final codes = await repo.getMyPromoCodes();
    state = state.copyWith(codes: codes, isLoading: false);
  }

  Future<void> create({
    required String code,
    required int discountPercent,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    state = state.copyWith(isCreating: true);
    final repo = ref.read(promoRepositoryProvider);
    await repo.createPromoCode(
      code: code,
      discountPercent: discountPercent,
      maxUses: maxUses,
      expiresAt: expiresAt,
    );
    await _load();
    state = state.copyWith(isCreating: false);
  }

  Future<void> deactivate(String id) async {
    final repo = ref.read(promoRepositoryProvider);
    await repo.deactivatePromoCode(id);
    await _load();
  }
}

final _promoListProvider = NotifierProvider<_PromoListNotifier, _PromoListState>(
  _PromoListNotifier.new,
  isAutoDispose: true,
);

class CreatePromoCodeScreen extends ConsumerStatefulWidget {
  const CreatePromoCodeScreen({super.key});

  @override
  ConsumerState<CreatePromoCodeScreen> createState() => _CreatePromoCodeScreenState();
}

class _CreatePromoCodeScreenState extends ConsumerState<CreatePromoCodeScreen> {
  final _codeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  final _expiresCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _maxUsesCtrl.dispose();
    _expiresCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_promoListProvider);

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
        title: const Text('Codes promo',
            style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Create form
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveau code',
                    style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildField(_codeCtrl, 'Code (ex: BIENVENUE20)', TextInputType.text),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildField(_discountCtrl, 'Réduction %', TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField(_maxUsesCtrl, 'Utilisations max', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildField(
                  _expiresCtrl,
                  'Expiration YYYY-MM-DD (optionnel)',
                  TextInputType.datetime,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isCreating
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            final code = _codeCtrl.text.trim();
                            final discount = int.tryParse(_discountCtrl.text);
                            if (code.isEmpty || discount == null || discount <= 0 || discount > 100) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code et réduction (1-100%) requis'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            await ref.read(_promoListProvider.notifier).create(
                                  code: code,
                                  discountPercent: discount,
                                  maxUses: int.tryParse(_maxUsesCtrl.text),
                                  expiresAt: _parseDate(_expiresCtrl.text),
                                );
                            _codeCtrl.clear();
                            _discountCtrl.clear();
                            _maxUsesCtrl.clear();
                            _expiresCtrl.clear();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blanc,
                      foregroundColor: AppColors.fond,
                      disabledBackgroundColor: AppColors.surfaceAlt,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state.isCreating
                        ? Shimmer.fromColors(
                            baseColor: AppColors.surface,
                            highlightColor: AppColors.surfaceAlt,
                            child: Container(
                              width: 52,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          )
                        : const Text('Créer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: state.isLoading
                ? Shimmer.fromColors(
                    baseColor: AppColors.surface,
                    highlightColor: AppColors.surfaceAlt,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 6,
                      itemBuilder: (_, __) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        height: 74,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                : state.codes.isEmpty
                    ? const Center(
                        child: Text('Aucun code promo', style: TextStyle(color: AppColors.gris, fontSize: 15)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.codes.length,
                        itemBuilder: (context, index) {
                          final code = state.codes[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(code.code,
                                          style: TextStyle(
                                            color: code.isActive ? AppColors.blanc : AppColors.gris,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(
                                        '-${code.discountPercent}% · ${code.currentUses}${code.maxUses != null ? '/${code.maxUses}' : ''} utilisations',
                                        style: const TextStyle(color: AppColors.gris, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                if (code.isActive)
                                  Semantics(
                                    label: 'Désactiver code promo',
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.gris, size: 18),
                                      onPressed: () {
                                        ref.read(_promoListProvider.notifier).deactivate(code.id);
                                      },
                                      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Inactif',
                                        style: TextStyle(color: AppColors.gris, fontSize: 11)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppColors.blanc, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gris, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    try {
      final parts = value.split('-');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d, 23, 59, 59);
    } catch (_) {
      return null;
    }
  }
}
