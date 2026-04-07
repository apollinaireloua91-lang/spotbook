import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/promo_repository.dart';
import '../../domain/promo_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// STATE & NOTIFIER
// ═════════════════════════════════════════════════════════════════════════════

class _PromoListState {
  const _PromoListState(
      {this.codes = const [], this.isLoading = true, this.isCreating = false});
  final List<PromoCodeDetail> codes;
  final bool isLoading;
  final bool isCreating;
  _PromoListState copyWith(
          {List<PromoCodeDetail>? codes,
          bool? isLoading,
          bool? isCreating}) =>
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

final _promoListProvider =
    NotifierProvider<_PromoListNotifier, _PromoListState>(
  _PromoListNotifier.new,
  isAutoDispose: true,
);

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class CreatePromoCodeScreen extends ConsumerStatefulWidget {
  const CreatePromoCodeScreen({super.key});

  @override
  ConsumerState<CreatePromoCodeScreen> createState() =>
      _CreatePromoCodeScreenState();
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          'Promo Codes',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Create form ──
          _CreateFormSection(
            codeCtrl: _codeCtrl,
            discountCtrl: _discountCtrl,
            maxUsesCtrl: _maxUsesCtrl,
            expiresCtrl: _expiresCtrl,
            isCreating: state.isCreating,
            onSubmit: () => _handleCreate(),
          ),

          // ── Section header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Text(
                  'Your Codes',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!state.isLoading)
                  Text(
                    '${state.codes.length} total',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // ── Promo code list ──
          Expanded(
            child: state.isLoading
                ? _buildShimmerList()
                : state.codes.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: state.codes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) => _PromoCodeCard(
                          code: state.codes[index],
                          onDeactivate: () => ref
                              .read(_promoListProvider.notifier)
                              .deactivate(state.codes[index].id),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreate() async {
    HapticFeedback.mediumImpact();
    final code = _codeCtrl.text.trim();
    final discount = int.tryParse(_discountCtrl.text);
    if (code.isEmpty || discount == null || discount <= 0 || discount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Code and discount (1-100%) required',
            style: GoogleFonts.dmSans(),
          ),
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
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_outlined,
                color: AppColors.violet, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No promo codes yet',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first code above to attract customers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
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

// ═════════════════════════════════════════════════════════════════════════════
// CREATE FORM SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _CreateFormSection extends StatelessWidget {
  const _CreateFormSection({
    required this.codeCtrl,
    required this.discountCtrl,
    required this.maxUsesCtrl,
    required this.expiresCtrl,
    required this.isCreating,
    required this.onSubmit,
  });

  final TextEditingController codeCtrl;
  final TextEditingController discountCtrl;
  final TextEditingController maxUsesCtrl;
  final TextEditingController expiresCtrl;
  final bool isCreating;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline,
                    color: AppColors.violet, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'New Code',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Code field
          _PremiumField(
            label: 'CODE',
            controller: codeCtrl,
            hint: 'e.g. WELCOME20',
          ),
          const SizedBox(height: 12),

          // Discount + Max uses row
          Row(
            children: [
              Expanded(
                child: _PremiumField(
                  label: 'DISCOUNT %',
                  controller: discountCtrl,
                  hint: '20',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumField(
                  label: 'MAX USES',
                  controller: maxUsesCtrl,
                  hint: 'Unlimited',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Expiry field
          _PremiumField(
            label: 'EXPIRES (OPTIONAL)',
            controller: expiresCtrl,
            hint: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 18),

          // Create button
          GestureDetector(
            onTap: isCreating ? null : onSubmit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: isCreating ? null : AppColors.gradientAccent,
                color: isCreating ? AppColors.surfaceAlt : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isCreating
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.gris,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: AppColors.textOnPrimary,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Create Code',
                            style: GoogleFonts.sora(
                              color: AppColors.textOnPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM FIELD
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: AppColors.gris.withAlpha(120),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.violet, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROMO CODE CARD
// ═════════════════════════════════════════════════════════════════════════════

class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard({
    required this.code,
    required this.onDeactivate,
  });

  final PromoCodeDetail code;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Discount badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: code.isActive
                  ? AppColors.violet.withAlpha(12)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '-${code.discountPercent}%',
                style: GoogleFonts.sora(
                  color: code.isActive ? AppColors.violet : AppColors.gris,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Code name + usage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code.code,
                  style: GoogleFonts.dmSans(
                    color: code.isActive ? AppColors.blanc : AppColors.gris,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${code.currentUses}${code.maxUses != null ? ' / ${code.maxUses}' : ''} uses',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Status / action
          if (code.isActive)
            Semantics(
              label: 'Deactivate promo code',
              child: GestureDetector(
                onTap: onDeactivate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Deactivate',
                    style: GoogleFonts.dmSans(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Inactive',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
