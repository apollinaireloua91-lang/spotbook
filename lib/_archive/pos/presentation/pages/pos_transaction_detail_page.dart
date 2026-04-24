/// POS transaction detail — breakdown + resend receipt + refund.
///
/// Reached from [PosHistoryPage] via `/pro/pos/transaction/:id`.
/// The Pro sees the full line-item breakdown (subtotal, tip, TPS, TVQ,
/// application fee, net), the original method (card brand + last4), and
/// has two affordances: Envoyer le reçu, Rembourser (full only for now —
/// partial amounts are a phase-2 addition on the same repo method).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spotbook_pos_theme.dart';
import '../../../../core/theme/spotbook_tokens.dart';
import '../../data/pos_notifier.dart';
import '../../data/pos_repository.dart';
import '../../domain/pos_models.dart';
import '../money_format.dart';
import '../widgets/close_icon_button.dart';

/// Fetches a single transaction by id. Kept as a FutureProvider.family so
/// list-side invalidation is cheap.
final posTransactionByIdProvider =
    FutureProvider.autoDispose.family<PosTransaction?, String>((ref, id) {
  return ref.read(posRepositoryProvider).getTransaction(id);
});

class PosTransactionDetailPage extends ConsumerStatefulWidget {
  const PosTransactionDetailPage({super.key, required this.transactionId});
  final String transactionId;

  @override
  ConsumerState<PosTransactionDetailPage> createState() =>
      _PosTransactionDetailPageState();
}

