/// POS amount-entry page — Square-style numeric keypad.
///
/// Flow: the Pro types the subtotal (cents), optionally picks a tip preset,
/// toggles TPS+TVQ, then taps "Encaisser" → routes to [PosReaderPage] with
/// the captured [PosAmount].
///
/// Visuals are scoped under [SpotbookPosThemeScope] so the strict DS applies.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spotbook_pos_theme.dart';
import '../../../../core/theme/spotbook_tokens.dart';
import '../../data/pos_notifier.dart';
import '../../domain/pos_models.dart';
import '../money_format.dart';
import '../widgets/close_icon_button.dart';

class PosAmountPage extends ConsumerWidget {
  const PosAmountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(posAmountProvider);
    final notifier = ref.read(posAmountProvider.notifier);

    return SpotbookPosThemeScope(
      child: Scaffold(
        backgroundColor: SpotbookColorsDs.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpotbookSpacingDs.s5,
              vertical: SpotbookSpacingDs.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: close + title.
                Row(
                  children: [
                    CloseIconButton(onTap: () {
                      notifier.clear();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/pro/dashboard');
                      }
                    }),
                    const SizedBox(width: SpotbookSpacingDs.s4),
                    const Expanded(
                      child: Text(
                        'Nouvelle transaction',
                        style: TextStyle(
                          fontFamily: SpotbookTypographyDs.fontFamily,
                          fontSize: SpotbookTypographyDs.textHeading,
                          fontWeight: SpotbookTypographyDs.weightBold,
                          color: SpotbookColorsDs.white,
                          letterSpacing: SpotbookTypographyDs.letterSpacingTitle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpotbookSpacingDs.s8),

                // Big amount display.
                _AmountDisplay(amount: amount),

                const SizedBox(height: SpotbookSpacingDs.s6),

                // Tip presets.
                _TipPresets(
                  amount: amount,
                  onPick: notifier.setTipPercent,
                ),

                const SizedBox(height: SpotbookSpacingDs.s4),

                // Tax toggle.
                _TaxToggle(
                  applyTaxes: amount.applyTaxes,
                  onChanged: notifier.setApplyTaxes,
                ),

                const Spacer(),

                // Numeric keypad.
                _NumericKeypad(
                  onDigit: notifier.appendDigit,
                  onBackspace: notifier.backspace,
                ),

                const SizedBox(height: SpotbookSpacingDs.s6),

                // Primary CTA.
                _EncaisserButton(
                  amount: amount,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/pro/pos/reader', extra: amount);
                  },
                ),
                const SizedBox(height: SpotbookSpacingDs.s4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Amount display ────────────────────────────────────────────────────────

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.amount});
  final PosAmount amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Sous-total',
          style: TextStyle(
            fontFamily: SpotbookTypographyDs.fontFamily,
            fontSize: SpotbookTypographyDs.textCaption,
            fontWeight: SpotbookTypographyDs.weightMedium,
            color: SpotbookColorsDs.white.withValues(alpha: 0.55),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: SpotbookSpacingDs.s2),
        Text(
          formatCentsToCad(amount.subtotalCents),
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
        if (amount.totalCents > amount.subtotalCents) ...[
          const SizedBox(height: SpotbookSpacingDs.s2),
          Text(
            'Total ${formatCentsToCad(amount.totalCents)}',
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textBodySm,
              fontWeight: SpotbookTypographyDs.weightSemibold,
              color: SpotbookColorsDs.accentDark,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tip presets ──────────────────────────────────────────────────────────

class _TipPresets extends StatelessWidget {
  const _TipPresets({required this.amount, required this.onPick});

  final PosAmount amount;
  final ValueChanged<double> onPick;

  static const List<({String label, double pct})> _presets = [
    (label: 'Aucun', pct: 0),
    (label: '15 %', pct: 0.15),
    (label: '18 %', pct: 0.18),
    (label: '20 %', pct: 0.20),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPct = amount.subtotalCents == 0
        ? 0.0
        : amount.tipCents / amount.subtotalCents;

    return Row(
      children: [
        for (final preset in _presets) ...[
          Expanded(
            child: _TipChip(
              label: preset.label,
              selected: (currentPct - preset.pct).abs() < 0.005,
              onTap: amount.subtotalCents == 0
                  ? null
                  : () => onPick(preset.pct),
            ),
          ),
          if (preset != _presets.last)
            const SizedBox(width: SpotbookSpacingDs.s2),
        ],
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: selected
            ? SpotbookColorsDs.accent15
            : SpotbookColorsDs.accent08,
        borderRadius: BorderRadius.circular(SpotbookRadiiDs.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SpotbookRadiiDs.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? SpotbookColorsDs.accentDark
                    : SpotbookColorsDs.borderDark,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(SpotbookRadiiDs.md),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: SpotbookTypographyDs.fontFamily,
                  fontSize: SpotbookTypographyDs.textBodySm,
                  fontWeight: selected
                      ? SpotbookTypographyDs.weightBold
                      : SpotbookTypographyDs.weightMedium,
                  color: selected
                      ? SpotbookColorsDs.accentDark
                      : SpotbookColorsDs.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tax toggle ───────────────────────────────────────────────────────────

class _TaxToggle extends StatelessWidget {
  const _TaxToggle({required this.applyTaxes, required this.onChanged});

  final bool applyTaxes;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Appliquer TPS + TVQ',
            style: TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textBodySm,
              fontWeight: SpotbookTypographyDs.weightMedium,
              color: SpotbookColorsDs.white.withValues(alpha: 0.80),
            ),
          ),
        ),
        Switch.adaptive(
          value: applyTaxes,
          activeThumbColor: SpotbookColorsDs.accentDark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Numeric keypad ───────────────────────────────────────────────────────

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    // 3×4 grid: 1-9, (0 centered), backspace.
    final rows = <List<_KeyDef>>[
      [_KeyDef.digit(1), _KeyDef.digit(2), _KeyDef.digit(3)],
      [_KeyDef.digit(4), _KeyDef.digit(5), _KeyDef.digit(6)],
      [_KeyDef.digit(7), _KeyDef.digit(8), _KeyDef.digit(9)],
      [const _KeyDef.blank(), _KeyDef.digit(0), const _KeyDef.backspace()],
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (final key in row) ...[
                Expanded(
                  child: _KeypadButton(
                    def: key,
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                  ),
                ),
                if (key != row.last)
                  const SizedBox(width: SpotbookSpacingDs.s3),
              ],
            ],
          ),
          if (row != rows.last) const SizedBox(height: SpotbookSpacingDs.s3),
        ],
      ],
    );
  }
}

class _KeyDef {
  const _KeyDef.digit(this.digit)
      : isBackspace = false,
        isBlank = false;
  const _KeyDef.backspace()
      : digit = null,
        isBackspace = true,
        isBlank = false;
  const _KeyDef.blank()
      : digit = null,
        isBackspace = false,
        isBlank = true;

  final int? digit;
  final bool isBackspace;
  final bool isBlank;
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.def,
    required this.onDigit,
    required this.onBackspace,
  });

  final _KeyDef def;
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    if (def.isBlank) {
      return const SizedBox(height: 56);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (def.isBackspace) {
            onBackspace();
          } else if (def.digit != null) {
            onDigit(def.digit!);
          }
        },
        borderRadius: BorderRadius.circular(SpotbookRadiiDs.md),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: def.isBackspace
              ? const Icon(
                  Icons.backspace_outlined,
                  color: SpotbookColorsDs.white,
                  size: 24,
                )
              : Text(
                  '${def.digit}',
                  style: const TextStyle(
                    fontFamily: SpotbookTypographyDs.fontFamily,
                    fontSize: 28,
                    fontWeight: SpotbookTypographyDs.weightSemibold,
                    color: SpotbookColorsDs.white,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Encaisser button ─────────────────────────────────────────────────────

class _EncaisserButton extends StatelessWidget {
  const _EncaisserButton({required this.amount, required this.onPressed});

  final PosAmount amount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = amount.isAboveStripeMinimum;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
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
              enabled
                  ? 'Encaisser ${formatCentsToCad(amount.totalCents)}'
                  : 'Montant minimum 0,50 \$',
              style: const TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textBody,
                fontWeight: SpotbookTypographyDs.weightBold,
                color: SpotbookColorsDs.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
