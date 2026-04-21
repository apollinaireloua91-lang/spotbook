/// POS history page — paginated list of the current Pro's transactions.
///
/// RLS on `pos_transactions` scopes to `pro_id = auth.uid()` — there is
/// no additional filter needed in the query. Sorted newest-first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spotbook_pos_theme.dart';
import '../../../../core/theme/spotbook_tokens.dart';
import '../../data/pos_notifier.dart';
import '../../domain/pos_models.dart';
import '../money_format.dart';
import '../widgets/close_icon_button.dart';

class PosHistoryPage extends ConsumerWidget {
  const PosHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(posHistoryProvider);

    return SpotbookPosThemeScope(
      child: Scaffold(
        backgroundColor: SpotbookColorsDs.black,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                onClose: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/pro/dashboard');
                  }
                },
                onRefresh: () =>
                    ref.read(posHistoryProvider.notifier).refresh(),
              ),
              Expanded(
                child: historyAsync.when(
                  data: (rows) => rows.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          color: SpotbookColorsDs.accentDark,
                          backgroundColor: SpotbookColorsDs.black,
                          onRefresh: () =>
                              ref.read(posHistoryProvider.notifier).refresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpotbookSpacingDs.s5,
                              vertical: SpotbookSpacingDs.s4,
                            ),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: SpotbookSpacingDs.s2),
                            itemBuilder: (context, i) => _TransactionRow(
                              tx: rows[i],
                              onTap: () => context.push(
                                '/pro/pos/transaction/${rows[i].id}',
                              ),
                            ),
                          ),
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: SpotbookColorsDs.accentDark,
                    ),
                  ),
                  error: (e, _) => _ErrorState(
                    onRetry: () =>
                        ref.read(posHistoryProvider.notifier).refresh(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onRefresh});
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpotbookSpacingDs.s5,
        SpotbookSpacingDs.s4,
        SpotbookSpacingDs.s5,
        SpotbookSpacingDs.s3,
      ),
      child: Row(
        children: [
          CloseIconButton(onTap: onClose),
          const SizedBox(width: SpotbookSpacingDs.s4),
          const Expanded(
            child: Text(
              'Historique',
              style: TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textHeading,
                fontWeight: SpotbookTypographyDs.weightBold,
                color: SpotbookColorsDs.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: SpotbookColorsDs.white,
            ),
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }
}

// ── Rows ─────────────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx, required this.onTap});
  final PosTransaction tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final refunded = tx.refundedAmountCents > 0;
    final statusLabel = switch (tx.status) {
      'succeeded' => 'Réussi',
      'partially_refunded' => 'Remboursé (partiel)',
      'refunded' => 'Remboursé',
      'failed' => 'Échec',
      'canceled' => 'Annulé',
      _ => tx.status,
    };

    return Material(
      color: SpotbookColorsDs.accent08,
      borderRadius: BorderRadius.circular(SpotbookRadiiDs.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SpotbookRadiiDs.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpotbookSpacingDs.s4,
            vertical: SpotbookSpacingDs.s4,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: SpotbookColorsDs.borderDark,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(SpotbookRadiiDs.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCentsToCad(tx.amountTotalCents),
                      style: const TextStyle(
                        fontFamily: SpotbookTypographyDs.fontFamily,
                        fontSize: SpotbookTypographyDs.textBody,
                        fontWeight: SpotbookTypographyDs.weightBold,
                        color: SpotbookColorsDs.white,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(tx.createdAt),
                      style: TextStyle(
                        fontFamily: SpotbookTypographyDs.fontFamily,
                        fontSize: SpotbookTypographyDs.textCaption,
                        fontWeight: SpotbookTypographyDs.weightMedium,
                        color:
                            SpotbookColorsDs.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: SpotbookTypographyDs.fontFamily,
                      fontSize: SpotbookTypographyDs.textCaption,
                      fontWeight: SpotbookTypographyDs.weightSemibold,
                      color: refunded
                          ? SpotbookColorsDs.white.withValues(alpha: 0.55)
                          : SpotbookColorsDs.accentDark,
                    ),
                  ),
                  if (tx.paymentMethodBrand != null &&
                      tx.paymentMethodLast4 != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${tx.paymentMethodBrand} •••• ${tx.paymentMethodLast4}',
                      style: TextStyle(
                        fontFamily: SpotbookTypographyDs.fontFamily,
                        fontSize: SpotbookTypographyDs.textCaption,
                        color:
                            SpotbookColorsDs.white.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/$y · $h\u00a0h\u00a0$min';
}

// ── Empty / error ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpotbookSpacingDs.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: SpotbookColorsDs.white.withValues(alpha: 0.32),
              size: 56,
            ),
            const SizedBox(height: SpotbookSpacingDs.s4),
            const Text(
              'Aucune transaction pour le moment',
              style: TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBody,
                fontWeight: SpotbookTypographyDs.weightSemibold,
                color: SpotbookColorsDs.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpotbookSpacingDs.s2),
            Text(
              'Vos encaissements Tap to Pay apparaîtront ici.',
              style: TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBodySm,
                fontWeight: SpotbookTypographyDs.weightMedium,
                color: SpotbookColorsDs.white.withValues(alpha: 0.55),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpotbookSpacingDs.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Impossible de charger l\u2019historique',
              style: TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBody,
                fontWeight: SpotbookTypographyDs.weightSemibold,
                color: SpotbookColorsDs.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpotbookSpacingDs.s4),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  fontFamily: SpotbookTypographyDs.fontFamily,
                  fontSize: SpotbookTypographyDs.textBodySm,
                  fontWeight: SpotbookTypographyDs.weightSemibold,
                  color: SpotbookColorsDs.accentDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