class _PosTransactionDetailPageState
    extends ConsumerState<PosTransactionDetailPage> {
  bool _sending = false;
  bool _refunding = false;
  String? _sendMessage;
  String? _refundMessage;

  Future<void> _sendReceipt() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _sendMessage = null;
    });
    try {
      final sent = await ref
          .read(posRepositoryProvider)
          .sendReceipt(transactionId: widget.transactionId);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendMessage = sent ? 'Reçu envoyé' : 'Aucun destinataire enregistré';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendMessage = 'Envoi impossible — réessayez';
      });
    }
  }

  Future<void> _refund(PosTransaction tx) async {
    if (_refunding) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _RefundConfirmDialog(amount: tx.amountTotalCents),
    );
    if (confirm != true) return;

    setState(() {
      _refunding = true;
      _refundMessage = null;
    });
    try {
      await ref
          .read(posRepositoryProvider)
          .refund(transactionId: tx.id);
      if (!mounted) return;
      setState(() {
        _refunding = false;
        _refundMessage = 'Remboursement effectué';
      });
      // Invalidate both the single row (so the body refreshes) and the
      // history list (so the row shows as "Remboursé" on the way back).
      ref.invalidate(posTransactionByIdProvider(widget.transactionId));
      ref.invalidate(posHistoryProvider);
    } on PosRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _refunding = false;
        _refundMessage = 'Refus: ${e.code}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _refunding = false;
        _refundMessage = 'Remboursement impossible — réessayez';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(posTransactionByIdProvider(widget.transactionId));

    return SpotbookPosThemeScope(
      child: Scaffold(
        backgroundColor: SpotbookColorsDs.black,
        body: SafeArea(
          child: async.when(
            data: (tx) => tx == null
                ? const _NotFound()
                : _Body(
                    tx: tx,
                    sending: _sending,
                    refunding: _refunding,
                    sendMessage: _sendMessage,
                    refundMessage: _refundMessage,
                    onSendReceipt: _sendReceipt,
                    onRefund: () => _refund(tx),
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: SpotbookColorsDs.accentDark,
              ),
            ),
            error: (e, _) => const _NotFound(),
          ),
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.tx,
    required this.sending,
    required this.refunding,
    required this.sendMessage,
    required this.refundMessage,
    required this.onSendReceipt,
    required this.onRefund,
  });

  final PosTransaction tx;
  final bool sending;
  final bool refunding;
  final String? sendMessage;
  final String? refundMessage;
  final VoidCallback onSendReceipt;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SpotbookSpacingDs.s5,
        SpotbookSpacingDs.s4,
        SpotbookSpacingDs.s5,
        SpotbookSpacingDs.s8,
      ),
      children: [
        // Header.
        Row(
          children: [
            CloseIconButton(onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/pro/pos/history');
              }
            }),
            const SizedBox(width: SpotbookSpacingDs.s4),
            const Expanded(
              child: Text(
                'Transaction',
                style: TextStyle(
                  fontFamily: SpotbookTypographyDs.fontFamily,
                  fontSize: SpotbookTypographyDs.textHeading,
                  fontWeight: SpotbookTypographyDs.weightBold,
                  color: SpotbookColorsDs.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: SpotbookSpacingDs.s6),

        // Hero amount.
        Center(
          child: Text(
            formatCentsToCad(tx.amountTotalCents),
            style: const TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textDisplay,
              fontWeight: SpotbookTypographyDs.weightBold,
              color: SpotbookColorsDs.white,
              letterSpacing: SpotbookTypographyDs.letterSpacingDisplay,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: SpotbookSpacingDs.s2),
        Center(
          child: Text(
            _statusLabel(tx.status),
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textBodySm,
              fontWeight: SpotbookTypographyDs.weightSemibold,
              color: tx.refundedAmountCents > 0
                  ? SpotbookColorsDs.white.withValues(alpha: 0.60)
                  : SpotbookColorsDs.accentDark,
            ),
          ),
        ),

        const SizedBox(height: SpotbookSpacingDs.s8),

        // Breakdown.
        _Row(label: 'Sous-total', value: formatCentsToCad(tx.amountSubtotalCents)),
        if (tx.tipCents > 0)
          _Row(label: 'Pourboire', value: formatCentsToCad(tx.tipCents)),
        if (tx.tpsCents > 0)
          _Row(label: 'TPS (5 %)', value: formatCentsToCad(tx.tpsCents)),
        if (tx.tvqCents > 0)
          _Row(label: 'TVQ (9,975 %)', value: formatCentsToCad(tx.tvqCents)),
        _Divider(),
        _Row(
          label: 'Total',
          value: formatCentsToCad(tx.amountTotalCents),
          emphasize: true,
        ),
        _Row(
          label: 'Frais Spotbook',
          value: '− ${formatCentsToCad(tx.applicationFeeCents)}',
          dim: true,
        ),
        _Row(
          label: 'Net pour vous',
          value: formatCentsToCad(tx.netToProCents),
          emphasize: true,
        ),
        if (tx.refundedAmountCents > 0) ...[
          const SizedBox(height: SpotbookSpacingDs.s2),
          _Row(
            label: 'Remboursé',
            value: formatCentsToCad(tx.refundedAmountCents),
            dim: true,
          ),
        ],

        const SizedBox(height: SpotbookSpacingDs.s6),

        // Payment method.
        if (tx.paymentMethodBrand != null && tx.paymentMethodLast4 != null)
          _Row(
            label: 'Méthode',
            value: '${tx.paymentMethodBrand} •••• ${tx.paymentMethodLast4}',
          ),
        _Row(
          label: 'Date',
          value: _formatDateTime(tx.createdAt),
        ),
        _Row(
          label: 'Référence',
          value: tx.stripePaymentIntentId,
          monospace: true,
        ),

        const SizedBox(height: SpotbookSpacingDs.s8),

        // Actions.
        _SecondaryPill(
          label: sending ? 'Envoi en cours…' : 'Envoyer le reçu',
          onPressed: sending ? null : onSendReceipt,
        ),
        if (sendMessage != null) ...[
          const SizedBox(height: SpotbookSpacingDs.s2),
          Text(
            sendMessage!,
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textCaption,
              color: SpotbookColorsDs.white.withValues(alpha: 0.70),
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: SpotbookSpacingDs.s3),

        if (tx.isRefundable)
          _DangerPill(
            label: refunding ? 'Remboursement en cours…' : 'Rembourser',
            onPressed: refunding ? null : onRefund,
          ),
        if (refundMessage != null) ...[
          const SizedBox(height: SpotbookSpacingDs.s2),
          Text(
            refundMessage!,
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textCaption,
              color: SpotbookColorsDs.white.withValues(alpha: 0.70),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ── Small building blocks ────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.dim = false,
    this.monospace = false,
  });
  final String label;
  final String value;
  final bool emphasize;
  final bool dim;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBodySm,
                fontWeight: emphasize
                    ? SpotbookTypographyDs.weightSemibold
                    : SpotbookTypographyDs.weightMedium,
                color: dim
                    ? SpotbookColorsDs.white.withValues(alpha: 0.55)
                    : SpotbookColorsDs.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: emphasize
                  ? SpotbookTypographyDs.textBody
                  : SpotbookTypographyDs.textBodySm,
              fontWeight: emphasize
                  ? SpotbookTypographyDs.weightBold
                  : SpotbookTypographyDs.weightMedium,
              color: dim
                  ? SpotbookColorsDs.white.withValues(alpha: 0.55)
                  : SpotbookColorsDs.white,
              fontFeatures: monospace
                  ? const [FontFeature.tabularFigures()]
                  : const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpotbookSpacingDs.s3),
      child: Container(
        height: 1,
        color: SpotbookColorsDs.borderDark,
      ),
    );
  }
}

