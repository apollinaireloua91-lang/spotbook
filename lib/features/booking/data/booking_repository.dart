import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/booking_models.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(supabase: Supabase.instance.client);
});

class BookingRepository {
  BookingRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// `bookings.pro_id` → `users` (pas `profiles_pro`) : embed via `pro_user`.
  static const _bookingSelect =
      '*, services(name, price, duration_minutes), time_slots(date, start_time, end_time), pro_user:users!bookings_pro_id_fkey(full_name, avatar_url, city, profiles_pro(business_name, category))';

  static const _proBookingSelect =
      '*, services(name, price, duration_minutes), time_slots(date, start_time, end_time), pro_user:users!bookings_pro_id_fkey(full_name, avatar_url, city, profiles_pro(business_name, category)), client_user:users!bookings_client_id_fkey(full_name, avatar_url)';

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
    // Pas de filtre `is_active` en SQL : colonne parfois NULL sur certaines bases.
    final rows = await _supabase
        .from('services')
        .select()
        .eq('pro_id', proId)
        .order('price');

    return (rows as List)
        .where((row) {
          final m = row as Map<String, dynamic>;
          final v = m['is_active'];
          if (v == null) return true;
          return v == true;
        })
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Create booking ──────────────────────────────────────

  Future<Map<String, dynamic>> createBooking({
    required String slotId,
    required String serviceId,
    String? promoCodeId,
  }) async {
    final res = await _supabase.functions.invoke(
      'create-booking-atomic',
      body: {
        'slotId': slotId,
        'serviceId': serviceId,
        if (promoCodeId != null) 'promoCodeId': promoCodeId,
      },
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Booking failed';
      throw Exception(err ?? 'Booking failed');
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
        .select(_proBookingSelect)
        .eq('pro_id', uid)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    final data = await _supabase
        .from('bookings')
        .select(_proBookingSelect)
        .eq('id', bookingId)
        .maybeSingle();
    if (data == null) return null;
    return BookingModel.fromJson(data);
  }

  /// Pro : met à jour le statut d'une réservation via Edge Function sécurisée.
  /// [action] : 'accept', 'decline', 'complete'
  Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String action, {
    String? reason,
  }) async {
    final res = await _supabase.functions.invoke(
      'update-booking-status',
      body: {
        'bookingId': bookingId,
        'action': action,
        if (reason != null) 'reason': reason,
      },
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Status update failed';
      throw Exception(err ?? 'Status update failed');
    }
    return res.data as Map<String, dynamic>;
  }

  /// Pro : marque le RDV comme terminé (après passage en salon).
  Future<void> markBookingCompleted(String bookingId) async {
    await updateBookingStatus(bookingId, 'complete');
  }

  /// Pro : accepte une réservation en attente (ex. après paiement / validation).
  Future<void> proConfirmBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'accept');
  }

  /// Pro : marque le solde restant comme payé sur place.
  Future<void> markRemainingPaid(String bookingId) async {
    await updateBookingStatus(bookingId, 'mark_remaining_paid');
  }

  /// Pro : refuse une réservation avec motif optionnel.
  Future<void> proDeclineBooking(String bookingId, {String? reason}) async {
    await updateBookingStatus(bookingId, 'decline', reason: reason);
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

  // ─── Reschedule booking ──────────────────────────────────

  /// Atomically reschedules a booking to a new slot via server-side RPC.
  /// Frees the old slot, reserves the new slot, and updates the booking
  /// in a single transaction to prevent data corruption.
  Future<Map<String, dynamic>> rescheduleBooking({
    required String bookingId,
    required String oldSlotId,
    required String newSlotId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final result = await _supabase.rpc('reschedule_booking_atomic', params: {
      'p_booking_id': bookingId,
      'p_old_slot_id': oldSlotId,
      'p_new_slot_id': newSlotId,
      'p_user_id': uid,
    });

    final data = result as Map<String, dynamic>;
    if (data.containsKey('error')) {
      throw Exception(data['error'] as String);
    }
    return data;
  }

  // ─── Promo code ───────────────────────────────────────────

  Future<PromoCodeModel?> validatePromoCode(String code, String proId) async {
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
      'average_rating': (profile?['average_rating'] as num?)?.toDouble() ?? 0.0,
      'review_count': profile?['review_count'] as int? ?? 0,
    };
  }

  /// Série journalière des acomptes (RDV confirmés + terminés) pour graphique revenus.
  Future<List<({DateTime day, double amount})>> getProRevenueDaily({
    int days = 30,
  }) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final from = DateTime.now().subtract(Duration(days: days));
    final data = await _supabase
        .from('bookings')
        .select('deposit_amount, created_at, status')
        .eq('pro_id', uid)
        .gte('created_at', from.toIso8601String())
        .inFilter('status', ['confirmed', 'completed']);

    final byDay = <String, double>{};
    for (final row in data as List) {
      final created = DateTime.parse(row['created_at'] as String).toUtc();
      final local = created.toLocal();
      final key =
          '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
      final amt = (row['deposit_amount'] as num?)?.toDouble() ?? 0;
      byDay[key] = (byDay[key] ?? 0) + amt;
    }

    final out = <({DateTime day, double amount})>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      out.add((day: DateTime(d.year, d.month, d.day), amount: byDay[key] ?? 0));
    }
    return out;
  }

  /// Transactions détaillées (bookings confirmés/terminés) pour la période.
  Future<List<BookingModel>> getProTransactions({int days = 30}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final from = DateTime.now().subtract(Duration(days: days));
    final data = await _supabase
        .from('bookings')
        .select(_proBookingSelect)
        .eq('pro_id', uid)
        .gte('created_at', from.toIso8601String())
        .inFilter('status', ['confirmed', 'completed'])
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingModel>> getUpcomingProBookings({int limit = 5}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final data = await _supabase
        .from('bookings')
        .select(_proBookingSelect)
        .eq('pro_id', uid)
        .inFilter('status', ['confirmed', 'pending_payment'])
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
