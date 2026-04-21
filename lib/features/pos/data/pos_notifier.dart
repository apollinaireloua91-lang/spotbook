import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pos_models.dart';
import 'pos_repository.dart';
import 'pos_terminal.dart';

// ── Amount input ─────────────────────────────────────────────────────────

/// Notifier driving the POS amount-entry screen. Holds the subtotal (cents)
/// and tip (cents) the Pro has typed; TPS / TVQ are derived automatically
/// via [PosAmount]'s getters and controlled by [PosAmount.applyTaxes].
class PosAmountNotifier extends Notifier<PosAmount> {
  @override
  PosAmount build() => const PosAmount();

  /// Appends a digit from the custom numeric keypad (Square-style).
  /// The value is interpreted as cents: "1" then "2" then "3" → 1,23 $.
  void appendDigit(int digit) {
    assert(digit >= 0 && digit <= 9, 'digit must be 0-9');
    final next = state.subtotalCents * 10 + digit;
    // Clamp to 7 figures = 99 999,99 $, keeps Stripe's hard ceiling in sight.
    if (next > 9999999) return;
    state = state.copyWith(subtotalCents: next);
  }

  /// Removes the last digit (backspace on the keypad).
  void backspace() {
    state = state.copyWith(subtotalCents: state.subtotalCents ~/ 10);
  }

  /// Clears the subtotal and tip entirely.
  void clear() {
    state = const PosAmount();
  }

  /// Sets a preset tip as a fraction of the subtotal (0.15 → 15 %).
  void setTipPercent(double pct) {
    final tip = (state.subtotalCents * pct).round();
    state = state.copyWith(tipCents: tip);
  }

  /// Sets a custom tip amount in cents (from the "Montant libre" field).
  void setTipCents(int cents) {
    state = state.copyWith(tipCents: cents < 0 ? 0 : cents);
  }

  void setApplyTaxes(bool value) {
    state = state.copyWith(applyTaxes: value);
  }
}

final posAmountProvider =
    NotifierProvider<PosAmountNotifier, PosAmount>(PosAmountNotifier.new);

// ── Terminal initialization ──────────────────────────────────────────────

/// Async bootstrap for the Stripe Terminal SDK (permissions → init →
/// discover local reader). The UI shows a spinner while the state is
/// loading and an error banner if it throws.
///
/// The first [build] returns `false` without side effects so we don't
/// surprise-initialise the SDK on app launch; the Pro-side POS entry
/// screen is responsible for calling [ensureReady].
class PosTerminalInitNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> ensureReady() async {
    if (state.asData?.value == true) return true;
    state = const AsyncLoading();
    try {
      final terminal = ref.read(posTerminalDataSourceProvider);
      final permsOk = await terminal.requestPermissions();
      if (!permsOk) {
        state = const AsyncData(false);
        return false;
      }
      final initOk = await terminal.initialize();
      if (!initOk) {
        state = const AsyncData(false);
        return false;
      }
      await terminal.discoverAndConnectLocalReader();
      state = const AsyncData(true);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final posTerminalInitProvider =
    AsyncNotifierProvider<PosTerminalInitNotifier, bool>(
  PosTerminalInitNotifier.new,
);

// ── Payment lifecycle ────────────────────────────────────────────────────

/// Snapshot of the current Tap to Pay collection: its reader state, the
/// transaction id (once the Edge Function returns), and the terminal
/// result (on success / failure).
class PosPaymentState {
  const PosPaymentState({
    this.readerState = PosReaderState.idle,
    this.transactionId,
    this.paymentIntentId,
    this.result,
  });

  final PosReaderState readerState;
  final String? transactionId;
  final String? paymentIntentId;
  final PosPaymentResult? result;

  PosPaymentState copyWith({
    PosReaderState? readerState,
    String? transactionId,
    String? paymentIntentId,
    PosPaymentResult? result,
  }) =>
      PosPaymentState(
        readerState: readerState ?? this.readerState,
        transactionId: transactionId ?? this.transactionId,
        paymentIntentId: paymentIntentId ?? this.paymentIntentId,
        result: result ?? this.result,
      );
}

/// Drives the "Encaisser" → "Approchez la carte" → "Succès" flow.
///
/// Calls the Edge Function first to reserve a PaymentIntent + pos_transactions
/// row, then hands the client_secret to the Terminal SDK for on-device
/// collection. Cancellation is routed through the SDK so the reader is
/// always left in a clean state even if the user backs out mid-flow.
class PosPaymentNotifier extends AsyncNotifier<PosPaymentState> {
  @override
  Future<PosPaymentState> build() async => const PosPaymentState();

  /// Starts a fresh Tap to Pay collection. [clientRequestId] must be a
  /// client-generated UUID v4 — it drives Stripe idempotency so a retry
  /// never double-charges.
  Future<void> collect({
    required PosAmount amount,
    required String clientRequestId,
    String? customerEmail,
    String? customerPhone,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. Reserve the PaymentIntent server-side.
      final repo = ref.read(posRepositoryProvider);
      final ref0 = await repo.createPaymentIntent(
        amountSubtotalCents: amount.subtotalCents,
        tipCents: amount.tipCents,
        tpsCents: amount.tpsCents,
        tvqCents: amount.tvqCents,
        clientRequestId: clientRequestId,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );

      state = AsyncData(PosPaymentState(
        readerState: PosReaderState.collectingPaymentMethod,
        transactionId: ref0.transactionId,
        paymentIntentId: ref0.paymentIntentId,
      ));

      // 2. Hand off to the Terminal SDK for the NFC tap.
      final terminal = ref.read(posTerminalDataSourceProvider);
      final result = await terminal.collectAndConfirm(
        clientSecret: ref0.clientSecret,
        transactionId: ref0.transactionId,
      );

      state = AsyncData(PosPaymentState(
        readerState: result.success
            ? PosReaderState.succeeded
            : PosReaderState.failed,
        transactionId: ref0.transactionId,
        paymentIntentId: ref0.paymentIntentId,
        result: result,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> cancel() async {
    try {
      await ref.read(posTerminalDataSourceProvider).cancelCollection();
    } finally {
      state = AsyncData(
        state.asData?.value.copyWith(readerState: PosReaderState.canceled) ??
            const PosPaymentState(readerState: PosReaderState.canceled),
      );
    }
  }

  void reset() {
    state = const AsyncData(PosPaymentState());
  }
}

final posPaymentProvider =
    AsyncNotifierProvider<PosPaymentNotifier, PosPaymentState>(
  PosPaymentNotifier.new,
);

// ── Transaction history ──────────────────────────────────────────────────

/// Paginated history for the current Pro. Autoscrolls newest-first.
class PosHistoryNotifier extends AsyncNotifier<List<PosTransaction>> {
  @override
  Future<List<PosTransaction>> build() {
    return ref.read(posRepositoryProvider).listTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(posRepositoryProvider).listTransactions(),
    );
  }
}

final posHistoryProvider =
    AsyncNotifierProvider<PosHistoryNotifier, List<PosTransaction>>(
  PosHistoryNotifier.new,
);

/// Today's totals for the Pro dashboard widget.
final posTodayTotalsProvider =
    FutureProvider.autoDispose<({int count, int netCents})>((ref) {
  return ref.read(posRepositoryProvider).todayTotals();
});
