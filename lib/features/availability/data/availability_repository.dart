import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/availability_models.dart';

/// Persistance alignée sur `supabase/migrations` :
/// - `availability_rules` (pro_id, day_of_week JS 0=dim … 6=sam)
/// - `provider_settings` (clé **pro_id**, pas provider_id)
/// - Jours bloqués + toggle réservations : `profiles_pro.availability` (jsonb)
class AvailabilityRepository {
  final _db = Supabase.instance.client;

  String get _uid => _db.auth.currentUser!.id;

  // ─── Load ───────────────────────────────────────────────────────────────────

  Future<AvailabilityState> load() async {
    final results = await Future.wait<dynamic>([
      _db
          .from('availability_rules')
          .select()
          .eq('pro_id', _uid)
          .order('day_of_week')
          .order('start_time'),
      _db.from('provider_settings').select().eq('pro_id', _uid).maybeSingle(),
      _db.from('profiles_pro').select('availability').eq('id', _uid).maybeSingle(),
    ]);

    final weekRules = _weekRulesFromAvailabilityRules(results[0] as List<dynamic>);
    final settings = _parseSettings(
      results[1] as Map<String, dynamic>?,
      results[2] as Map<String, dynamic>?,
    );
    final blockedDates = _blockedDatesFromProfileJson(results[2] as Map<String, dynamic>?);

    return AvailabilityState(
      weekRules: weekRules,
      blockedDates: blockedDates,
      settings: settings,
    );
  }

  Future<List<BlockedDate>> loadBlockedDates() async {
    final row = await _db
        .from('profiles_pro')
        .select('availability')
        .eq('id', _uid)
        .maybeSingle();
    return _blockedDatesFromProfileJson(row);
  }

  // ─── Save weekly rules → availability_rules ─────────────────────────────────

  Future<void> saveAvailability(List<DayRule> rules) async {
    await _db.from('availability_rules').delete().eq('pro_id', _uid);

    final rows = <Map<String, dynamic>>[];
    for (final rule in rules) {
      if (!rule.isActive || rule.slots.isEmpty) continue;
      final dbDow = _uiDowToDb(rule.dayOfWeek);
      for (final slot in rule.slots) {
        if (!slot.isValid) continue;
        rows.add({
          'pro_id': _uid,
          'day_of_week': dbDow,
          'start_time': _fmt(slot.startTime),
          'end_time': _fmt(slot.endTime),
          'slot_duration_minutes': 60,
        });
      }
    }
    if (rows.isNotEmpty) {
      await _db.from('availability_rules').insert(rows);
    }
  }

  // ─── Blocked dates (jsonb) ──────────────────────────────────────────────────

  Future<void> toggleBlockedDate(DateTime date, List<BlockedDate> current) async {
    final dateStr = _dateStr(date);
    final row = await _db
        .from('profiles_pro')
        .select('availability')
        .eq('id', _uid)
        .maybeSingle();
    final av = Map<String, dynamic>.from(row?['availability'] as Map? ?? {});
    final blocked = List<String>.from(
      (av['blocked_dates'] as List<dynamic>? ?? []).map((e) => e.toString()),
    );

    final had = current.any((d) => _sameDay(d.date, date));
    if (had) {
      blocked.removeWhere((s) => s == dateStr);
    } else {
      if (!blocked.contains(dateStr)) blocked.add(dateStr);
    }
    blocked.sort();
    av['blocked_dates'] = blocked;

    await _db.from('profiles_pro').update({'availability': av}).eq('id', _uid);
  }

  // ─── Settings (provider_settings + accepts dans jsonb) ─────────────────────

