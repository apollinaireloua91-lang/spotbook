import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(supabase: Supabase.instance.client);
});

class NotificationRepository {
  NotificationRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<List<NotificationModel>> getNotifications() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  Future<NotificationPreferences> getPreferences() async {
    final uid = _uid;
    if (uid == null) return const NotificationPreferences();

    final data = await _supabase
        .from('notification_preferences')
        .select()
        .eq('user_id', uid)
        .maybeSingle();

    if (data == null) return const NotificationPreferences();
    return NotificationPreferences.fromJson(data);
  }

  Future<void> updatePreferences(Map<String, bool> updates) async {
    final uid = _uid;
    if (uid == null) return;

    await _supabase
        .from('notification_preferences')
        .upsert({'user_id': uid, ...updates}, onConflict: 'user_id');
  }

  Future<void> saveFcmToken(String token) async {
    final uid = _uid;
    if (uid == null) return;

    await _supabase
        .from('users')
        .update({'fcm_token': token})
        .eq('id', uid);
  }

  Future<int> getUnreadCount() async {
    final uid = _uid;
    if (uid == null) return 0;

    final result = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .eq('is_read', false)
        .count(CountOption.exact);

    return result.count;
  }

  /// Returns unread counts grouped by type category for Pro notification dots.
  Future<Map<String, int>> getUnreadCountsByCategory() async {
    final uid = _uid;
    if (uid == null) return {};

    final data = await _supabase
        .from('notifications')
        .select('type')
        .eq('user_id', uid)
        .eq('is_read', false);

    final counts = <String, int>{};
    for (final row in data) {
      final type = row['type'] as String? ?? 'general';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }
}
