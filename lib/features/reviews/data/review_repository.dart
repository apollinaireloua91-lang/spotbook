import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/review_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(supabase: Supabase.instance.client);
});

class ReviewRepository {
  ReviewRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<void> createReview({
    required String bookingId,
    required String proId,
    required int rating,
    String? comment,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    await _supabase.from('reviews').upsert({
      'booking_id': bookingId,
      'client_id': uid,
      'pro_id': proId,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'booking_id');
  }

  Future<List<ReviewModel>> getProReviews(String proId) async {
    final data = await _supabase
        .from('reviews')
        .select('*, users:client_id(full_name, avatar_url)')
        .eq('pro_id', proId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<double> getProAverageRating(String proId) async {
    final data = await _supabase
        .from('reviews')
        .select('rating')
        .eq('pro_id', proId);

    final ratings = (data as List).map((r) => (r['rating'] as int)).toList();
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  /// Completed bookings the current client hasn't reviewed yet.
  ///
  /// Two small round-trips:
  ///   1. Pull all completed bookings with their pro + service joins.
  ///   2. Pull the set of booking_ids already reviewed by this client.
  /// Filter locally — simpler than a NOT EXISTS subselect and keeps the
  /// query readable. Completed-bookings count per client is small.
  Future<List<ReviewableBookingItem>> getReviewableBookings() async {
    final uid = _uid;
    if (uid == null) return [];

    final bookings = await _supabase
        .from('bookings')
        .select(
          'id, pro_id, status, created_at, '
          'services(name, title), '
          'pro:users!pro_id(full_name, display_name, avatar_url, '
          'profiles_pro(business_name, category))',
        )
        .eq('client_id', uid)
        .eq('status', 'completed')
        .order('created_at', ascending: false);

    final list = (bookings as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return [];

    final ids = list.map((b) => b['id'] as String).toList();
    final reviewed = await _supabase
        .from('reviews')
        .select('booking_id')
        .eq('client_id', uid)
        .inFilter('booking_id', ids);
    final reviewedIds = {
      for (final r in (reviewed as List).cast<Map<String, dynamic>>())
        r['booking_id'] as String,
    };

    return list
        .where((b) => !reviewedIds.contains(b['id']))
        .map(ReviewableBookingItem.fromJson)
        .toList();
  }

  Future<bool> hasReviewed(String bookingId) async {
    final uid = _uid;
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
