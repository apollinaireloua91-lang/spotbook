/// Outlined pill bottom — "Annuler".
/// Port of `ReaderChrome.jsx → CancelButton`.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/spotbook_tokens.dart';

class CancelPillButton extends StatefulWidget {
  const CancelPillButton({
    super.key,
    required this.onPressed,
    this.disabled = false,
    this.label = 'Annuler',
  });

  final VoidCallback onPressed;
  final bool disabled;
  final String label;

  @override
  State<CancelPillButton> createState() => _CancelPillButtonState();
}

class _CancelPillButtonState extends State<CancelPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed && !widget.disabled ? 0.98 : 1.0;
    final opacity = widget.disabled ? 0.4 : 1.0;

    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: 'Annuler la transaction',
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTapDown: widget.disabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapUp: widget.disabled
              ? null
              : (_) {
                  setState(() => _pressed = false);
                  widget.onPressed();
                },
          onTapCancel: widget.disabled
              ? null
              : () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpotbookSpacingDs.s6,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(SpotbookRadiiDs.xl),
                border: Border.all(
                  color: SpotbookColorsDs.accentDark,
                  width: 1.5,
                ),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: SpotbookTypographyDs.fontFamily,
                  fontSize: SpotbookTypographyDs.textBodySm,
                  fontWeight: SpotbookTypographyDs.weightSemibold,
                  color: SpotbookColorsDs.accentDark,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
