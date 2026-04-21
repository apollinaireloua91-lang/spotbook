/// POS Tap to Pay reader page — the orchestrator.
///
/// Composition of the POS DS:
///   [ReaderBackground]               — full-screen dark radial gradient
///   Stack positioned chrome
///     top : [CloseIconButton] + [AmountBadge]
///     center column
///       [PulseNfcIndicator]
///       gap
///       [ReaderStateIndicator]
///     bottom : [CancelPillButton]
///
/// Lifecycle, in order:
///   1. `initState` ensures the Stripe Terminal SDK is ready.
///   2. On first frame, `posPaymentProvider.collect()` is fired with a
///      client-generated idempotency key.
///   3. Haptic feedback is dispatched on every state transition (mapping
///      per design spec — never a vibration burst on success to keep the
///      sensation "calme et confiant").
///   4. On `succeeded` → go to `/pro/pos/success`.
///      On `failed`    → go to `/pro/pos/error`.
///      On user-cancel / close → cancel the collection then pop.
///
/// Wrapped in [SpotbookPosThemeScope] so the scoped 3-color DS theme is
/// applied to this subtree only — legacy AppColors screens stay untouched.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spotbook_pos_theme.dart';
import '../../../../core/theme/spotbook_tokens.dart';
import '../../data/pos_notifier.dart';
import '../../domain/pos_models.dart';
import '../widgets/amount_badge.dart';
import '../widgets/cancel_button.dart';
import '../widgets/close_icon_button.dart';
import '../widgets/pulse_nfc_indicator.dart';
import '../widgets/reader_background.dart';
import '../widgets/reader_state_indicator.dart';

class PosReaderPage extends ConsumerStatefulWidget {
  const PosReaderPage({
    super.key,
    required this.amount,
    this.customerEmail,
    this.customerPhone,
  });

  /// Amount captured on the previous screen (`PosAmountPage`). Passed via
  /// `go_router` `extra` — always non-null by contract.
  final PosAmount amount;
  final String? customerEmail;
  final String? customerPhone;

  @override
  ConsumerState<PosReaderPage> createState() => _PosReaderPageState();
}

class _PosReaderPageState extends ConsumerState<PosReaderPage> {
  /// Idempotency key generated once per page lifetime. Ensures a retry
  /// (e.g. the Pro backs out and reopens) never double-charges.
  late final String _clientRequestId;

  /// Tracks the previously observed reader state so we dispatch haptic
  /// feedback only on transitions, not on rebuilds.
  PosReaderState _lastState = PosReaderState.idle;

  /// Guards against the double-navigation race where the provider emits
  /// `succeeded` / `failed` multiple times while the router transition is
  /// already in flight.
  bool _hasNavigatedAway = false;

