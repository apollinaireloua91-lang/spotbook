/// POS error page — dimmed-accent surface after a failed tap.
///
/// Reached via `context.go('/pro/pos/error', extra: {...})` from
/// [PosReaderPage]. Per DS rules: never green, never red — the error
/// surface uses the "error" variant of the disc gradient (accent dimmed
/// to a deeper purple) plus a 70 % opacity wrapper. Copy is
/// sentence-case, no exclamation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spotbook_pos_theme.dart';
import '../../../../core/theme/spotbook_tokens.dart';
import '../../data/pos_notifier.dart';
import '../../domain/pos_models.dart';
import '../money_format.dart';
import '../widgets/reader_background.dart';

class PosErrorPage extends ConsumerWidget {
  const PosErrorPage({
    super.key,
    required this.amount,
    required this.result,
  });

  final PosAmount amount;
  final PosPaymentResult? result;

  /// Maps the [PosErrorCode] into a one-liner actionable message — keeps the
  /// DS rule "copy utile plutôt que `Error unknown`".
  static String _messageFor(PosErrorCode? code) {
    switch (code) {
      case PosErrorCode.permissionsDenied:
        return 'Autorisez l\u2019accès NFC dans les réglages du téléphone';
      case PosErrorCode.nfcDisabled:
        return 'Activez le NFC puis réessayez';
      case PosErrorCode.bluetoothDisabled:
        return 'Activez le Bluetooth puis réessayez';
      case PosErrorCode.cardDeclined:
        return 'Carte refusée — proposez un autre moyen';
      case PosErrorCode.timeout:
        return 'Délai dépassé — réapprochez la carte';
      case PosErrorCode.network:
        return 'Connexion interrompue — vérifiez le réseau';
      case PosErrorCode.stripeConnectNotReady:
        return 'Compte Stripe en attente — finalisez le rattachement';
      case PosErrorCode.unknown:
      case null:
        return 'Une erreur est survenue — réessayez';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = result?.errorCode;
    final detail = _messageFor(code);

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

                  // Dimmed error disc — no red, no green. Accent dimmed.
                  Opacity(
                    opacity: SpotbookReaderLayoutDs.errorDiscOpacity,
                    child: _ErrorDisc(),
                  ),

                  const SizedBox(height: SpotbookSpacingDs.s8),

                  const Text(
                    'Paiement non complété',
                    style: TextStyle(
                      fontFamily: SpotbookTypographyDs.fontFamily,
                      fontSize: SpotbookTypographyDs.textTitle,
                      fontWeight: SpotbookTypographyDs.weightBold,
                      color: SpotbookColorsDs.white,
                      letterSpacing: SpotbookTypographyDs.letterSpacingTitle,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpotbookSpacingDs.s3),
                  Text(
                    detail,
                    style: TextStyle(
                      fontFamily: SpotbookTypographyDs.fontFamily,
                      fontSize: SpotbookTypographyDs.textBodySm,
                      fontWeight: SpotbookTypographyDs.weightMedium,
                      color: SpotbookColorsDs.white.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpotbookSpacingDs.s3),
                  Text(
                    'Montant: ${formatCentsToCad(amount.totalCents)}',
                    style: TextStyle(
                      fontFamily: SpotbookTypographyDs.fontFamily,
                      fontSize: SpotbookTypographyDs.textCaption,
                      fontWeight: SpotbookTypographyDs.weightMedium,
                      color: SpotbookColorsDs.white.withValues(alpha: 0.48),
                      letterSpacing: 0.6,
                    ),
                  ),

                  const Spacer(),

                  // Primary — retry (keeps the same amount).
                  _PrimaryPill(
                    label: 'Réessayer',
                    onPressed: () {
                      ref.read(posPaymentProvider.notifier).reset();
                      context.go('/pro/pos/reader', extra: amount);
                    },
                  ),
                  const SizedBox(height: SpotbookSpacingDs.s3),

                  // Secondary — change the amount.
                  _SecondaryPill(
                    label: 'Modifier le montant',
                    onPressed: () {
                      ref.read(posPaymentProvider.notifier).reset();
                      context.go('/pro/pos/amount');
                    },
                  ),
                  const SizedBox(height: SpotbookSpacingDs.s3),

                  // Tertiary — bail out.
                  TextButton(
                    onPressed: () {
                      ref.read(posAmountProvider.notifier).clear();
                      ref.read(posPaymentProvider.notifier).reset();
                      context.go('/pro/dashboard');
                    },
                    child: Text(
                      'Retour au tableau de bord',
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

// ── Error disc ───────────────────────────────────────────────────────────

class _ErrorDisc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: SpotbookReaderLayoutDs.pulseDiscSize,
      height: SpotbookReaderLayoutDs.pulseDiscSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            SpotbookColorsDs.discErrorStart,
            SpotbookColorsDs.discErrorEnd,
          ],
          stops: [0.0, 1.0],
        ),
        // Medium glow — not the double-stack success glow.
        boxShadow: [SpotbookGlowsDs.medium],
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.priority_high_rounded,
        color: SpotbookColorsDs.white,
        size: SpotbookReaderLayoutDs.iconSizeBase,
      ),
    );
  }
}

// ── Pills (scoped to this page) ──────────────────────────────────────────

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
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
            boxShadow: const [SpotbookGlowsDs.medium],
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
    );
  }
}

class _SecondaryPill extends StatelessWidget {
  const _SecondaryPill({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
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
    );
  }
}
