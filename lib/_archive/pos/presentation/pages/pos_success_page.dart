/// POS success page — the confirmation surface after a successful tap.
///
/// Reached via `context.go('/pro/pos/success', extra: {...})` from
/// [PosReaderPage]. Displays the brand's "paiement réussi" celebration,
/// the amount, optional card info, and three CTAs: Envoyer le reçu,
/// Nouvelle transaction, Historique.
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
import '../widgets/reader_background.dart';

class PosSuccessPage extends ConsumerStatefulWidget {
  const PosSuccessPage({
    super.key,
    required this.amount,
    required this.result,
  });

  final PosAmount amount;
  final PosPaymentResult? result;

  @override
  ConsumerState<PosSuccessPage> createState() => _PosSuccessPageState();
}

class _PosSuccessPageState extends ConsumerState<PosSuccessPage> {
  bool _receiptSending = false;
  bool _receiptSent = false;
  String? _receiptError;

  Future<void> _sendReceipt() async {
    final txId = widget.result?.transactionId;
    if (txId == null || _receiptSending) return;
    setState(() {
      _receiptSending = true;
      _receiptError = null;
    });
    try {
      // Reuse whatever channel the repository decides — the Edge Function
      // picks SMS vs email based on what's stored on the transaction row.
      await ref.read(posRepositoryProvider).sendReceipt(transactionId: txId);
      if (!mounted) return;
      setState(() {
        _receiptSending = false;
        _receiptSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _receiptSending = false;
        _receiptError = 'Envoi impossible — réessayez';
      });
    }
  }

  void _newTransaction() {
    ref.read(posAmountProvider.notifier).clear();
    ref.read(posPaymentProvider.notifier).reset();
    context.go('/pro/pos/amount');
  }

  void _viewHistory() {
    ref.read(posPaymentProvider.notifier).reset();
    context.go('/pro/pos/history');
  }

  @override
  Widget build(BuildContext context) {
    final cardBrand = widget.result?.cardBrand;
    final cardLast4 = widget.result?.cardLast4;

    return SpotbookPosThemeScope(
      child: Scaffold(
        backgroundColor: SpotbookColorsDs.black,
        body: ReaderBackground(
          active: true,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpotbookSpacingDs.s6,
                vertical: SpotbookSpacingDs.s4,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  // Celebration disc — success gradient + double-stack glow.
                  _SuccessDisc(),

                  const SizedBox(height: SpotbookSpacingDs.s8),

                  const Text(
                    'Paiement réussi',
                    style: TextStyle(
                      fontFamily: SpotbookTypographyDs.fontFamily,
                      fontSize: SpotbookTypographyDs.textTitle,
                      fontWeight: SpotbookTypographyDs.weightBold,
                      color: SpotbookColorsDs.white,
                      letterSpacing: SpotbookTypographyDs.letterSpacingTitle,
                    ),
                  ),
                  const SizedBox(height: SpotbookSpacingDs.s3),
                  Text(
                    formatCentsToCad(widget.amount.totalCents),
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
                  if (cardBrand != null && cardLast4 != null) ...[
                    const SizedBox(height: SpotbookSpacingDs.s3),
                    Text(
                      '$cardBrand •••• $cardLast4',
                      style: TextStyle(
                        fontFamily: SpotbookTypographyDs.fontFamily,
                        fontSize: SpotbookTypographyDs.textBodySm,
                        fontWeight: SpotbookTypographyDs.weightMedium,
                        color: SpotbookColorsDs.white.withValues(alpha: 0.60),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Receipt CTA (secondary).
                  _SecondaryPill(
                    label: _receiptSent
                        ? 'Reçu envoyé'
                        : _receiptSending
                            ? 'Envoi en cours…'
                            : 'Envoyer le reçu',
                    onPressed: _receiptSent || _receiptSending
                        ? null
                        : _sendReceipt,
                  ),
                  if (_receiptError != null) ...[
                    const SizedBox(height: SpotbookSpacingDs.s2),
                    Text(
                      _receiptError!,
                      style: TextStyle(
                        fontFamily: SpotbookTypographyDs.fontFamily,
                        fontSize: SpotbookTypographyDs.textCaption,
                        color: SpotbookColorsDs.accentDark
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  const SizedBox(height: SpotbookSpacingDs.s3),

                  // Primary CTA — new transaction.
                  _PrimaryPill(
                    label: 'Nouvelle transaction',
                    onPressed: _newTransaction,
                  ),
                  const SizedBox(height: SpotbookSpacingDs.s3),

                  // Tertiary — history.
                  TextButton(
                    onPressed: _viewHistory,
                    child: Text(
                      'Voir l\u2019historique',
                      style: TextStyle(
                        fontFamily: SpotbookTypographyDs.fontFamily,
                        fontSize: SpotbookTypographyDs.textBodySm,
                        fontWeight: SpotbookTypographyDs.weightMedium,
                        color: SpotbookColorsDs.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                  const SizedBox(height: SpotbookSpacingDs.s2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Success disc ─────────────────────────────────────────────────────────

class _SuccessDisc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: SpotbookReaderLayoutDs.pulseDiscSize,
      height: SpotbookReaderLayoutDs.pulseDiscSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            SpotbookColorsDs.discSuccessStart,
            SpotbookColorsDs.discSuccessEnd,
          ],
          stops: [0.0, 1.0],
        ),
        boxShadow: SpotbookGlowsDs.discSuccess,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check_rounded,
        color: SpotbookColorsDs.white,
        size: SpotbookReaderLayoutDs.iconSizeSuccess,
      ),
    );
  }
}

// ── Pill buttons (scoped, reusable) ──────────────────────────────────────

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({required this.label, required this.onPressed});
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
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SpotbookColorsDs.accentDeep,
                  SpotbookColorsDs.accentDark,
                ],
              ),
              borderRadius: BorderRadius.circular(SpotbookRadiiDs.xl),
              boxShadow: enabled ? const [SpotbookGlowsDs.medium] : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBody,
                fontWeight: SpotbookTypographyDs.weightBold,
                color: SpotbookColorsDs.white,
              ),
            ),
          ),
        ),
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
      opacity: enabled ? 1.0 : 0.50,
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
