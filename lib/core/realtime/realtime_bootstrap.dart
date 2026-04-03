import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import 'realtime_manager.dart';

/// Watches the auth state stream and initialises / tears down the
/// [RealtimeManager] accordingly.
///
/// Must be "kept alive" for the entire app session — add it as an
/// eager watcher in the root widget:
///
/// ```dart
/// ref.watch(realtimeBootstrapProvider);
/// ```
final realtimeBootstrapProvider = Provider<void>((ref) {
  final authAsync = ref.watch(authStateProvider);

  authAsync.whenData((authState) {
    final manager = ref.read(realtimeManagerProvider);
    final event = authState.event;
    final user = authState.session?.user;

    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.initialSession) {
      if (user != null) {
        final role = user.userMetadata?['role'] as String? ?? 'client';
        manager.initialize(userId: user.id, role: role);
        debugPrint('[RealtimeBootstrap] init for ${user.id} ($role)');
      }
    }

    if (event == AuthChangeEvent.signedOut) {
      manager.dispose();
      debugPrint('[RealtimeBootstrap] disposed on sign-out');
    }
  });
});
