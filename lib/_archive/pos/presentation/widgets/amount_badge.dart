/// Top-right amount pill on the reader screen.
///
/// Port of `ReaderChrome.jsx → AmountBadge`.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/spotbook_tokens.dart';
import '../money_format.dart';

class AmountBadge extends StatelessWidget {
  const AmountBadge({super.key, required this.totalCents});

  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final text = formatCentsToCad(totalCents);
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Montant à encaisser $text',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SpotbookColorsDs.accent15,
          borderRadius: BorderRadius.circular(SpotbookRadiiDs.lg),
          border: Border.all(
            color: SpotbookColorsDs.accent30,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpotbookSpacingDs.s4,
            vertical: SpotbookSpacingDs.s2,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: SpotbookTypographyDs.fontFamily,
              fontSize: SpotbookTypographyDs.textBadge,
              fontWeight: SpotbookTypographyDs.weightBold,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              letterSpacing: -0.18,
              height: 1,
              color: SpotbookColorsDs.accentDark,
            ),
          ),
        ),
      ),
    );
  }
}
