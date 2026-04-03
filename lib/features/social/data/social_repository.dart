import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../favorites/domain/favorite_model.dart';
import '../../reviews/domain/review_model.dart';
import '../domain/social_models.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(supabase: Supabase.instance.client);
});

class SocialRepository {
  SocialRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;
  String? get currentUserId => _uid;

  Future<void> addReview({
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

  Future<void> toggleFavorite({
    required String targetId,
    required String targetType,
    String? targetName,
    String? targetImageUrl,
    String? targetSubtitle,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final existing = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', uid)
        .eq('target_id', targetId)
        .maybeSingle();
    if (existing != null) {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', uid)
          .eq('target_id', targetId);
      return;
    }
    await _supabase.from('favorites').upsert({
      'user_id': uid,
      'target_id': targetId,
      'target_type': targetType,
      'target_name': targetName,
      'target_image_url': targetImageUrl,
      'target_subtitle': targetSubtitle,
    }, onConflict: 'user_id, target_id');
  }

  Future<List<FavoriteModel>> getFavorites(String targetType) async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _supabase
        .from('favorites')
        .select()
        .eq('user_id', uid)
        .eq('target_type', targetType)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> applyPromoCode({
    required String code,
    required String proId,
    required double amount,
  }) async {
    final res = await _supabase.functions.invoke(
      'apply-promo-code',
      body: {'code': code, 'proId': proId, 'amount': amount},
    );
    if (res.status != 200) {
      throw Exception((res.data as Map?)?['error'] ?? 'Promo invalide');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> createPromoCode({
    required String code,
    required int discountPercent,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase.from('promo_codes').insert({
      'pro_id': uid,
      'code': code.toUpperCase(),
      'discount_percent': discountPercent,
      'max_uses': maxUses,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': true,
    });
  }

  Future<String> getReferralCode() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final user = await _supabase
        .from('users')
        .select('referral_code')
        .eq('id', uid)
        .single();
    final existing = user['referral_code'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = 'SPT-${uid.substring(0, 6).toUpperCase()}';
    await _supabase.from('users').update({'referral_code': generated}).eq('id', uid);
    return generated;
  }

  Future<void> blockUser(String blockedId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase.from('blocks').upsert({
      'blocker_id': uid,
      'blocked_id': blockedId,
    });
  }

  Future<void> reportContent({
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase.from('reports').insert({
      'reporter_id': uid,
      'target_id': targetId,
      'target_type': targetType,
      'reason': reason,
    });
  }

  Future<ProInsights> getProInsights({
    required String proId,
    required int period,
  }) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: period));
    final prevFrom = from.subtract(Duration(days: period));

    final bookingsCurrent = await _supabase
        .from('bookings')
        .select('total_amount, created_at')
        .eq('pro_id', proId)
        .eq('status', 'completed')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', now.toIso8601String());
    final bookingsPrevious = await _supabase
        .from('bookings')
        .select('total_amount')
        .eq('pro_id', proId)
        .eq('status', 'completed')
        .gte('created_at', prevFrom.toIso8601String())
        .lt('created_at', from.toIso8601String());

    final revenueCurrent = (bookingsCurrent as List)
        .fold<double>(0, (acc, e) => acc + ((e['total_amount'] as num?)?.toDouble() ?? 0));
    final revenuePrev = (bookingsPrevious as List)
        .fold<double>(0, (acc, e) => acc + ((e['total_amount'] as num?)?.toDouble() ?? 0));

    final viewsCurrent = await _supabase
        .from('videos')
        .select('views_count')
        .eq('pro_id', proId)
        .gte('created_at', from.toIso8601String());
    final viewsPrev = await _supabase
        .from('videos')
        .select('views_count')
        .eq('pro_id', proId)
        .gte('created_at', prevFrom.toIso8601String())
        .lt('created_at', from.toIso8601String());

    final eventsCurrent = await _supabase
        .from('events')
        .select('id')
        .eq('pro_id', proId)
        .gte('created_at', from.toIso8601String());
    final eventsPrev = await _supabase
        .from('events')
        .select('id')
        .eq('pro_id', proId)
        .gte('created_at', prevFrom.toIso8601String())
        .lt('created_at', from.toIso8601String());

    final viewsNow = (viewsCurrent as List)
        .fold<int>(0, (acc, e) => acc + (e['views_count'] as int? ?? 0));
    final viewsBefore = (viewsPrev as List)
        .fold<int>(0, (acc, e) => acc + (e['views_count'] as int? ?? 0));

    double delta(double current, double previous) {
      if (previous == 0) return current > 0 ? 100 : 0;
      return ((current - previous) / previous) * 100;
    }

    final points = _buildRevenueSeries(
      (bookingsCurrent as List).cast<Map<String, dynamic>>(),
      period,
      from,
    );

    return ProInsights(
      periodDays: period,
      revenueSeries: points,
      metrics: [
        InsightMetric(
          label: 'Revenus',
          value: revenueCurrent,
          deltaPercent: delta(revenueCurrent, revenuePrev),
        ),
        InsightMetric(
          label: 'Vues vidéo',
          value: viewsNow.toDouble(),
          deltaPercent: delta(viewsNow.toDouble(), viewsBefore.toDouble()),
        ),
        InsightMetric(
          label: 'Événements',
          value: (eventsCurrent as List).length.toDouble(),
          deltaPercent: delta(
            (eventsCurrent as List).length.toDouble(),
            (eventsPrev as List).length.toDouble(),
          ),
        ),
      ],
    );
  }

  List<InsightPoint> _buildRevenueSeries(
    List<Map<String, dynamic>> bookings,
    int period,
    DateTime from,
  ) {
    final bucketCount = period == 7 ? 7 : 6;
    final bucketSize = period / bucketCount;
    final buckets = List<double>.filled(bucketCount, 0);
    for (final b in bookings) {
      final createdAt = DateTime.tryParse(b['created_at'] as String? ?? '');
      if (createdAt == null) continue;
      final diff = createdAt.difference(from).inDays.clamp(0, period - 1);
      final idx = (diff / bucketSize).floor().clamp(0, bucketCount - 1);
      buckets[idx] += (b['total_amount'] as num?)?.toDouble() ?? 0;
    }
    return List.generate(bucketCount, (i) {
      final label = period == 7 ? 'J${i + 1}' : 'S${i + 1}';
      return InsightPoint(label: label, value: buckets[i]);
    });
  }
}

final socialProReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  proId,
) async {
  final data = await Supabase.instance.client
      .from('reviews')
      .select('*, users:client_id(full_name, avatar_url)')
      .eq('pro_id', proId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
