import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/booking_models.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(supabase: Supabase.instance.client);
});

class _TimeRange {
  const _TimeRange({required this.start, required this.end});
  final int start; // minutes from midnight
  final int end;
}

class BookingRepository {
  BookingRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  static const _bookingSelect =
      '*, services(name, title, price, duration_minutes), time_slots(date, start_time, end_time), client:users!client_id(full_name, display_name, avatar_url), pro:users!pro_id(full_name, display_name, avatar_url, profiles_pro(business_name, category, city))';

  // ─── Slots & dates ────────────────────────────────────────

  Future<List<String>> getAvailableDates(String proId) async {
    final data = await _supabase
        .from('time_slots')
        .select('date')
        .eq('pro_id', proId)
        .eq('is_available', true)
        .gte('date', DateTime.now().toIso8601String().split('T')[0])
        .lte(
          'date',
          DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String()
              .split('T')[0],
        )
        .order('date');

    final dates = <String>{};
    for (final row in data as List) {
      dates.add(row['date'] as String);
    }
    return dates.toList();
  }

  /// Returns the set of active weekday indices for a Pro (0=Sunday … 6=Saturday,
  /// JS convention matching the DB schema).
  /// Used by the calendar to decide which dates are clickable even when
  /// time_slots haven't been generated yet.
  Future<Set<int>> getProActiveWeekdays(String proId) async {
    final rows = await _supabase
        .from('availability_rules')
        .select('day_of_week')
        .eq('pro_id', proId);
    final set = <int>{};
    for (final row in rows as List) {
      final d = (row as Map)['day_of_week'];
      if (d is int) set.add(d);
    }
    return set;
  }

  /// Fallback slot generator that only reads `availability_rules` (required
  /// table). Used if the more comprehensive computeSlotsForDate fails for any
  /// reason (missing columns, RLS issue, network blip). Guarantees a sensible
  /// display of the Pro's weekly hours.
  Future<List<TimeSlotModel>> computeSlotsSimple({
    required String proId,
    required DateTime date,
  }) async {
    final isoDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dowJs = date.weekday == 7 ? 0 : date.weekday;

    final rows = await _supabase
        .from('availability_rules')
        .select('start_time, end_time')
        .eq('pro_id', proId)
        .eq('day_of_week', dowJs);

    if ((rows as List).isEmpty) return [];

    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;

    // Build and merge ranges to prevent duplicates when rules overlap
    final ranges = <_TimeRange>[];
    for (final row in rows) {
      final r = row as Map;
      ranges.add(_TimeRange(
        start: _parseMinutes(r['start_time'] as String),
        end: _parseMinutes(r['end_time'] as String),
      ));
    }
    _mergeRanges(ranges);

    // Use a Set of start minutes to guarantee uniqueness as extra safety
    final seenStarts = <int>{};
    final slots = <TimeSlotModel>[];
    for (final range in ranges) {
      for (var t = range.start; t + 15 <= range.end; t += 15) {
        if (isToday && t < nowMinutes) continue;
        if (!seenStarts.add(t)) continue; // already generated this start time
        final startStr = _minutesToStr(t);
        final endStr = _minutesToStr(t + 15);
        slots.add(TimeSlotModel(
          id: 'virtual_${isoDate}_$startStr',
          proId: proId,
          date: isoDate,
          startTime: '$startStr:00',
          endTime: '$endStr:00',
          isAvailable: true,
        ));
      }
    }
    return slots;
  }

