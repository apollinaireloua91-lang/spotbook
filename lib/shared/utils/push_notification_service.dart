import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/data/notification_repository.dart';
import '../theme/app_colors.dart';

class PushNotificationService {
  PushNotificationService({required NotificationRepository repository})
      : _repository = repository;

  final NotificationRepository _repository;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context) async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _repository.saveFcmToken(token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _repository.saveFcmToken(newToken);
      });
    }

    // Foreground: show dialog (never system notification)
    FirebaseMessaging.onMessage.listen((message) {
      if (context.mounted) {
        _showForegroundDialog(context, message);
      }
    });

    // Background: navigate on tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (context.mounted) {
        _navigateFromNotification(context, message);
      }
    });

    // Terminated: check initial message
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && context.mounted) {
      _navigateFromNotification(context, initialMessage);
    }
  }

  void _showForegroundDialog(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? 'Spotbook';
    final body = message.notification?.body ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          body,
          style: const TextStyle(color: AppColors.gris, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.blanc)),
          ),
          if (message.data['type'] != null)
            TextButton(
              onPressed: () {
                ctx.pop();
                _navigateFromNotification(context, message);
              },
              child: const Text('Voir', style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _navigateFromNotification(BuildContext context, RemoteMessage message) {
    final type = message.data['type'] as String?;
    final router = GoRouter.of(context);

    switch (type) {
      case 'booking_reminder':
      case 'booking_update':
        final bookingId = message.data['bookingId'] as String?;
        if (bookingId != null) {
          router.push('/booking/$bookingId');
        }
        break;
      case 'chat':
        final conversationId = message.data['conversationId'] as String?;
        if (conversationId != null) {
          router.push('/chat/$conversationId');
        }
        break;
      case 'review_request':
        final bookingId = message.data['bookingId'] as String?;
        if (bookingId != null) {
          router.push('/booking/$bookingId');
        }
        break;
      case 'waitlist':
        final eventId = message.data['eventId'] as String?;
        if (eventId != null) {
          router.push('/event/$eventId');
        }
        break;
      default:
        router.push('/notifications');
    }
  }
}
