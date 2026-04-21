/// Radial background gradient that morphs between idle and active variants.
///
/// Port of `.sb-reader` CSS — the transition [bg-idle] ⇄ [bg-active] is a 600 ms
/// `ease-standard` cross-fade between two RadialGradients.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/spotbook_tokens.dart';

/// Background surface for every POS reader-like screen (reader page, success,
/// error). Accepts an [active] flag controlling the gradient morph.
class ReaderBackground extends StatelessWidget {
  const ReaderBackground({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SpotbookMotionDs.backgroundMorph,
      curve: SpotbookMotionDs.easeStandard,
      decoration: BoxDecoration(
        color: SpotbookColorsDs.black,
        gradient: active ? _activeGradient : _idleGradient,
      ),
      child: child,
    );
  }

  // `radial-gradient(circle at 50% 48%, #3E065F 0%, #1A0230 38%, #050008 70%, #000 100%)`.
  static const RadialGradient _activeGradient = RadialGradient(
    center: Alignment(0, -0.04),
    radius: 0.95,
    colors: <Color>[
      SpotbookColorsDs.bgActiveCenter,
      SpotbookColorsDs.bgActiveMid1,
      SpotbookColorsDs.bgActiveMid2,
      SpotbookColorsDs.black,
    ],
    stops: <double>[0.0, 0.38, 0.70, 1.0],
  );

  // `radial-gradient(circle at 50% 50%, #1F0330 0%, #0A0115 45%, #000 100%)`.
  static const RadialGradient _idleGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.95,
    colors: <Color>[
      SpotbookColorsDs.bgIdleCenter,
      SpotbookColorsDs.bgIdleMid,
      SpotbookColorsDs.black,
    ],
    stops: <double>[0.0, 0.45, 1.0],
  );
}