  /// Computes the list of 15-minute time slots for a Pro on a given date,
  /// derived from their weekly availability_rules ± exceptions ± lunch break.
  /// Excludes slots already booked (is_available = false in time_slots).
  ///
  /// This is the "source of truth" for the client booking flow — it doesn't
  /// depend on the slot generator having run, so a Pro who just saved their
  /// schedule can immediately see their slots on the client side.
  Future<List<TimeSlotModel>> computeSlotsForDate({
    required String proId,
    required DateTime date,
  }) async {
    final isoDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    // JS weekday: 0 = Sunday (matches DB)
    final dowJs = date.weekday == 7 ? 0 : date.weekday;

    final results = await Future.wait<dynamic>([
      // Weekly rules for this weekday
      _supabase
          .from('availability_rules')
          .select(
              'start_time, end_time, lunch_break_start, lunch_break_end')
          .eq('pro_id', proId)
          .eq('day_of_week', dowJs),
      // Exception for this specific date
      _supabase
          .from('availability_exceptions')
          .select('is_closed, custom_start, custom_end')
          .eq('pro_id', proId)
          .eq('exception_date', isoDate)
          .maybeSingle(),
      // Slots already booked (is_available=false) on this date — must be filtered out
      _supabase
          .from('time_slots')
          .select('id, start_time, end_time, is_available')
          .eq('pro_id', proId)
          .eq('date', isoDate),
    ]);

    final rules = results[0] as List;
    final exception = results[1] as Map<String, dynamic>?;
    final existingSlots = results[2] as List;

    // If the day is closed via exception, no slots
    if (exception != null && exception['is_closed'] == true) {
      return [];
    }

    // Build merged active ranges
    var ranges = <_TimeRange>[];
    if (exception != null &&
        exception['custom_start'] != null &&
        exception['custom_end'] != null) {
      ranges = [
        _TimeRange(
          start: _parseMinutes(exception['custom_start'] as String),
          end: _parseMinutes(exception['custom_end'] as String),
        ),
      ];
    } else {
      for (final row in rules) {
        final r = row as Map;
        ranges.add(_TimeRange(
          start: _parseMinutes(r['start_time'] as String),
          end: _parseMinutes(r['end_time'] as String),
        ));
      }
      _mergeRanges(ranges);
      // Subtract lunch break from the first rule that has one (pro should have 1/day)
      final lunchRow = rules.firstWhere(
        (r) =>
            (r as Map)['lunch_break_start'] != null &&
            (r)['lunch_break_end'] != null,
        orElse: () => null,
      );
      if (lunchRow != null) {
        final lunchStart = _parseMinutes(
            (lunchRow as Map)['lunch_break_start'] as String);
        final lunchEnd = _parseMinutes(
            (lunchRow)['lunch_break_end'] as String);
        ranges = _subtractBreak(ranges, lunchStart, lunchEnd);
      }
    }

    if (ranges.isEmpty) return [];

    // Index booked slots by HH:mm for fast lookup
    final bookedStarts = <String>{};
    final availableSlotMap = <String, Map<String, dynamic>>{};
    for (final row in existingSlots) {
      final r = row as Map<String, dynamic>;
      final startStr = (r['start_time'] as String).substring(0, 5);
      if (r['is_available'] == false) {
        bookedStarts.add(startStr);
      } else {
        availableSlotMap[startStr] = r;
      }
    }

    // Generate 15-min slots, skipping booked ones
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;

    final slots = <TimeSlotModel>[];
    for (final range in ranges) {
      for (var t = range.start; t + 15 <= range.end; t += 15) {
        final startStr = _minutesToStr(t);
        final endStr = _minutesToStr(t + 15);
        // Skip past slots on today's date
        if (isToday && t < nowMinutes) continue;
        // Skip booked slots
        if (bookedStarts.contains(startStr)) continue;
        // Prefer existing slot id if one exists (for booking creation)
        final existing = availableSlotMap[startStr];
        slots.add(TimeSlotModel(
          id: (existing?['id'] as String?) ?? 'virtual_${isoDate}_$startStr',
          proId: proId,
          date: isoDate,
          startTime: '$startStr:00',
          endTime: '$endStr:00',
          isAvailable: true,
        ));
      }
    }
    return slots;
  }

