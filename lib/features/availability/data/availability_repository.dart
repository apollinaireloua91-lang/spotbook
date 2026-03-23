import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/availability_models.dart';

class AvailabilityRepository {
  final _db = Supabase.instance.client;

  String get _uid => _db.auth.currentUser!.id;

  // ─── Load all availability data ─────────────────────────────────────────────

  Future<AvailabilityState> load() async {
    final results = await Future.wait<dynamic>([
      _db.from('provider_availability').select().eq('provider_id', _uid),
      _db
          .from('provider_blocked_dates')
          .select()
          .eq('provider_id', _uid)
          .gte('blocked_date', _today()),
      _db
          .from('provider_settings')
          .select()
          .eq('provider_id', _uid)
          .maybeSingle(),
    ]);

    final weekRules = _parseWeekRules(results[0] as List<dynamic>);
    final blockedDates = _parseBlockedDates(results[1] as List<dynamic>);
    final settings = _parseSettings(results[2] as Map<String, dynamic>?);

    return AvailabilityState(
      weekRules: weekRules,
      blockedDates: blockedDates,
      settings: settings,
    );
  }

  Future<List<BlockedDate>> loadBlockedDates() async {
    final rows = await _db
        .from('provider_blocked_dates')
        .select()
        .eq('provider_id', _uid)
        .gte('blocked_date', _today());
    return _parseBlockedDates(rows as List<dynamic>);
  }

  // ─── Save weekly availability ────────────────────────────────────────────────

  Future<void> saveAvailability(List<DayRule> rules) async {
    await _db.from('provider_availability').delete().eq('provider_id', _uid);

    final rows = <Map<String, dynamic>>[];
    for (final rule in rules) {
      if (!rule.isActive || rule.slots.isEmpty) continue;
      for (int i = 0; i < rule.slots.length; i++) {
        final slot = rule.slots[i];
        rows.add({
          'provider_id': _uid,
          'day_of_week': rule.dayOfWeek,
          'start_time': _fmt(slot.startTime),
          'end_time': _fmt(slot.endTime),
          'slot_index': i,
          'is_active': true,
        });
      }
    }
    if (rows.isNotEmpty) {
      await _db.from('provider_availability').insert(rows);
    }
  }

  // ─── Blocked dates toggle ────────────────────────────────────────────────────

  Future<void> toggleBlockedDate(DateTime date, List<BlockedDate> current) async {
    final dateStr = _dateStr(date);
    final existing = current.where((d) => _sameDay(d.date, date)).firstOrNull;

    if (existing != null) {
      await _db.from('provider_blocked_dates').delete().eq('id', existing.id);
    } else {
      await _db.from('provider_blocked_dates').insert({
        'provider_id': _uid,
        'blocked_date': dateStr,
      });
    }
  }

  // ─── Settings ────────────────────────────────────────────────────────────────

  Future<void> saveSettings(AvailabilitySettings s) async {
    await _db.from('provider_settings').upsert({
      'provider_id': _uid,
      'min_gap_minutes': s.minGapMinutes,
      'max_bookings_per_day': s.maxBookingsPerDay,
      'accepts_bookings': s.acceptsBookings,
      'min_advance_hours': s.minAdvanceHours,
    });
  }

  Future<void> toggleAcceptBookings(bool value) async {
    await _db.from('provider_settings').upsert({
      'provider_id': _uid,
      'accepts_bookings': value,
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  List<DayRule> _parseWeekRules(List<dynamic> rows) {
    final slotsMap = <int, List<DaySlot>>{};
    final activeMap = <int, bool>{};

    for (final row in rows) {
      final dow = row['day_of_week'] as int;
      activeMap[dow] = row['is_active'] as bool? ?? true;
      (slotsMap[dow] ??= []).add(DaySlot(
        tempId: '${dow}_${row['slot_index']}',
        slotIndex: row['slot_index'] as int,
        startTime: _parseTime(row['start_time'] as String),
        endTime: _parseTime(row['end_time'] as String),
      ));
    }

    return List.generate(7, (i) {
      final slots = (slotsMap[i] ?? [])
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
      return DayRule(
        dayOfWeek: i,
        isActive: activeMap[i] ?? false,
        slots: slots,
      );
    });
  }

  List<BlockedDate> _parseBlockedDates(List<dynamic> rows) => rows
      .map((r) => BlockedDate(
            id: r['id'] as String,
            date: DateTime.parse(r['blocked_date'] as String),
            reason: r['reason'] as String?,
          ))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  AvailabilitySettings _parseSettings(Map<String, dynamic>? row) {
    if (row == null) return const AvailabilitySettings();
    return AvailabilitySettings(
      minGapMinutes: row['min_gap_minutes'] as int? ?? 15,
      maxBookingsPerDay: row['max_bookings_per_day'] as int? ?? 10,
      acceptsBookings: row['accepts_bookings'] as bool? ?? true,
      minAdvanceHours: row['min_advance_hours'] as int? ?? 2,
    );
  }

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _today() => _dateStr(DateTime.now());
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final availabilityRepositoryProvider =
    Provider<AvailabilityRepository>((ref) => AvailabilityRepository());
