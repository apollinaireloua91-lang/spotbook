import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification_model.dart';
import 'notification_repository.dart';

// ─── Notification list ──────────────────────────────────────

class NotificationListState {
  const NotificationListState({this.notifications = const [], this.isLoading = true});
  final List<NotificationModel> notifications;
  final bool isLoading;

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
  }) =>
      NotificationListState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationListNotifier extends Notifier<NotificationListState> {
  @override
  NotificationListState build() {
    _load();
    return const NotificationListState();
  }

  Future<void> _load() async {
    final repo = ref.read(notificationRepositoryProvider);
    final list = await repo.getNotifications();
    state = state.copyWith(notifications: list, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Future<void> markAsRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id
              ? NotificationModel(
                  id: n.id,
                  userId: n.userId,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  data: n.data,
                  isRead: true,
                  createdAt: n.createdAt,
                )
              : n)
          .toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => NotificationModel(
                id: n.id,
                userId: n.userId,
                title: n.title,
                body: n.body,
                type: n.type,
                data: n.data,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList(),
    );
  }

  Future<void> deleteNotification(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.deleteNotification(id);
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
  }
}

final notificationListProvider =
    NotifierProvider<NotificationListNotifier, NotificationListState>(
  NotificationListNotifier.new,
  isAutoDispose: true,
);

// ─── Notification preferences ───────────────────────────────

class NotifPrefsState {
  const NotifPrefsState({
    this.prefs = const NotificationPreferences(),
    this.isLoading = true,
    this.isSaving = false,
  });
  final NotificationPreferences prefs;
  final bool isLoading;
  final bool isSaving;

  NotifPrefsState copyWith({
    NotificationPreferences? prefs,
    bool? isLoading,
    bool? isSaving,
  }) =>
      NotifPrefsState(
        prefs: prefs ?? this.prefs,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
      );
}

class NotifPrefsNotifier extends Notifier<NotifPrefsState> {
  @override
  NotifPrefsState build() {
    _load();
    return const NotifPrefsState();
  }

  Future<void> _load() async {
    final repo = ref.read(notificationRepositoryProvider);
    final prefs = await repo.getPreferences();
    state = state.copyWith(prefs: prefs, isLoading: false);
  }

  Future<void> updatePreference(String key, bool value) async {
    state = state.copyWith(isSaving: true);
    final repo = ref.read(notificationRepositoryProvider);
    await repo.updatePreferences({key: value});
    await _load();
    state = state.copyWith(isSaving: false);
  }
}

final notifPrefsProvider = NotifierProvider<NotifPrefsNotifier, NotifPrefsState>(
  NotifPrefsNotifier.new,
  isAutoDispose: true,
);