  int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToStr(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  void _mergeRanges(List<_TimeRange> ranges) {
    if (ranges.isEmpty) return;
    ranges.sort((a, b) => a.start.compareTo(b.start));
    var i = 0;
    while (i < ranges.length - 1) {
      if (ranges[i + 1].start <= ranges[i].end) {
        ranges[i] = _TimeRange(
          start: ranges[i].start,
          end: ranges[i].end > ranges[i + 1].end
              ? ranges[i].end
              : ranges[i + 1].end,
        );
        ranges.removeAt(i + 1);
      } else {
        i++;
      }
    }
  }

  List<_TimeRange> _subtractBreak(
      List<_TimeRange> ranges, int breakStart, int breakEnd) {
    final out = <_TimeRange>[];
    for (final r in ranges) {
      if (breakEnd <= r.start || breakStart >= r.end) {
        out.add(r);
        continue;
      }
      if (breakStart > r.start) {
        out.add(_TimeRange(start: r.start, end: breakStart));
      }
      if (breakEnd < r.end) {
        out.add(_TimeRange(start: breakEnd, end: r.end));
      }
    }
    return out;
  }

  /// Returns a set of ISO date strings where the Pro has a closed-exception
  /// or the date is in `blocked_dates`. Calendar greys these out.
  Future<Set<String>> getProBlockedDates(String proId) async {
    final results = await Future.wait<dynamic>([
      _supabase
          .from('availability_exceptions')
          .select('exception_date')
          .eq('pro_id', proId)
          .eq('is_closed', true)
          .gte(
            'exception_date',
            DateTime.now().toIso8601String().split('T')[0],
          ),
      _supabase
          .from('profiles_pro')
          .select('availability')
          .eq('id', proId)
          .maybeSingle(),
    ]);
    final blocked = <String>{};
    for (final row in (results[0] as List)) {
      final d = (row as Map)['exception_date'];
      if (d is String) blocked.add(d);
    }
    final av = (results[1] as Map?)?['availability'];
    if (av is Map) {
      final list = av['blocked_dates'];
      if (list is List) {
        for (final d in list) {
          if (d is String) blocked.add(d);
        }
      }
    }
    return blocked;
  }

  Future<List<TimeSlotModel>> getTimeSlots(String proId, String date) async {
    final data = await _supabase
        .from('time_slots')
        .select()
        .eq('pro_id', proId)
        .eq('date', date)
        .eq('is_available', true)
        .order('start_time');

    return (data as List)
        .map((json) => TimeSlotModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Services ─────────────────────────────────────────────

  Future<List<ServiceModel>> getProServices(String proId) async {
    final data = await _supabase
        .from('services')
        .select()
        .eq('pro_id', proId)
        .eq('is_active', true)
        .order('price');

    return (data as List)
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Create booking ──────────────────────────────────────

  Future<Map<String, dynamic>> createBooking({
    required String slotId,
    required String serviceId,
    String? promoCodeId,
    String? proId,
    String? slotDate,
    String? slotStart,
    String? slotEnd,
  }) async {
    // Refresh session + passer explicitement le token utilisateur en header.
    // Sans le header explicite, le SDK peut envoyer l'anon key ce qui fait
    // échouer getUser() côté edge function (→ 401 unauthorized).
    await _supabase.auth.refreshSession();
    final accessToken = _supabase.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Session expirée — reconnecte-toi');
    }
    // Si le slot a un id "virtual_..." (généré à la volée côté client),
    // on envoie plutôt le spec (pro/date/heures) et l'edge function crée
    // le vrai time_slot via service-role avant de créer le booking.
    final isVirtual = slotId.startsWith('virtual_');
    final res = await _supabase.functions.invoke(
      'create-booking-atomic',
      body: {
        if (!isVirtual) 'slotId': slotId,
        'serviceId': serviceId,
        if (promoCodeId != null) 'promoCodeId': promoCodeId,
        if (proId != null) 'proId': proId,
        if (slotDate != null) 'slotDate': slotDate,
        if (slotStart != null) 'slotStart': slotStart,
        if (slotEnd != null) 'slotEnd': slotEnd,
      },
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Échec de la réservation';
      throw Exception(err ?? 'Échec de la réservation');
    }
    return res.data as Map<String, dynamic>;
  }

  // ─── Bookings lists ──────────────────────────────────────

  Future<List<BookingModel>> getClientBookings() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final data = await _supabase
        .from('bookings')
        .select(_bookingSelect)
        .eq('client_id', uid)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingModel>> getProBookings() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final data = await _supabase
        .from('bookings')
        .select(_bookingSelect)
        .eq('pro_id', uid)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Cancel booking ──────────────────────────────────────

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final res = await _supabase.functions.invoke(
      'cancel-booking',
      body: {'bookingId': bookingId},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Cancel failed';
      throw Exception(err ?? 'Cancel failed');
    }
    return res.data as Map<String, dynamic>;
  }

  // ─── Promo code ───────────────────────────────────────────

  Future<PromoCodeModel?> validatePromoCode(
      String code, String proId) async {
    final data = await _supabase
        .from('promo_codes')
        .select()
        .eq('code', code)
        .eq('pro_id', proId)
        .eq('is_active', true)
        .maybeSingle();
    if (data == null) return null;

    final promo = PromoCodeModel.fromJson(data);
    return promo;
  }

  // ─── Realtime slot availability ──────────────────────────

  RealtimeChannel subscribeSlotChanges({
    required String proId,
    required String date,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return _supabase
        .channel('slots-$proId-$date')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'time_slots',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pro_id',
            value: proId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  void unsubscribeChannel(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }

  // ─── Pro dashboard stats ──────────────────────────────────

  Future<Map<String, dynamic>> getProDashboardStats() async {
    final uid = currentUserId;
    if (uid == null) return {};

    final bookings = await _supabase
        .from('bookings')
        .select('status, total_amount, deposit_amount')
        .eq('pro_id', uid);

    final list = bookings as List;
    int totalBookings = list.length;
    int upcoming = 0;
    double totalRevenue = 0;

    for (final b in list) {
      if (b['status'] == 'confirmed' || b['status'] == 'pending_payment') {
        upcoming++;
      }
      if (b['status'] == 'completed' || b['status'] == 'confirmed') {
        totalRevenue += (b['deposit_amount'] as num?)?.toDouble() ?? 0;
      }
    }

    final profile = await _supabase
        .from('profiles_pro')
        .select('average_rating, review_count')
        .eq('id', uid)
        .maybeSingle();

    return {
      'total_bookings': totalBookings,
      'upcoming': upcoming,
      'total_revenue': totalRevenue,
      'average_rating':
          (profile?['average_rating'] as num?)?.toDouble() ?? 0.0,
      'review_count': profile?['review_count'] as int? ?? 0,
    };
  }

  Future<List<BookingModel>> getUpcomingProBookings({int limit = 5}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final data = await _supabase
        .from('bookings')
        .select(_bookingSelect)
        .eq('pro_id', uid)
        .inFilter('status', ['confirmed', 'pending_payment'])
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    final data = await _supabase
        .from('bookings')
        .select(_bookingSelect)
        .eq('id', bookingId)
        .maybeSingle();
    if (data == null) return null;
    return BookingModel.fromJson(data);
  }

  Future<void> proConfirmBooking(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'confirmed'})
        .eq('id', bookingId);
  }

  Future<void> markBookingCompleted(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'completed'})
        .eq('id', bookingId);
  }

  Future<void> markRemainingPaid(String bookingId) async {
    await _supabase.from('bookings').update({
      'remaining_payment_status': 'paid_on_site',
      'remaining_paid_at': DateTime.now().toUtc().toIso8601String(),
      'payment_status': 'fully_paid',
    }).eq('id', bookingId);
  }

  // ─── QR Validation (Pro scanner) ──────────────────────────

  Future<Map<String, dynamic>> validateBookingQr({
    required String bookingId,
    required String qrHash,
  }) async {
    final res = await _supabase.functions.invoke(
      'validate-qr-booking',
      body: {'bookingId': bookingId, 'qrHash': qrHash},
    );
    return res.data as Map<String, dynamic>;
  }

  // ─── Reviews ─────────────────────────────────────────────

  Future<void> submitReview({
    required String bookingId,
    required String proId,
    required int rating,
    required String comment,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    await _supabase.from('reviews').upsert({
      'booking_id': bookingId,
      'client_id': uid,
      'pro_id': proId,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'booking_id');
  }

  Future<bool> hasReviewedBooking(String bookingId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final data = await _supabase
        .from('reviews')
        .select('id')
        .eq('booking_id', bookingId)
        .eq('client_id', uid)
        .maybeSingle();
    return data != null;
  }
}
