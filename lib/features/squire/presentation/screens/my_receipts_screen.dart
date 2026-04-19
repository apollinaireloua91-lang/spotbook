import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/squire_repository.dart';
import '../../domain/squire_models.dart';

/// Priority #12 — Client's digital receipt list.
/// Tap a receipt to see the full breakdown.
class MyReceiptsScreen extends ConsumerStatefulWidget {
  const MyReceiptsScreen({super.key});

  @override
  ConsumerState<MyReceiptsScreen> createState() => _MyReceiptsScreenState();
}

class _MyReceiptsScreenState extends ConsumerState<MyReceiptsScreen> {
  List<DigitalReceipt> _receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      final list = await repo.listMyReceipts();
      if (!mounted) return;
      setState(() {
        _receipts = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
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
        ),
        title: Text(
          'Mes reçus',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SpotbookLoadingShimmer.card(itemCount: 4),
            )
          : _receipts.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aucun reçu',
                  subtitle:
                      'Tes reçus de réservations complétées apparaîtront ici.',
                )
              : RefreshIndicator(
                  color: AppColors.violet,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: _receipts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _ReceiptCard(receipt: _receipts[i]),
                  ),
                ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});
  final DigitalReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return SpotbookCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_rounded,
                color: AppColors.violet, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.receiptNumber,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy · HH:mm', 'fr_FR')
                      .format(receipt.generatedAt.toLocal()),
                  style: GoogleFonts.dmSans(
                      color: AppColors.gris, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatAmount(receipt.totalDollars,
                currency: receipt.currency),
            style: GoogleFonts.sora(
              color: AppColors.violetClair,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: AppColors.gris, size: 20),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await _ReceiptDetailSheet.show(context, receipt);
            },
          ),
        ],
      ),
    );
  }
}

class _ReceiptDetailSheet extends StatelessWidget {
  const _ReceiptDetailSheet({required this.receipt});
  final DigitalReceipt receipt;

  static Future<void> show(BuildContext ctx, DigitalReceipt r) {
    return showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReceiptDetailSheet(receipt: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Reçu ${receipt.receiptNumber}',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMMM yyyy · HH:mm', 'fr_FR')
                .format(receipt.generatedAt.toLocal()),
            style: GoogleFonts.dmSans(
                color: AppColors.gris, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...receipt.lineItems.map((line) {
            final name = line['name']?.toString() ?? '—';
            final cents = (line['amount_cents'] as int?) ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.dmSans(
                          color: AppColors.blanc, fontSize: 14),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatAmount(cents / 100.0,
                        currency: receipt.currency),
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc, fontSize: 14),
                  ),
                ],
              ),
            );
          }),
          Divider(color: AppColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(receipt.totalDollars,
                    currency: receipt.currency),
                style: GoogleFonts.sora(
                  color: AppColors.violetClair,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
