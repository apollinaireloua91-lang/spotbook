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

  static const _bookingSelect =
      '*, services(name, price, duration_minutes), time_slots(date, start_time, end_time), profiles_pro(business_name, users(full_name, avatar_url))';

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
    await _supabase
        .from('bookings')
        .update({'remaining_payment_status': 'paid'})
        .eq('id', bookingId);
  }
}
