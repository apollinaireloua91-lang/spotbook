/// Three-layer heartbeat animation that *is* the spotbook POS brand.
///
/// Fidelity port of `design_reference/.../ui_kits/pos/PulseNfcIndicator.jsx`
/// and `reader.css`:
///
/// - Layer 1 · Four sonar rings pulsing outward, phase-offset by 0.25, scale
///   0.6 → 2.5, opacity 0.8 → 0. Dropped on processing/success/error.
/// - Layer 2 · Main disc with radial gradient (+ NFC icon) pulsing on a
///   heartbeat (scale 1.0 → 1.08 → 1.0, 1200 ms).
/// - Layer 3 · Inner halo, counter-rhythm (0.5 → 1.2 scale, 800 ms) — the
///   asymmetry between outer (slow) and inner (fast) creates the organic
///   feel.
///
/// Every animated layer is wrapped in a [RepaintBoundary] to hit 60 fps on
/// mid-range Android hardware.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/spotbook_tokens.dart';
import '../../domain/pos_models.dart';
import '../reader_state_copy.dart';

class PulseNfcIndicator extends StatefulWidget {
  const PulseNfcIndicator({
    super.key,
    required this.state,
    this.size = 400,
  });

  final PosReaderState state;
  final double size;

  @override
  State<PulseNfcIndicator> createState() => _PulseNfcIndicatorState();
}

