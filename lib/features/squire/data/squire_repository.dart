import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/squire_models.dart';

final squireRepositoryProvider = Provider<SquireRepository>((ref) {
  return SquireRepository(supabase: Supabase.instance.client);
});

/// Unified repository for Squire feature-parity (#2-#13).
/// Grouped by feature with clear section headers.
///
/// Conventions:
///   - Methods return domain models (never raw Maps).
///   - Writes that require atomicity or cross-table consistency invoke
///     edge functions (process-tip, award-loyalty, generate-receipt).
///   - Direct table writes are only for user-owned simple CRUD (notes,
///     recurring cancellation, waitlist self-insert).
class SquireRepository {
  SquireRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;
  String? get _uid => _supabase.auth.currentUser?.id;

  // ══════════════════════════════════════════════════════════════════════
  // #2 — Availability exceptions
  // ══════════════════════════════════════════════════════════════════════

  Future<List<AvailabilityException>> listExceptions({
    required String proId,
    DateTime? fromDate,
  }) async {
    var q = _supabase
        .from('availability_exceptions')
        .select()
        .eq('pro_id', proId);
    if (fromDate != null) {
      q = q.gte('exception_date',
          fromDate.toIso8601String().split('T')[0]);
    }
    final rows = await q.order('exception_date', ascending: true);
    return (rows as List)
        .map((r) => AvailabilityException.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<AvailabilityException> upsertException(
      AvailabilityException exception) async {
    final row = await _supabase
        .from('availability_exceptions')
        .upsert(exception.toInsertJson(),
            onConflict: 'pro_id,exception_date')
        .select()
        .single();
    return AvailabilityException.fromJson(row);
  }

  Future<void> deleteException(String id) async {
    await _supabase.from('availability_exceptions').delete().eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════════════
  // #3 — Tipping
  // ══════════════════════════════════════════════════════════════════════

  /// Creates a tip PaymentIntent via edge function. Returns the clientSecret
  /// for the Flutter Stripe SDK to confirm.
  Future<Map<String, dynamic>> startTipPayment({
    required String bookingId,
    required int amountCents,
  }) async {
    final res = await _supabase.functions.invoke(
      'process-tip',
      body: {'bookingId': bookingId, 'amountCents': amountCents},
    );
    if (res.status != 200) {
      throw Exception((res.data as Map?)?['error'] ?? 'tip_error');
    }
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Tip>> listTipsForPro({int limit = 50}) async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('tips')
        .select()
        .eq('pro_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => Tip.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════
  // #5 — Waitlist
  // ══════════════════════════════════════════════════════════════════════

  Future<BookingWaitlistEntry> joinWaitlist({
    required String proId,
    String? serviceId,
    required DateTime preferredDate,
    String? preferredTimeStart,
    String? preferredTimeEnd,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    final row = await _supabase
        .from('booking_waitlist')
        .insert({
          'client_id': uid,
          'pro_id': proId,
          'service_id': serviceId,
          'preferred_date':
              preferredDate.toIso8601String().split('T')[0],
          'preferred_time_start': preferredTimeStart,
          'preferred_time_end': preferredTimeEnd,
        })
        .select()
        .single();
    return BookingWaitlistEntry.fromJson(row);
  }

  Future<List<BookingWaitlistEntry>> listWaitlistForClient() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('booking_waitlist')
        .select()
        .eq('client_id', uid)
        .inFilter('status', ['waiting', 'notified'])
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) =>
            BookingWaitlistEntry.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingWaitlistEntry>> listWaitlistForPro({
    required String proId,
  }) async {
    final rows = await _supabase
        .from('booking_waitlist')
        .select()
        .eq('pro_id', proId)
        .eq('status', 'waiting')
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) =>
            BookingWaitlistEntry.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelWaitlistEntry(String id) async {
    await _supabase
        .from('booking_waitlist')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════════════
  // #6 — Walk-in queue
  // ══════════════════════════════════════════════════════════════════════

  Future<WalkInEntry> addWalkIn({
    required String clientName,
    String? clientPhone,
    String? serviceId,
    int? estimatedWaitMinutes,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    // Compute next position
    final last = await _supabase
        .from('walk_in_queue')
        .select('position')
        .eq('pro_id', uid)
        .eq('status', 'waiting')
        .order('position', ascending: false)
        .limit(1);
    final lastPos = (last as List).isEmpty
        ? 0
        : ((last.first as Map)['position'] as int? ?? 0);
    final row = await _supabase
        .from('walk_in_queue')
        .insert({
          'pro_id': uid,
          'client_name': clientName,
          'client_phone': clientPhone,
          'service_id': serviceId,
          'position': lastPos + 1,
          'estimated_wait_minutes': estimatedWaitMinutes,
        })
        .select()
        .single();
    return WalkInEntry.fromJson(row);
  }

  Future<List<WalkInEntry>> listActiveWalkIns() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('walk_in_queue')
        .select()
        .eq('pro_id', uid)
        .inFilter('status', ['waiting', 'in_service'])
        .order('position', ascending: true);
    return (rows as List)
        .map((r) => WalkInEntry.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateWalkInStatus(String id, WalkInStatus status) async {
    String asDbValue(WalkInStatus s) {
      switch (s) {
        case WalkInStatus.inService:
          return 'in_service';
        case WalkInStatus.noShow:
          return 'no_show';
        default:
          return s.name;
      }
    }

    final payload = <String, dynamic>{'status': asDbValue(status)};
    if (status == WalkInStatus.inService) {
      payload['started_at'] = DateTime.now().toIso8601String();
    } else if (status == WalkInStatus.completed) {
      payload['completed_at'] = DateTime.now().toIso8601String();
    }
    await _supabase.from('walk_in_queue').update(payload).eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════════════
  // #7 — Recurring bookings
  // ══════════════════════════════════════════════════════════════════════

  Future<RecurringBooking> createRecurring({
    required String proId,
    required String serviceId,
    required int dayOfWeek,
    required String startTime,
    required int frequencyWeeks,
    required DateTime nextBookingDate,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    final row = await _supabase
        .from('recurring_bookings')
        .insert({
          'client_id': uid,
          'pro_id': proId,
          'service_id': serviceId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'frequency_weeks': frequencyWeeks,
          'next_booking_date':
              nextBookingDate.toIso8601String().split('T')[0],
        })
        .select()
        .single();
    return RecurringBooking.fromJson(row);
  }

  Future<List<RecurringBooking>> listMyRecurring() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('recurring_bookings')
        .select()
        .or('client_id.eq.$uid,pro_id.eq.$uid')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => RecurringBooking.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelRecurring(String id) async {
    await _supabase
        .from('recurring_bookings')
        .update({
          'is_active': false,
          'cancelled_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════════════
  // #8 — Client notes
  // ══════════════════════════════════════════════════════════════════════

  Future<ClientNote?> loadClientNote({required String clientId}) async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _supabase
        .from('client_notes')
        .select()
        .eq('pro_id', uid)
        .eq('client_id', clientId)
        .maybeSingle();
    if (row == null) return null;
    return ClientNote.fromJson(row);
  }

  Future<ClientNote> saveClientNote({
    required String clientId,
    required String note,
    List<String> tags = const [],
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    final row = await _supabase
        .from('client_notes')
        .upsert({
          'pro_id': uid,
          'client_id': clientId,
          'note': note,
          'tags': tags,
        }, onConflict: 'pro_id,client_id')
        .select()
        .single();
    return ClientNote.fromJson(row);
  }

  Future<void> deleteClientNote(String noteId) async {
    await _supabase.from('client_notes').delete().eq('id', noteId);
  }

  // ══════════════════════════════════════════════════════════════════════
  // #9 — Loyalty
  // ══════════════════════════════════════════════════════════════════════

  Future<LoyaltyProgram?> loadLoyaltyProgram(String proId) async {
    final row = await _supabase
        .from('loyalty_programs')
        .select()
        .eq('pro_id', proId)
        .maybeSingle();
    if (row == null) return null;
    return LoyaltyProgram.fromJson(row);
  }

  Future<LoyaltyProgram> saveLoyaltyProgram(LoyaltyProgram program) async {
    final row = await _supabase
        .from('loyalty_programs')
        .upsert(program.toUpsertJson())
        .select()
        .single();
    return LoyaltyProgram.fromJson(row);
  }

  /// Gets the current balance for a (client, pro) pair via the view.
  Future<int> loyaltyBalance({required String clientId, required String proId}) async {
    final row = await _supabase
        .from('loyalty_balances')
        .select('balance')
        .eq('client_id', clientId)
        .eq('pro_id', proId)
        .maybeSingle();
    return (row?['balance'] as int?) ?? 0;
  }

  Future<List<LoyaltyLedgerEntry>> loyaltyHistory({
    required String proId,
    int limit = 50,
  }) async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('loyalty_points_ledger')
        .select()
        .eq('client_id', uid)
        .eq('pro_id', proId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) =>
            LoyaltyLedgerEntry.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════
  // #10 — Referrals
  // ══════════════════════════════════════════════════════════════════════

  Future<UserReferral?> loadMyReferralCode() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _supabase
        .from('user_referrals')
        .select()
        .eq('referrer_id', uid)
        .filter('referred_id', 'is', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return UserReferral.fromJson(row);
  }

  /// Creates a new unique referral code for the current user.
  /// Code format: 4 letters of user's name + 4 random chars, uppercased.
  Future<UserReferral> generateReferralCode({
    String prefix = 'SPOT',
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    // Generate a random 4-char suffix
    final chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    final suffix = List.generate(4, (i) {
      return chars[(rand >> (i * 5)) & 0x1F % chars.length];
    }).join();
    final code = '${prefix.toUpperCase()}$suffix';
    final row = await _supabase
        .from('user_referrals')
        .insert({
          'referrer_id': uid,
          'referral_code': code,
        })
        .select()
        .single();
    return UserReferral.fromJson(row);
  }

  Future<List<UserReferral>> listMyReferrals() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('user_referrals')
        .select()
        .eq('referrer_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => UserReferral.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════
  // #12 — Receipts
  // ══════════════════════════════════════════════════════════════════════

  Future<DigitalReceipt?> loadReceiptForBooking(String bookingId) async {
    final row = await _supabase
        .from('receipts')
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();
    if (row == null) return null;
    return DigitalReceipt.fromJson(row);
  }

  Future<List<DigitalReceipt>> listMyReceipts({int limit = 30}) async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('receipts')
        .select()
        .eq('client_id', uid)
        .order('generated_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => DigitalReceipt.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════
  // #13 — Enhanced reviews
  // ══════════════════════════════════════════════════════════════════════

  Future<void> submitEnhancedReview({
    required String bookingId,
    required String proId,
    required ReviewCriteria criteria,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    final payload = <String, dynamic>{
      'booking_id': bookingId,
      'client_id': uid,
      'pro_id': proId,
      ...criteria.toInsertJson(),
    };
    await _supabase.from('reviews').upsert(payload);
  }
}
