import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/booking_models.dart';

final proSchedulingRepositoryProvider = Provider<ProSchedulingRepository>((ref) {
  return ProSchedulingRepository(supabase: Supabase.instance.client);
});

class ProSchedulingRepository {
  ProSchedulingRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Jour JS (0 = dimanche) à partir d'une date locale.
  static int jsDayOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.weekday == DateTime.sunday ? 0 : d.weekday;
  }

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _timeFromMinutes(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }

  static int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  Future<List<ServiceModel>> fetchAllServices(String proId) async {
    final data = await _supabase
        .from('services')
        .select()
        .eq('pro_id', proId)
        .order('price');

    return (data as List)
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Colonnes `title` et `category` sont NOT NULL côté Postgres (`services`).
  Future<String> _defaultServiceCategory(String proId) async {
    final row = await _supabase
        .from('profiles_pro')
        .select('category')
        .eq('id', proId)
        .maybeSingle();
    final c = row?['category'] as String?;
    if (c != null && c.trim().isNotEmpty) return c.trim();
    return 'Autre';
  }

  Future<void> createService({
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
    double depositPercentage = 0.30,
    String paymentMode = 'full',
    String? depositType,
    double? depositValue,
  }) async {
    await _supabase.auth.refreshSession();
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('Le nom du service est obligatoire');

    final category = await _defaultServiceCategory(uid);

    await _supabase.from('services').insert({
      'pro_id': uid,
      'title': trimmed,
      'name': trimmed,
      'category': category,
      'description': description?.trim(),
      'duration_minutes': durationMinutes,
      'price': price,
      'deposit_percentage': depositPercentage,
      'payment_mode': paymentMode,
      'deposit_type': depositType,
      'deposit_value': depositValue,
      'is_active': true,
    });
  }

  Future<void> updateService({
    required String id,
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
    required bool isActive,
    double depositPercentage = 0.30,
    String paymentMode = 'full',
    String? depositType,
    double? depositValue,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    final trimmed = name.trim();

    await _supabase.from('services').update({
      'title': trimmed,
      'name': trimmed,
      'description': description?.trim(),
      'duration_minutes': durationMinutes,
      'price': price,
      'deposit_percentage': depositPercentage,
      'payment_mode': paymentMode,
      'deposit_type': depositType,
      'deposit_value': depositValue,
      'is_active': isActive,
    }).eq('id', id).eq('pro_id', uid);
  }

  Future<void> setServiceActive(String id, bool isActive) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');
    await _supabase
        .from('services')
        .update({'is_active': isActive}).eq('id', id).eq('pro_id', uid);
  }

  Future<List<AvailabilityRuleModel>> fetchAvailabilityRules(String proId) async {
    final data = await _supabase
        .from('availability_rules')
        .select()
        .eq('pro_id', proId)
        .order('day_of_week')
        .order('start_time');

    return (data as List)
        .map((json) => AvailabilityRuleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addAvailabilityRule({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDurationMinutes,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    await _supabase.from('availability_rules').insert({
      'pro_id': uid,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_minutes': slotDurationMinutes,
    });
  }

  Future<void> deleteAvailabilityRule(String ruleId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');
    await _supabase.from('availability_rules').delete().eq('id', ruleId).eq('pro_id', uid);
  }

  Future<List<TimeSlotModel>> fetchTimeSlotsForDate(String proId, String date) async {
    final data = await _supabase
        .from('time_slots')
        .select()
        .eq('pro_id', proId)
        .eq('date', date)
        .order('start_time');

    return (data as List)
        .map((json) => TimeSlotModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> setSlotAvailable(String slotId, bool isAvailable) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');
    await _supabase
        .from('time_slots')
        .update({'is_available': isAvailable}).eq('id', slotId).eq('pro_id', uid);
  }

  /// Recalcule les créneaux des [horizonDays] prochains jours (upsert), comme `generate-slots`.
  Future<int> syncTimeSlotsFromRules({int horizonDays = 14}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    final rules = await fetchAvailabilityRules(uid);
    if (rules.isEmpty) return 0;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final rows = <Map<String, dynamic>>[];

    for (var offset = 0; offset < horizonDays; offset++) {
      final date = start.add(Duration(days: offset));
      final dow = jsDayOfWeek(date);
      final dateStr = _dateStr(date);

      for (final rule in rules.where((r) => r.dayOfWeek == dow)) {
        final startMin = _parseTimeToMinutes(rule.startTime);
        final endMin = _parseTimeToMinutes(rule.endTime);
        final dur = rule.slotDurationMinutes;
        if (endMin <= startMin || dur <= 0) continue;

        for (var slotStart = startMin; slotStart + dur <= endMin; slotStart += dur) {
          final slotEnd = slotStart + dur;
          rows.add({
            'pro_id': uid,
            'date': dateStr,
            'start_time': _timeFromMinutes(slotStart),
            'end_time': _timeFromMinutes(slotEnd),
            'is_available': true,
          });
        }
      }
    }

    const batchSize = 40;
    for (var i = 0; i < rows.length; i += batchSize) {
      final end = min(i + batchSize, rows.length);
      final chunk = rows.sublist(i, end);
      await _supabase.from('time_slots').upsert(
            chunk,
            onConflict: 'pro_id,date,start_time',
          );
    }

    return rows.length;
  }
}