  Future<void> saveSettings(AvailabilitySettings s) async {
    await _db.from('provider_settings').upsert({
      'pro_id': _uid,
      'min_gap_minutes': s.minGapMinutes,
      'max_bookings_per_day': s.maxBookingsPerDay,
      'min_advance_hours': s.minAdvanceHours,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final row = await _db
        .from('profiles_pro')
        .select('availability')
        .eq('id', _uid)
        .maybeSingle();
    final av = Map<String, dynamic>.from(row?['availability'] as Map? ?? {});
    av['accepts_bookings'] = s.acceptsBookings;
    await _db.from('profiles_pro').update({'availability': av}).eq('id', _uid);
  }

  Future<void> toggleAcceptBookings(bool value) async {
    final row = await _db
        .from('profiles_pro')
        .select('availability')
        .eq('id', _uid)
        .maybeSingle();
    final av = Map<String, dynamic>.from(row?['availability'] as Map? ?? {});
    av['accepts_bookings'] = value;
    await _db.from('profiles_pro').update({'availability': av}).eq('id', _uid);
  }

  // ─── Day-of-week : UI 0=lun…6=dim ↔ DB JS 0=dim…6=sam ─────────────────────

  static int _uiDowToDb(int ui) => ui == 6 ? 0 : ui + 1;

  static int _dbDowToUi(int db) => db == 0 ? 6 : db - 1;

  List<DayRule> _weekRulesFromAvailabilityRules(List<dynamic> rows) {
    final slotsMap = <int, List<DaySlot>>{};

    for (final row in rows) {
      final rawDow = row['day_of_week'];
      if (rawDow == null) continue;
      final dbDow = rawDow as int;
      final uiDow = _dbDowToUi(dbDow);
      final id = row['id']?.toString() ?? '${uiDow}_${row['start_time']}';
      final startStr = row['start_time']?.toString() ?? '00:00:00';
      final endStr = row['end_time']?.toString() ?? '00:00:00';

      final list = slotsMap.putIfAbsent(uiDow, () => []);
      list.add(
        DaySlot(
          tempId: id,
          slotIndex: list.length,
          startTime: _parseTime(startStr),
          endTime: _parseTime(endStr),
        ),
      );
    }

    return List.generate(7, (i) {
      final slots = List<DaySlot>.from(slotsMap[i] ?? [])
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      for (var j = 0; j < slots.length; j++) {
        final s = slots[j];
        slots[j] = DaySlot(
          tempId: s.tempId,
          slotIndex: j,
          startTime: s.startTime,
          endTime: s.endTime,
        );
      }
      return DayRule(
        dayOfWeek: i,
        isActive: slots.isNotEmpty,
        slots: slots,
      );
    });
  }

  List<BlockedDate> _blockedDatesFromProfileJson(Map<String, dynamic>? row) {
    if (row == null) return [];
    final av = row['availability'];
    if (av is! Map) return [];
    final raw = av['blocked_dates'];
    if (raw is! List) return [];
    final today = _today();
    final out = <BlockedDate>[];
    for (final e in raw) {
      final s = e.toString();
      if (s.length < 10) continue;
      if (s.compareTo(today) < 0) continue;
      out.add(BlockedDate(id: s, date: DateTime.parse(s)));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  AvailabilitySettings _parseSettings(
    Map<String, dynamic>? settingsRow,
    Map<String, dynamic>? profileRow,
  ) {
    Map<String, dynamic>? av;
    if (profileRow != null && profileRow['availability'] is Map) {
      av = Map<String, dynamic>.from(profileRow['availability'] as Map);
    }
    final acceptsBookings = av?['accepts_bookings'] is bool
        ? av!['accepts_bookings'] as bool
        : true;

    if (settingsRow == null) {
      return AvailabilitySettings(acceptsBookings: acceptsBookings);
    }

    return AvailabilitySettings(
      minGapMinutes: settingsRow['min_gap_minutes'] as int? ?? 15,
      maxBookingsPerDay: settingsRow['max_bookings_per_day'] as int? ?? 10,
      acceptsBookings: acceptsBookings,
      minAdvanceHours: settingsRow['min_advance_hours'] as int? ?? 2,
    );
  }

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
    return TimeOfDay(hour: h, minute: m);
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
