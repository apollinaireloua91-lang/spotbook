import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
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

        // ── FCM token registration ──
        _registerFcmToken(ref);
      }
    }

    if (event == AuthChangeEvent.signedOut) {
      manager.dispose();
      debugPrint('[RealtimeBootstrap] disposed on sign-out');
    }
  });
});

/// Register FCM token with Supabase so Edge Functions can push.
Future<void> _registerFcmToken(Ref ref) async {
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await messaging.getToken();
      if (token != null) {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.saveFcmToken(token);
        debugPrint('[FCM] token registered');
      }
      // Auto-refresh on token change
      messaging.onTokenRefresh.listen((newToken) {
        ref.read(notificationRepositoryProvider).saveFcmToken(newToken);
        debugPrint('[FCM] token refreshed');
      });
    }
  } catch (e) {
    debugPrint('[FCM] registration error: $e');
  }
}