class _SecondaryPill extends StatelessWidget {
  const _SecondaryPill({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(SpotbookRadiiDs.xl),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: SpotbookColorsDs.accent15,
              borderRadius: BorderRadius.circular(SpotbookRadiiDs.xl),
              border: Border.all(
                color: SpotbookColorsDs.accent30,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBody,
                fontWeight: SpotbookTypographyDs.weightSemibold,
                color: SpotbookColorsDs.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Danger" pill — per DS rules: NOT red. Uses a dimmed-accent outline
/// (accent60 border, no fill) to signal irreversibility without leaving
/// the 3-color palette.
class _DangerPill extends StatelessWidget {
  const _DangerPill({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(SpotbookRadiiDs.xl),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(SpotbookRadiiDs.xl),
              border: Border.all(
                color: SpotbookColorsDs.accent60,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBody,
                fontWeight: SpotbookTypographyDs.weightSemibold,
                color: SpotbookColorsDs.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Refund confirm dialog ────────────────────────────────────────────────

class _RefundConfirmDialog extends StatelessWidget {
  const _RefundConfirmDialog({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SpotbookColorsDs.accentDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SpotbookRadiiDs.lg),
      ),
      title: const Text(
        'Rembourser cette transaction ?',
        style: TextStyle(
          fontFamily: SpotbookTypographyDs.fontFamily,
          fontSize: SpotbookTypographyDs.textHeading,
          fontWeight: SpotbookTypographyDs.weightBold,
          color: SpotbookColorsDs.white,
        ),
      ),
      content: Text(
        'Le client sera remboursé de ${formatCentsToCad(amount)}. '
        'Cette action est irréversible.',
        style: TextStyle(
          fontFamily: SpotbookTypographyDs.fontFamily,
          fontSize: SpotbookTypographyDs.textBodySm,
          fontWeight: SpotbookTypographyDs.weightMedium,
          color: SpotbookColorsDs.white.withValues(alpha: 0.80),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Annuler',
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textBodySm,
              fontWeight: SpotbookTypographyDs.weightSemibold,
              color: SpotbookColorsDs.white.withValues(alpha: 0.80),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Confirmer',
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textBodySm,
              fontWeight: SpotbookTypographyDs.weightBold,
              color: SpotbookColorsDs.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Not-found fallback ───────────────────────────────────────────────────

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpotbookSpacingDs.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transaction introuvable',
              style: TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textHeading,
                fontWeight: SpotbookTypographyDs.weightBold,
                color: SpotbookColorsDs.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpotbookSpacingDs.s4),
            TextButton(
              onPressed: () => context.go('/pro/pos/history'),
              child: const Text(
                'Retour à l\u2019historique',
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

String _statusLabel(String s) => switch (s) {
      'succeeded' => 'Réussi',
      'partially_refunded' => 'Remboursé (partiel)',
      'refunded' => 'Remboursé',
      'failed' => 'Échec',
      'canceled' => 'Annulé',
      _ => s,
    };

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/$y · $h\u00a0h\u00a0$min';
}
