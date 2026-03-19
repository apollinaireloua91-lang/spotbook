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

    await _supabase.from('reviews').insert({
      'booking_id': bookingId,
      'client_id': uid,
      'pro_id': proId,
      'rating': rating,
      'comment': comment,
    });
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
