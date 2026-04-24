/// Animated title + subtitle block under the NFC disc.
/// Port of `ReaderChrome.jsx → ReaderStateIndicator` + CSS `@keyframes stateIn`.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/spotbook_tokens.dart';
import '../../domain/pos_models.dart';
import '../reader_state_copy.dart';

class ReaderStateIndicator extends StatelessWidget {
  const ReaderStateIndicator({super.key, required this.state});

  final PosReaderState state;

  @override
  Widget build(BuildContext context) {
    final copy = copyFor(state);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: SpotbookReaderLayoutDs.stateBlockMinHeight,
        maxWidth: SpotbookReaderLayoutDs.stateBlockMaxWidth,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpotbookReaderLayoutDs.stateBlockHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AnimatedTextSwap(
              keyValue: 'title-${copy.title}',
              style: const TextStyle(
                fontFamily: SpotbookTypographyDs.fontFamily,
                fontSize: SpotbookTypographyDs.textTitle,
                fontWeight: SpotbookTypographyDs.weightBold,
                letterSpacing: SpotbookTypographyDs.letterSpacingTitle,
                height: 1.15,
                color: SpotbookColorsDs.white,
              ),
              text: copy.title,
            ),
            if (copy.subtitle != null) ...[
              const SizedBox(height: SpotbookSpacingDs.s3),
              _AnimatedTextSwap(
                keyValue: 'sub-${copy.subtitle}',
                style: TextStyle(
                  fontFamily: SpotbookTypographyDs.fontFamily,
                  fontSize: SpotbookTypographyDs.textBodySm,
                  fontWeight: SpotbookTypographyDs.weightMedium,
                  height: SpotbookTypographyDs.lineHeightBody,
                  color: SpotbookColorsDs.white.withValues(
                    alpha: SpotbookReaderLayoutDs.subtitleOpacity,
                  ),
                ),
                text: copy.subtitle!,
                targetOpacity: SpotbookReaderLayoutDs.subtitleOpacity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Internal helper reproducing the CSS `@keyframes stateIn` — opacity 0 → end,
/// scale 0.95 → 1, 250 ms ease-out, keyed so `AnimatedSwitcher` replays the
/// entrance animation whenever the string changes.
class _AnimatedTextSwap extends StatelessWidget {
  const _AnimatedTextSwap({
    required this.keyValue,
    required this.text,
    required this.style,
    this.targetOpacity = 1.0,
  });

  final String keyValue;
  final String text;
  final TextStyle style;
  final double targetOpacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: SpotbookMotionDs.stateIn,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.95, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Opacity(
        key: ValueKey<String>(keyValue),
        opacity: targetOpacity,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: style.color),
        ),
      ),
    );
  }
}
