// The `TODO(post-crash)` markers below are intentional grep anchors — they
// enumerate every method that needs a real Stripe Terminal SDK binding once
// the iOS crash is resolved and the Apple capability approval lands. Keep
// them in the code (searchable via `grep -r "TODO(post-crash)"`) but silence
// the analyzer's `todo` lint so they don't pollute the Problems tab.
// ignore_for_file: todo

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pos_models.dart';

/// Abstraction over the Stripe Terminal SDK. The real implementation will
/// call into `mek_stripe_terminal` (see SPOTBOOK_POS_IMPLEMENTATION.md for
/// the SDK-choice rationale); for now this datasource is a stub that
/// throws [UnimplementedError] on every method so the rest of the feature
/// can be wired and analyzed without committing to the SDK while the iOS
/// crash is being debugged and the Apple capability approval is pending.
///
/// Swap the implementation by binding [posTerminalDataSourceProvider] to
/// `MekStripeTerminalDataSource` once the native integration is ready.
// TODO(post-crash): implement Stripe Terminal SDK integration via
// `mek_stripe_terminal` 4.6.x — see doc.
abstract class PosTerminalDataSource {
  /// Initializes the native SDK, configures the connection-token provider
  /// (which hits a Spotbook Edge Function to mint a token), and returns
  /// whether the SDK became ready.
  Future<bool> initialize();

  /// Requests the runtime permissions required by Tap to Pay: location
  /// (mandatory for Stripe fraud rules), NFC, and Bluetooth on Android.
  /// Returns false if any mandatory permission was denied.
  Future<bool> requestPermissions();

  /// Starts local-reader discovery in Tap to Pay mode (the phone itself
  /// acts as the reader — no external hardware). Emits [PosReaderState]
  /// transitions via [readerStateStream]. Completes when a local reader
  /// is ready, or throws on timeout / error.
  Future<void> discoverAndConnectLocalReader();

  /// Collects a payment method (user taps card / phone) for the given
  /// PaymentIntent client_secret, then confirms the PaymentIntent. The
  /// UI should subscribe to [readerStateStream] for status copy.
  ///
  /// Returns the [PosPaymentResult] once Stripe has processed the
  /// transaction (succeeded or failed).
  Future<PosPaymentResult> collectAndConfirm({
    required String clientSecret,
    required String transactionId,
  });

  /// Cancels any in-flight collection and resets the reader to idle.
  /// Safe to call at any time.
  Future<void> cancelCollection();

  /// Disconnects from the local reader and releases resources. Call when
  /// the POS flow is dismissed.
  Future<void> disconnect();

  /// Reactive state machine. UI binds to this for copy transitions.
  Stream<PosReaderState> get readerStateStream;
}

/// Stub implementation — every method throws [UnimplementedError] with a
/// `// TODO(post-crash): ...` marker so `grep -r "TODO(post-crash)"` can
/// enumerate what's left to wire up once the SDK is integrated.
class StubPosTerminalDataSource implements PosTerminalDataSource {
  @override
  Future<bool> initialize() {
    // TODO(post-crash): implement Stripe Terminal SDK integration
    throw UnimplementedError(
      'Stripe Terminal SDK not yet integrated. See '
      'docs/SPOTBOOK_POS_IMPLEMENTATION.md for the integration plan.',
    );
  }

  @override
  Future<bool> requestPermissions() {
    // TODO(post-crash): implement Stripe Terminal SDK integration
    throw UnimplementedError();
  }

  @override
  Future<void> discoverAndConnectLocalReader() {
    // TODO(post-crash): implement Stripe Terminal SDK integration
    throw UnimplementedError();
  }

  @override
  Future<PosPaymentResult> collectAndConfirm({
    required String clientSecret,
    required String transactionId,
  }) {
    // TODO(post-crash): implement Stripe Terminal SDK integration
    throw UnimplementedError();
  }

  @override
  Future<void> cancelCollection() {
    // TODO(post-crash): implement Stripe Terminal SDK integration
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect() {
    // TODO(post-crash): implement Stripe Terminal SDK integration
    throw UnimplementedError();
  }

  @override
  Stream<PosReaderState> get readerStateStream {
    // TODO(post-crash): implement Stripe Terminal SDK integration
    return const Stream<PosReaderState>.empty();
  }
}

/// Bound to [StubPosTerminalDataSource] until the SDK is wired. Swap the
/// override in `ProviderScope` (or in main.dart) once the real adapter
/// lands.
final posTerminalDataSourceProvider = Provider<PosTerminalDataSource>((ref) {
  return StubPosTerminalDataSource();
});
