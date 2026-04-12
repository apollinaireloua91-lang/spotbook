import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final proFeedRepositoryProvider = Provider<ProFeedRepository>((ref) {
  return ProFeedRepository(supabase: Supabase.instance.client);
});

class ProFeedRepository {
  ProFeedRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  // ─── Badge Counts ─────────────────────────────────────────────────

  Future<int> countUnreadNotifications() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final res = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> countPendingBookings() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final res = await _supabase
          .from('bookings')
          .select('id')
          .eq('pro_id', uid)
          .inFilter('status', ['pending', 'confirmed']);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> countTicketSales() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final events = await _supabase
          .from('events')
          .select('id')
          .eq('pro_id', uid);
      final ids = (events as List).map((e) => e['id'] as String).toList();
      if (ids.isEmpty) return 0;
      final res = await _supabase
          .from('tickets')
          .select('id')
          .inFilter('event_id', ids);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> countUnreadMessages() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final res = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', uid)
          .eq('is_read', false);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ─── Bottom Sheet Data ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchNotifications(
      {int limit = 20}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final res = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchBookings({int limit = 20}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final res = await _supabase
          .from('bookings')
          .select('*, services(title, name)')
          .eq('pro_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTicketSales(
      {int limit = 20}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final events = await _supabase
          .from('events')
          .select('id')
          .eq('pro_id', uid);
      final ids = (events as List).map((e) => e['id'] as String).toList();
      if (ids.isEmpty) return [];
      final res = await _supabase
          .from('tickets')
          .select('*, events(title)')
          .inFilter('event_id', ids)
          .order('purchased_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages({int limit = 20}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final res = await _supabase
          .from('messages')
          .select()
          .eq('receiver_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }
}
