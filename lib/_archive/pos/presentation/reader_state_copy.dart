/// FR copy for each [PosReaderState], ported from `ReaderChrome.jsx`.
///
/// Maintained as a pure Dart constant so it can be `const` and cheap to read.
/// The full `PosReaderState` enum has more micro-phases than the JSX source
/// (`discoveringReaders`, `connectingReader`, `readerReady`,
/// `collectingPaymentMethod`, `canceled`). We map those to the closest design
/// copy — see `docs/SPOTBOOK_DS_FLUTTER_PORT.md` §6.
library;

import '../domain/pos_models.dart';

class ReaderStateCopy {
  const ReaderStateCopy({required this.title, this.subtitle});
  final String title;
  final String? subtitle;
}

const Map<PosReaderState, ReaderStateCopy> kReaderStateCopy = {
  PosReaderState.idle: ReaderStateCopy(title: 'Prêt à encaisser'),
  PosReaderState.initializing: ReaderStateCopy(title: 'Initialisation…'),
  PosReaderState.discoveringReaders:
      ReaderStateCopy(title: 'Prêt à encaisser'),
  PosReaderState.connectingReader:
      ReaderStateCopy(title: 'Prêt à encaisser'),
  PosReaderState.readerReady: ReaderStateCopy(title: 'Prêt à encaisser'),
  PosReaderState.collectingPaymentMethod: ReaderStateCopy(
    title: 'Approchez la carte du client',
    subtitle:
        'Ou présentez le téléphone du client au dos de votre iPhone',
  ),
  PosReaderState.processingPayment: ReaderStateCopy(
    title: 'Traitement du paiement',
    subtitle: 'Confirmation auprès de la banque',
  ),
  PosReaderState.succeeded: ReaderStateCopy(title: 'Paiement réussi'),
  PosReaderState.failed: ReaderStateCopy(
    title: 'Une erreur est survenue',
    subtitle: 'Carte non lue — réessayez',
  ),
  PosReaderState.canceled: ReaderStateCopy(title: 'Transaction annulée'),
};

/// Looks up the FR copy for a given reader state, with a safe default.
ReaderStateCopy copyFor(PosReaderState state) =>
    kReaderStateCopy[state] ??
    const ReaderStateCopy(title: 'Prêt à encaisser');

/// Broad category used by the pulse indicator to decide which motion layers
/// are active and which gradient variant to paint on the center disc.
enum ReaderVisualPhase { idle, seeking, reading, processing, success, error }

ReaderVisualPhase visualPhaseFor(PosReaderState state) {
  switch (state) {
    case PosReaderState.idle:
    case PosReaderState.initializing:
    case PosReaderState.discoveringReaders:
    case PosReaderState.connectingReader:
    case PosReaderState.readerReady:
      return ReaderVisualPhase.idle;
    case PosReaderState.collectingPaymentMethod:
      return ReaderVisualPhase.seeking;
    case PosReaderState.processingPayment:
      return ReaderVisualPhase.processing;
    case PosReaderState.succeeded:
      return ReaderVisualPhase.success;
    case PosReaderState.failed:
      return ReaderVisualPhase.error;
    case PosReaderState.canceled:
      return ReaderVisualPhase.idle;
  }
}

/// Returns the accelerated-speed multiplier for the given state. CSS reference:
/// `PulseNfcIndicator.jsx` → `speed = state === 'readingCard' ? 0.5 : 1`.
/// We treat `readerReady` + `collectingPaymentMethod` as the “reading/seeking”
/// phases where the rhythm doubles.
double speedMultiplierFor(PosReaderState state) {
  return state == PosReaderState.collectingPaymentMethod ? 0.5 : 1.0;
}

/// Returns true when the outer sonar rings should be mounted.
/// Dropped in processing / success / error to match CSS `.state-* { stopOuter }`.
bool shouldShowSonarRings(ReaderVisualPhase phase) {
  switch (phase) {
    case ReaderVisualPhase.idle:
    case ReaderVisualPhase.seeking:
    case ReaderVisualPhase.reading:
      return true;
    case ReaderVisualPhase.processing:
    case ReaderVisualPhase.success:
    case ReaderVisualPhase.error:
      return false;
  }
}