class _PulseNfcIndicatorState extends State<PulseNfcIndicator>
    with TickerProviderStateMixin {
  // Three controllers — one per motion layer.
  late final AnimationController _waveController;
  late final AnimationController _beatController;
  late final AnimationController _haloController;

  // Optional controllers spun up on demand for one-shot states.
  AnimationController? _finalWaveController;
  AnimationController? _shakeController;
  AnimationController? _successIconController;
  AnimationController? _spinnerController;
  AnimationController? _seekingController;

  ReaderVisualPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    final speed = speedMultiplierFor(widget.state);
    _waveController = AnimationController(
      vsync: this,
      duration: _scaled(SpotbookMotionDs.wave, speed),
    )..repeat();
    _beatController = AnimationController(
      vsync: this,
      duration: _scaled(SpotbookMotionDs.pulse, speed),
    )..repeat(reverse: true);
    _haloController = AnimationController(
      vsync: this,
      duration: _scaled(SpotbookMotionDs.halo, speed),
    )..repeat(reverse: true);

    _syncToState(initial: true);
  }

  @override
  void didUpdateWidget(covariant PulseNfcIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncToState();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _beatController.dispose();
    _haloController.dispose();
    _finalWaveController?.dispose();
    _shakeController?.dispose();
    _successIconController?.dispose();
    _spinnerController?.dispose();
    _seekingController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // State synchronization — wires the CSS `.state-*` rules to controllers.
  // ─────────────────────────────────────────────────────────────────────────

  void _syncToState({bool initial = false}) {
    final state = widget.state;
    final phase = visualPhaseFor(state);
    final speed = speedMultiplierFor(state);

    // Update durations when acceleration flips.
    _waveController.duration = _scaled(SpotbookMotionDs.wave, speed);
    _beatController.duration = _scaled(SpotbookMotionDs.pulse, speed);
    _haloController.duration = _scaled(SpotbookMotionDs.halo, speed);

    // Mount/stop sonar rings + heartbeat based on phase.
    final wantsSonar = shouldShowSonarRings(phase);
    if (wantsSonar && !_waveController.isAnimating) _waveController.repeat();
    if (!wantsSonar && _waveController.isAnimating) _waveController.stop();

    // Disc heartbeat is paused on success / error (matches CSS
    // `animation-play-state: paused`).
    final beatPaused =
        phase == ReaderVisualPhase.success || phase == ReaderVisualPhase.error;
    if (beatPaused && _beatController.isAnimating) _beatController.stop();
    if (!beatPaused && !_beatController.isAnimating) {
      _beatController.repeat(reverse: true);
    }

    // Halo counter-rhythm only runs while sonar runs.
    if (wantsSonar && !_haloController.isAnimating) {
      _haloController.repeat(reverse: true);
    }
    if (!wantsSonar && _haloController.isAnimating) _haloController.stop();

    // Seeking rotation — only in `collectingPaymentMethod`.
    if (phase == ReaderVisualPhase.seeking) {
      _seekingController ??= AnimationController(
        vsync: this,
        duration: SpotbookMotionDs.seeking,
      )..repeat(reverse: true);
    } else {
      _seekingController?.stop();
    }

    // Processing spinner.
    if (phase == ReaderVisualPhase.processing) {
      _spinnerController ??= AnimationController(
        vsync: this,
        duration: SpotbookMotionDs.spinner,
      )..repeat();
    } else if (_spinnerController != null &&
        _spinnerController!.isAnimating) {
      _spinnerController!.stop();
    }

    // One-shot celebrations / errors: only fire on transitions into those
    // phases to avoid re-firing on rebuild.
    if (!initial && phase != _lastPhase) {
      if (phase == ReaderVisualPhase.success) {
        _runFinalWave();
        _runSuccessIcon();
      } else if (phase == ReaderVisualPhase.error) {
        _runShake();
      }
    }

    _lastPhase = phase;
  }

  void _runFinalWave() {
    _finalWaveController?.dispose();
    _finalWaveController = AnimationController(
      vsync: this,
      duration: SpotbookMotionDs.finalWave,
    )..forward();
    _finalWaveController!.addListener(() {
      if (mounted) setState(() {});
    });
    _finalWaveController!.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() {});
    });
  }

  void _runShake() {
    _shakeController?.dispose();
    _shakeController = AnimationController(
      vsync: this,
      duration: SpotbookMotionDs.shakeTotal,
    )..forward();
    _shakeController!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _runSuccessIcon() {
    _successIconController?.dispose();
    _successIconController = AnimationController(
      vsync: this,
      duration: SpotbookMotionDs.iconSuccess,
    )..forward();
    _successIconController!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build.
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final phase = visualPhaseFor(widget.state);
    final showSonar = shouldShowSonarRings(phase);
    final showFinalWave = phase == ReaderVisualPhase.success &&
        _finalWaveController != null;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1 · Sonar rings (phase-offset).
          if (showSonar) ..._buildSonarRings(),

          // Final celebration wave on success.
          if (showFinalWave) _buildFinalWave(),

          // Shake wrapper → wraps halo + disc together (matches JSX).
          _buildShakenCore(phase),
        ],
      ),
    );
  }

  // ─── Layer 1 · Sonar rings ───────────────────────────────────────────────

  List<Widget> _buildSonarRings() {
    return SpotbookReaderLayoutDs.sonarPhases.map((phaseOffset) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            final t = (_waveController.value + phaseOffset) % 1.0;
            final scale = _lerp(
              SpotbookReaderLayoutDs.sonarScaleBegin,
              SpotbookReaderLayoutDs.sonarScaleEnd,
              SpotbookMotionDs.easeOutQuart.transform(t),
            );
            final opacity = _lerp(
              SpotbookReaderLayoutDs.sonarOpacityBegin,
              SpotbookReaderLayoutDs.sonarOpacityEnd,
              SpotbookMotionDs.easeInQuart.transform(t),
            );
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: SpotbookReaderLayoutDs.pulseDiscSize,
                  height: SpotbookReaderLayoutDs.pulseDiscSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpotbookColorsDs.accent08,
                    border: Border.all(
                      color: SpotbookColorsDs.accentDark,
                      width: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  // ─── Final celebration wave ──────────────────────────────────────────────

  Widget _buildFinalWave() {
    final controller = _finalWaveController!;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = SpotbookMotionDs.easeOutQuart.transform(controller.value);
          final scale = _lerp(
            SpotbookReaderLayoutDs.finalWaveScaleBegin,
            SpotbookReaderLayoutDs.finalWaveScaleEnd,
            t,
          );
          final opacity = _lerp(
            SpotbookReaderLayoutDs.finalWaveOpacityBegin,
            SpotbookReaderLayoutDs.finalWaveOpacityEnd,
            t,
          );
          return IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: SpotbookReaderLayoutDs.pulseDiscSize,
                  height: SpotbookReaderLayoutDs.pulseDiscSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        SpotbookColorsDs.accent60,
                        Color(0x008E05C2),
                      ],
                      stops: <double>[0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Layer 2+3 · disc + halo inside a shake wrapper ──────────────────────

  Widget _buildShakenCore(ReaderVisualPhase phase) {
    final shakeOffset = _shakeOffset();
    return Transform.translate(
      offset: Offset(shakeOffset, 0),
      child: SizedBox(
        width: SpotbookReaderLayoutDs.pulseDiscSize,
        height: SpotbookReaderLayoutDs.pulseDiscSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 3 · inner halo (counter-rhythm).
            if (phase != ReaderVisualPhase.success &&
                phase != ReaderVisualPhase.error)
              RepaintBoundary(child: _buildHalo()),

            // Layer 2 · disc + icon.
            RepaintBoundary(child: _buildDisc(phase)),
          ],
        ),
      ),
    );
  }

  double _shakeOffset() {
    final controller = _shakeController;
    if (controller == null || !controller.isAnimating) return 0;
    // 3 shake cycles of ±8px.
    final t = controller.value;
    // sin(2π × 3 × t) produces the 3-wave oscillation.
    final oscillation = math.sin(2 * math.pi * 3 * t);
    // Damp over time so the last shake is softer.
    final damp = 1.0 - t;
    return SpotbookReaderLayoutDs.shakeOffsetPx * oscillation * damp;
  }

  // ─── Halo ────────────────────────────────────────────────────────────────

  Widget _buildHalo() {
    return AnimatedBuilder(
      animation: _haloController,
      builder: (context, _) {
        final t = SpotbookMotionDs.easeInOutSine.transform(
          _haloController.value,
        );
        final scale = _lerp(
          SpotbookReaderLayoutDs.haloScaleBegin,
          SpotbookReaderLayoutDs.haloScaleEnd,
          t,
        );
        return Transform.scale(
          scale: scale,
          child: Container(
            width: SpotbookReaderLayoutDs.pulseHaloSize,
            height: SpotbookReaderLayoutDs.pulseHaloSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SpotbookColorsDs.accentDark,
              boxShadow: <BoxShadow>[SpotbookGlowsDs.medium],
            ),
          ),
        );
      },
    );
  }

  // ─── Disc (heartbeat + gradient variant + icon) ──────────────────────────

  Widget _buildDisc(ReaderVisualPhase phase) {
    final gradient = _discGradientFor(phase);
    final glow = phase == ReaderVisualPhase.success
        ? SpotbookGlowsDs.discSuccess
        : SpotbookGlowsDs.discDefault;
    final discOpacity = phase == ReaderVisualPhase.error
        ? SpotbookReaderLayoutDs.errorDiscOpacity
        : 1.0;

    return AnimatedBuilder(
      animation: _beatController,
      builder: (context, _) {
        final t = SpotbookMotionDs.easeInOutSine.transform(
          _beatController.value,
        );
        final beatScale = _lerp(
          SpotbookReaderLayoutDs.heartbeatScaleBegin,
          SpotbookReaderLayoutDs.heartbeatScaleEnd,
          t,
        );
        final scale = phase == ReaderVisualPhase.success ||
                phase == ReaderVisualPhase.error
            ? 1.0
            : beatScale;

        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: SpotbookMotionDs.base,
            curve: Curves.ease,
            width: SpotbookReaderLayoutDs.pulseDiscSize,
            height: SpotbookReaderLayoutDs.pulseDiscSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: glow,
            ),
            child: Opacity(
              opacity: discOpacity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (phase == ReaderVisualPhase.processing)
                    _ProcessingSpinner(controller: _spinnerController),
                  _buildIcon(phase),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Gradient _discGradientFor(ReaderVisualPhase phase) {
    switch (phase) {
      case ReaderVisualPhase.success:
        return const RadialGradient(
          colors: <Color>[
            SpotbookColorsDs.discSuccessStart,
            SpotbookColorsDs.discSuccessEnd,
          ],
        );
      case ReaderVisualPhase.error:
        return const RadialGradient(
          colors: <Color>[
            SpotbookColorsDs.discErrorStart,
            SpotbookColorsDs.discErrorEnd,
          ],
        );
      case ReaderVisualPhase.idle:
      case ReaderVisualPhase.seeking:
      case ReaderVisualPhase.reading:
      case ReaderVisualPhase.processing:
        return const RadialGradient(
          colors: <Color>[
            SpotbookColorsDs.discGradientStart,
            SpotbookColorsDs.discGradientEnd,
          ],
        );
    }
  }

  // ─── Icon ────────────────────────────────────────────────────────────────

  Widget _buildIcon(ReaderVisualPhase phase) {
    final icon = _iconFor(phase);
    final size = phase == ReaderVisualPhase.success
        ? SpotbookReaderLayoutDs.iconSizeSuccess
        : SpotbookReaderLayoutDs.iconSizeBase;

    Widget iconWidget = Icon(
      icon,
      color: SpotbookColorsDs.white,
      size: size,
    );

    // Success icon entrance — elastic-out, one-shot.
    if (phase == ReaderVisualPhase.success && _successIconController != null) {
      iconWidget = AnimatedBuilder(
        animation: _successIconController!,
        builder: (context, child) {
          final t = SpotbookMotionDs.easeElasticOut.transform(
            _successIconController!.value,
          );
          return Transform.scale(scale: t, child: child);
        },
        child: iconWidget,
      );
    }

    // Seeking idle sway for the contactless glyph.
    if (phase == ReaderVisualPhase.seeking && _seekingController != null) {
      iconWidget = AnimatedBuilder(
        animation: _seekingController!,
        builder: (context, child) {
          final t = _seekingController!.value; // 0..1..0 with reverse
          final angle = (t - 0.5) * 2 *
              SpotbookReaderLayoutDs.seekingRotationRadians;
          return Transform.rotate(angle: angle, child: child);
        },
        child: iconWidget,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.8, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<IconData>(icon),
        child: iconWidget,
      ),
    );
  }

  IconData _iconFor(ReaderVisualPhase phase) {
    switch (phase) {
      case ReaderVisualPhase.success:
        return Icons.check_rounded;
      case ReaderVisualPhase.error:
        return Icons.close_rounded;
      case ReaderVisualPhase.processing:
        // Icon still visible behind the spinner — keep the NFC glyph.
        return Icons.contactless_outlined;
      case ReaderVisualPhase.idle:
      case ReaderVisualPhase.seeking:
      case ReaderVisualPhase.reading:
        return Icons.contactless_outlined;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  double _lerp(double begin, double end, double t) => begin + (end - begin) * t;

  Duration _scaled(Duration base, double speed) {
    final micros = (base.inMicroseconds * speed).round();
    return Duration(microseconds: micros.clamp(1, 1 << 30));
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Processing spinner — a ~106° arc rotating at 900 ms / loop.
// ───────────────────────────────────────────────────────────────────────────

class _ProcessingSpinner extends StatelessWidget {
  const _ProcessingSpinner({required this.controller});

  final AnimationController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          return Transform.rotate(
            angle: c.value * 2 * math.pi,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: _SpinnerPainter(),
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  static const double _trackAlpha = 0.18;
  static const double _arcSweep = 40 / (40 + 85) * 2 * math.pi; // ~106°

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = SpotbookColorsDs.white.withValues(alpha: _trackAlpha);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = SpotbookColorsDs.white;
    canvas.drawArc(rect, -math.pi / 2, _arcSweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) => false;
}
