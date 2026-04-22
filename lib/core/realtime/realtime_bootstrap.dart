import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import 'realtime_manager.dart';

/// Subscription sur FCM `onTokenRefresh`. Doit être installée UNE SEULE FOIS
/// pour toute la durée de vie de l'app — sinon chaque auth event
/// (`signedIn`, `tokenRefreshed`, `userUpdated`, `initialSession`) rajoute
/// un listener supplémentaire, et chaque rotation FCM déclenche alors N
/// `saveFcmToken` concurrents (race sur le row `users`).
StreamSubscription<String>? _fcmRefreshSub;

/// Observer `AppLifecycleListener` installé une seule fois. iOS suspend les
/// WebSockets Supabase quand l'app est en background > ~30 s — au retour
/// foreground, les channels sont « zombies » : abonnés côté client, morts
/// côté serveur. `tokenRefreshed` ne suffit pas toujours à remettre tout en
/// route. On force une resouscription sur `AppLifecycleState.resumed`.
AppLifecycleListener? _lifecycleListener;

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
  // Hook de reconnexion post-background — installé une seule fois. On ne
  // cherche pas à prédire si Supabase a perdu le lien : on demande au
  // RealtimeManager de retisser les channels si une session existe encore.
  // Le manager est idempotent (no-op si non initialisé ni logged in).
  if (_lifecycleListener == null) {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        final manager = ref.read(realtimeManagerProvider);
        manager.reconnect();
      },
    );
    ref.onDispose(() {
      _lifecycleListener?.dispose();
      _lifecycleListener = null;
    });
  }

  final authAsync = ref.watch(authStateProvider);

  authAsync.whenData((authState) async {
    final manager = ref.read(realtimeManagerProvider);
    final event = authState.event;
    final user = authState.session?.user;

    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.userUpdated ||
        event == AuthChangeEvent.initialSession) {
      if (user != null) {
        // Self-heal : si le trigger DB `on_auth_user_created` a échoué
        // silencieusement au signup (row absente de public.users),
        // toute insertion avec FK → users cassera (events, bookings...).
        // On tente une insertion idempotente AVANT le fetch de role, pour
        // qu'il trouve une row valide si elle manquait.
        await ref.read(authRepositoryProvider).ensurePublicUserRow();

        // Fetch role from public.users (authoritative).
        // user.userMetadata['role'] is unreliable: not populated on Google
        // OAuth sign-ins, and is editable by the user anyway (security best
        // practice: never base authorization on user_metadata).
        final role = await _fetchUserRole(user.id);
        if (role == null) {
          debugPrint('[RealtimeBootstrap] role not set yet for ${user.id} — '
              'skipping realtime init (awaits RoleSelectionScreen → '
              'realtimeRoleRefreshProvider)');
        } else {
          manager.reinitializeForRole(userId: user.id, role: role);
          debugPrint('[RealtimeBootstrap] init for ${user.id} ($role)');
        }

        // ── FCM token registration ──
        _registerFcmToken(ref);
      }
    }

    if (event == AuthChangeEvent.signedOut) {
      // Soft teardown: removes every channel and resets the session
      // pointers, but keeps the typed StreamControllers alive so listeners
      // survive a sign-out → sign-in cycle in the same app instance.
      // Full `dispose()` (closing controllers) only runs when the provider
      // itself is disposed (container-level).
      manager.tearDown();
      debugPrint('[RealtimeBootstrap] torn down on sign-out');
    }
  });

  // Expose a manual refresh hook so screens that change the role (e.g.
  // RoleSelectionScreen / CompleteProfileScreen) can force a re-init without
  // waiting for the next auth event.
  ref.listen<int>(realtimeRoleRefreshProvider, (_, __) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final role = await _fetchUserRole(user.id);
    if (role == null) return;
    ref.read(realtimeManagerProvider).reinitializeForRole(
          userId: user.id,
          role: role,
        );
    debugPrint('[RealtimeBootstrap] manual refresh → $role');
  });
});

/// Trigger this notifier to force the bootstrap to re-read
/// `public.users.role` and re-subscribe realtime channels. Call from screens
/// that mutate the current user's role (RoleSelectionScreen, admin upgrades).
///
/// Usage: `ref.read(realtimeRoleRefreshProvider.notifier).trigger();`
final realtimeRoleRefreshProvider =
    NotifierProvider<_RoleRefreshNotifier, int>(_RoleRefreshNotifier.new);

class _RoleRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void trigger() => state = state + 1;
}

Future<String?> _fetchUserRole(String userId) async {
  try {
    final row = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return row?['role'] as String?;
  } catch (e) {
    debugPrint('[RealtimeBootstrap] fetch role failed: $e');
    return null;
  }
}

/// Register FCM token with Supabase so Edge Functions can push.
///
/// Appelé depuis `authAsync.whenData` → ré-invoqué à chaque auth event
/// (`signedIn`, `tokenRefreshed`, etc.). Le `requestPermission` + `getToken`
/// sont cheap sur iOS une fois l'autorisation accordée (valeurs cachées).
/// En revanche `onTokenRefresh.listen` N'EST INSTALLÉ QU'UNE FOIS via
/// `_fcmRefreshSub` — sans cette garde, après N logins/refreshes il y
/// aurait N listeners qui sauvent tous le même token en concurrence.
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
      // Auto-refresh on token change — UNE SEULE souscription pour toute
      // la durée de vie du provider. Si on réinstallait sans cancel, chaque
      // login empilerait un listener supplémentaire.
      if (_fcmRefreshSub == null) {
        _fcmRefreshSub = messaging.onTokenRefresh.listen((newToken) {
          ref.read(notificationRepositoryProvider).saveFcmToken(newToken);
          debugPrint('[FCM] token refreshed');
        });
        ref.onDispose(() {
          _fcmRefreshSub?.cancel();
          _fcmRefreshSub = null;
        });
      }
    }
  } catch (e) {
    debugPrint('[FCM] registration error: $e');
  }
}
