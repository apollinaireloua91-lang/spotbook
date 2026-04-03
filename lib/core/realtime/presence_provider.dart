import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'realtime_events.dart';
import 'realtime_manager.dart';

/// Exposes the set of currently online Pro IDs via Supabase Presence.
///
/// Usage in widgets:
/// ```dart
/// final isOnline = ref.watch(onlineProIdsProvider).contains(proId);
/// ```
class OnlineProIdsNotifier extends Notifier<Set<String>> {
  StreamSubscription<PresenceUpdated>? _sub;

  @override
  Set<String> build() {
    _sub = ref.read(realtimeManagerProvider).presenceStream.listen((event) {
      state = event.onlineProIds;
    });
    ref.onDispose(() => _sub?.cancel());
    return const {};
  }
}

final onlineProIdsProvider =
    NotifierProvider<OnlineProIdsNotifier, Set<String>>(
  OnlineProIdsNotifier.new,
);