  @override
  void initState() {
    super.initState();
    _clientRequestId =
        'pos-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(0x7fffffff).toRadixString(16)}';
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoff());
  }

  Future<void> _kickoff() async {
    // Terminal bootstrap (permissions + SDK init + local reader connect).
    // The notifier is idempotent — subsequent calls no-op once ready.
    final ready =
        await ref.read(posTerminalInitProvider.notifier).ensureReady();
    if (!mounted || !ready || _hasNavigatedAway) return;

    // Fire the actual Tap to Pay collection.
    await ref.read(posPaymentProvider.notifier).collect(
          amount: widget.amount,
          clientRequestId: _clientRequestId,
          customerEmail: widget.customerEmail,
          customerPhone: widget.customerPhone,
        );
  }

  /// Haptic mapping per state — mirrors `ReaderChrome.jsx` event hooks.
  /// Uses only native [HapticFeedback] primitives (no third-party plugins):
  ///   seeking     → selectionClick (a soft tick, once per phase entry)
  ///   reading     → lightImpact
  ///   processing  → (silent — let the spinner do the work)
  ///   success     → mediumImpact (calm, single tap — never a double buzz)
  ///   error       → heavyImpact (short, firm)
  void _fireHapticFor(PosReaderState newState) {
    switch (newState) {
      case PosReaderState.collectingPaymentMethod:
        HapticFeedback.selectionClick();
      case PosReaderState.readerReady:
        HapticFeedback.lightImpact();
      case PosReaderState.succeeded:
        HapticFeedback.mediumImpact();
      case PosReaderState.failed:
        HapticFeedback.heavyImpact();
      case PosReaderState.idle:
      case PosReaderState.initializing:
      case PosReaderState.discoveringReaders:
      case PosReaderState.connectingReader:
      case PosReaderState.processingPayment:
      case PosReaderState.canceled:
        // No haptic — these are "quiet" states by design.
        break;
    }
  }

  void _handleTerminalStateTransition(PosReaderState next) {
    if (next == _lastState) return;
    _fireHapticFor(next);
    _lastState = next;

    if (_hasNavigatedAway) return;

    if (next == PosReaderState.succeeded) {
      _hasNavigatedAway = true;
      final result = ref.read(posPaymentProvider).asData?.value.result;
      // Brief linger on the success state so the animation can resolve —
      // matches the CSS `finalWave` + `iconSuccess` 1100 ms budget.
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        context.go(
          '/pro/pos/success',
          extra: <String, Object?>{
            'amount': widget.amount,
            'result': result,
          },
        );
      });
    } else if (next == PosReaderState.failed) {
      _hasNavigatedAway = true;
      final result = ref.read(posPaymentProvider).asData?.value.result;
      // Slightly longer linger for error so the shake lands (1200 ms
      // heartbeat × ~1 cycle).
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        context.go(
          '/pro/pos/error',
          extra: <String, Object?>{
            'amount': widget.amount,
            'result': result,
          },
        );
      });
    }
  }

  Future<void> _cancel() async {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;
    await ref.read(posPaymentProvider.notifier).cancel();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pro/pos/amount');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Single source of truth for the reader's visible state. If the
    // Notifier is still [AsyncLoading] (rare — only between provider
    // initialization and the first `collect()` call), we treat it as
    // "idle" to keep the idle disc visible, never a spinner.
    final async = ref.watch(posPaymentProvider);
    final payment = async.asData?.value;
    final currentState = payment?.readerState ?? PosReaderState.idle;

    // Side-effects on state transitions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleTerminalStateTransition(currentState);
    });

    // The background is "active" (richer dark-purple gradient) as soon as
    // the reader has left the pure idle state — mirrors the CSS
    // `.sb-reader.is-active` class toggle.
    final isActive = currentState != PosReaderState.idle &&
        currentState != PosReaderState.initializing &&
        currentState != PosReaderState.canceled;

    return SpotbookPosThemeScope(
      child: Scaffold(
        backgroundColor: SpotbookColorsDs.black,
        body: ReaderBackground(
          active: isActive,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1 — center pulse + state copy.
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseNfcIndicator(state: currentState),
                    const SizedBox(
                      height: SpotbookReaderLayoutDs.discToStateGap,
                    ),
                    ReaderStateIndicator(state: currentState),
                  ],
                ),
              ),

              // Layer 2 — top chrome (close + amount).
              Positioned(
                top: SpotbookReaderLayoutDs.topOffset,
                left: SpotbookReaderLayoutDs.topHorizontalPadding,
                right: SpotbookReaderLayoutDs.topHorizontalPadding,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CloseIconButton(onTap: _cancel),
                      AmountBadge(totalCents: widget.amount.totalCents),
                    ],
                  ),
                ),
              ),

              // Layer 3 — bottom cancel pill. Disabled during commit phases.
              Positioned(
                bottom: SpotbookReaderLayoutDs.bottomOffset,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: CancelPillButton(
                      onPressed: _cancel,
                      disabled: _hasNavigatedAway ||
                          currentState == PosReaderState.processingPayment ||
                          currentState == PosReaderState.succeeded,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
