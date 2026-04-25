import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart' show rootScaffoldMessengerKey;
import '../theme/app_colors.dart';

/// Branche les handlers FCM pour les messages reçus en foreground,
/// au tap depuis le background, et au cold start (via [getInitialMessage]).
///
/// Cycle de vie
/// ────────────
/// Instancié UNE SEULE FOIS depuis `realtime_bootstrap._registerFcmToken`
/// après l'enregistrement du token FCM. Re-appeler `wireHandlers()` ne
/// double pas les listeners (idempotent — guard via `_subs`).
///
/// L'enregistrement du token (`requestPermission` + `getToken` +
/// `onTokenRefresh`) est géré séparément par `realtime_bootstrap` afin
/// d'éviter les listeners en double — ne PAS le ré-implémenter ici.
///
/// Réception
/// ─────────
/// - **foreground** : poste un `MaterialBanner` non-bloquant via le
///   `rootScaffoldMessengerKey` global, avec CTA « Voir le message »
///   qui appelle [handleTap] sur la même `RemoteMessage`.
/// - **background tap** : `onMessageOpenedApp` → [handleTap] qui
///   navigue selon `data['route']` reçu du trigger PostgreSQL
///   (cf. `tr_notify_new_message_push` : `/pro/messages` ou
///   `/client/messages` selon `users.role` du destinataire).
/// - **cold start** : `getInitialMessage()` → [handleTap].
///
/// La route est CONSOMMÉE telle quelle depuis `data['route']` ; aucune
/// dérivation côté client → la source de vérité reste le trigger DB.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _initialMessageChecked = false;
  GoRouter? _router;

  /// Branche les 3 handlers FCM. Idempotent.
  ///
  /// Le [router] est injecté depuis `realtime_bootstrap` via
  /// `ref.read(goRouterProvider)`. Stocké comme champ pour que [handleTap]
  /// (appelé hors `BuildContext` depuis un listener FCM) puisse naviguer
  /// sans dépendre d'un global.
  void wireHandlers(GoRouter router) {
    _router ??= router;
    _foregroundSub ??= FirebaseMessaging.onMessage.listen(_showBanner);
    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(handleTap);

    if (!_initialMessageChecked) {
      _initialMessageChecked = true;
      FirebaseMessaging.instance.getInitialMessage().then((m) {
        if (m != null) handleTap(m);
      });
    }
  }

  /// À appeler depuis `ref.onDispose` côté bootstrap.
  void dispose() {
    _foregroundSub?.cancel();
    _foregroundSub = null;
    _openedSub?.cancel();
    _openedSub = null;
    _initialMessageChecked = false;
    _router = null;
  }

  // ─── Foreground UX ──────────────────────────────────────────────

  void _showBanner(RemoteMessage message) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) {
      // ScaffoldMessenger pas encore monté (cold start ?). On laisse
      // tomber — le push sera dans la table notifications de toute
      // façon, l'utilisateur le verra dans son inbox.
      return;
    }

    final title = message.notification?.title ?? 'Spotbook';
    final body = message.notification?.body ?? '';
    final hasRoute = (message.data['route'] as String?)?.isNotEmpty ?? false;

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.surface,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.notifications_rounded,
              color: AppColors.violet, size: 20),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.blanc,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.gris,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(
              'Ignorer',
              style: TextStyle(color: AppColors.gris, fontSize: 13),
            ),
          ),
          if (hasRoute)
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                handleTap(message);
              },
              child: Text(
                'Voir le message',
                style: TextStyle(
                  color: AppColors.violet,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );

    // Auto-dismiss après 6 secondes (UX WhatsApp/Instagram).
    Future.delayed(const Duration(seconds: 6), () {
      messenger.hideCurrentMaterialBanner();
    });
  }

  // ─── Tap navigation ─────────────────────────────────────────────

  /// Navigue selon `data['route']` du payload FCM, ou fallback inbox.
  ///
  /// La route est SET par le trigger DB (cf. migration
  /// `20260424120000_fix_push_notification_route_per_role.sql`) en
  /// fonction de `users.role` du destinataire. Le client se contente
  /// de la consommer.
  void handleTap(RemoteMessage message) {
    final router = _router;
    if (router == null) {
      // wireHandlers() pas encore appelé — anomalie (push reçu avant que
      // le bootstrap n'ait injecté le GoRouter). On laisse tomber : la
      // notif est déjà persistée en DB, l'user la verra dans son inbox.
      debugPrint('[Push] handleTap called before wireHandlers — ignored');
      return;
    }
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      try {
        router.go(route);
      } catch (e) {
        debugPrint('[Push] navigation failed for "$route": $e');
        router.go('/notifications');
      }
      return;
    }
    router.go('/notifications');
  }
}
