/// Top-left circular close button on the POS reader.
/// Port of `ReaderChrome.jsx → CloseButton`.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/spotbook_tokens.dart';

class CloseIconButton extends StatelessWidget {
  const CloseIconButton({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Fermer',
  });

  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: SpotbookReaderLayoutDs.closeButtonSize,
            height: SpotbookReaderLayoutDs.closeButtonSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
              border: Border.fromBorderSide(
                BorderSide(color: SpotbookColorsDs.borderDark, width: 1),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.close_rounded,
              color: SpotbookColorsDs.white,
              size: SpotbookReaderLayoutDs.iconSizeCloseGlyph,
            ),
          ),
        ),
      ),
    );
  }
}
