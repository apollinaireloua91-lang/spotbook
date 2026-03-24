import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/provider_search_result.dart';

final discoverSearchRepositoryProvider = Provider<DiscoverSearchRepository>((ref) {
  return DiscoverSearchRepository(supabase: Supabase.instance.client);
});

class DiscoverSearchRepository {
  DiscoverSearchRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Returns GPS coords from `users` table. Never throws — returns (null, null) on any error.
  Future<({double? lat, double? lng})> getCurrentUserCoordinates() async {
    try {
      final uid = currentUserId;
      if (uid == null) return (lat: null, lng: null);
      final row = await _supabase
          .from('users')
          .select('latitude, longitude')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return (lat: null, lng: null);
      return (
        lat: (row['latitude'] as num?)?.toDouble(),
        lng: (row['longitude'] as num?)?.toDouble(),
      );
    } catch (_) {
      // Columns may not exist yet (migration pending) — continue without coords.
      return (lat: null, lng: null);
    }
  }

  /// Direct PostgREST query — ALL pros, no RPC dependency.
  /// Used as primary loader and fallback when the RPC is unavailable.
  Future<List<ProviderSearchResult>> getAllProviders({String? category}) async {
    final hasCategory =
        category != null && category != 'All' && category.trim().isNotEmpty;

    final List<dynamic> prosData;
    if (hasCategory) {
      prosData = await _supabase
          .from('profiles_pro')
          .select('id, business_name, category, average_rating, review_count')
          .ilike('category', category.trim())
          .order('average_rating', ascending: false);
    } else {
      prosData = await _supabase
          .from('profiles_pro')
          .select('id, business_name, category, average_rating, review_count')
          .order('average_rating', ascending: false);
    }

    if (prosData.isEmpty) return [];

    final ids = prosData.map((p) => p['id'] as String).toList();

    final List<dynamic> usersData = await _supabase
        .from('users')
        .select('id, full_name, avatar_url, city, username, latitude, longitude, is_online')
        .inFilter('id', ids);

    final userMap = <String, Map<String, dynamic>>{
      for (final u in usersData)
        u['id'] as String: Map<String, dynamic>.from(u as Map),
    };

    return prosData.map((raw) {
      final p = Map<String, dynamic>.from(raw as Map);
      final u = userMap[p['id'] as String] ?? <String, dynamic>{};
      return ProviderSearchResult.fromJson({...p, ...u});
    }).toList();
  }

  Future<List<ProviderSearchResult>> searchProvidersNearby({
    double? lat,
    double? lng,
    double radiusKm = 50,
    String? query,
    String? category,
    double minRating = 0,
    int limit = 50,
  }) async {
    final res = await _supabase.rpc(
      'search_providers_nearby',
      params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_radius_km': radiusKm,
        'p_query': (query == null || query.trim().isEmpty) ? null : query.trim(),
        'p_category': (category == null || category.trim().isEmpty || category == 'All')
            ? null
            : category.trim(),
        'p_min_rating': minRating,
        'p_limit': limit,
      },
    );
    if (res == null) return [];
    return (res as List)
        .map((e) => ProviderSearchResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
