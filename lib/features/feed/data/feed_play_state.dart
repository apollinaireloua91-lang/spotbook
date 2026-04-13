import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared play/pause state for the client feed.
///
/// Written by the persistent play/pause button in FeedScreen,
/// read by each VideoFeedItem to sync actual BetterPlayer playback.
class FeedPlayStateNotifier extends Notifier<bool> {
  @override
  bool build() => true; // starts playing

  void toggle() => state = !state;
  void set(bool playing) => state = playing;
}

final feedPlayStateProvider =
    NotifierProvider<FeedPlayStateNotifier, bool>(FeedPlayStateNotifier.new);
