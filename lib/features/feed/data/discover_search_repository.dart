import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/provider_search_result.dart';

/// Distance en km (Haversine). Utilisé quand la RPC n’a pas renvoyé `distance_km`
/// mais que client + pro ont des coordonnées.
double? _haversineKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180.0;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

final discoverSearchRepositoryProvider =
    Provider<DiscoverSearchRepository>((ref) {
  return DiscoverSearchRepository(supabase: Supabase.instance.client);
});

class DiscoverSearchRepository {
  DiscoverSearchRepository({required SupabaseClient supabase})
      : _supabase = supabase;

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
  /// Category: substring match (ilike %cat%) so UI chips match more DB values.
  Future<List<ProviderSearchResult>> getAllProviders({
    String? category,
    double minRating = 0,
  }) async {
    final hasCategory =
        category != null && category != 'All' && category.trim().isNotEmpty;

    final List<dynamic> prosData;
    if (hasCategory) {
      final pattern = '%${category.trim()}%';
      prosData = await _supabase
          .from('profiles_pro')
          .select(
              'id, business_name, category, description, average_rating, review_count')
          .ilike('category', pattern)
          .order('average_rating', ascending: false);
    } else {
      prosData = await _supabase
          .from('profiles_pro')
          .select(
              'id, business_name, category, description, average_rating, review_count')
          .order('average_rating', ascending: false);
    }

    if (prosData.isEmpty) return [];

    final ids = prosData.map((p) => p['id'] as String).toList();

    final List<dynamic> usersData = await _supabase
        .from('users')
        .select(
          'id, full_name, avatar_url, city, username, latitude, longitude, deleted_at, role',
        )
        .inFilter('id', ids);

    final userMap = <String, Map<String, dynamic>>{
      for (final u in usersData)
        u['id'] as String: Map<String, dynamic>.from(u as Map),
    };

    final list = prosData.map((raw) {
      final p = Map<String, dynamic>.from(raw as Map);
      final id = p['id'] as String;
      final u = userMap[id] ?? <String, dynamic>{};
      return ProviderSearchResult.fromJson({...p, ...u});
    }).where((pro) {
      final u = userMap[pro.id];
      if (u == null) return true;
      return u['deleted_at'] == null;
    }).toList();

    return list.where((p) => (p.averageRating ?? 0) >= minRating).toList();
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
        'p_query':
            (query == null || query.trim().isEmpty) ? null : query.trim(),
        'p_category':
            (category == null || category.trim().isEmpty || category == 'All')
                ? null
                : category.trim(),
        'p_min_rating': minRating,
        'p_limit': limit,
      },
    );
    if (res == null) return [];
    return (res as List)
        .map((e) =>
            ProviderSearchResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Liste complète des pros (PostgREST) + enrichissement distance / coords via RPC.
  ///
  /// La RPC seule renvoie souvent `[]` sans erreur (catégorie stricte, `category` NULL
  /// côté SQL, rayon, etc.) — d’où la fusion pour que le client voie toujours les pros.
  Future<List<ProviderSearchResult>> fetchDiscoverProviders({
    double? clientLat,
    double? clientLng,
    double radiusKm = 50,
    String? textQuery,
    String? categoryChip,
    double minRating = 0,
  }) async {
    final cat = categoryChip;
    final trimmedQuery = textQuery?.trim();
    final hasText = trimmedQuery != null && trimmedQuery.isNotEmpty;

    final base = await getAllProviders(category: cat, minRating: minRating);

    List<ProviderSearchResult> rpcList = [];
    try {
      // Pas de p_query ici : le filtre texte est appliqué en Dart sur [base] pour
      // rester aligné avec getAllProviders (évite écarts ILIKE / champs NULL).
      rpcList = await searchProvidersNearby(
        lat: clientLat,
        lng: clientLng,
        radiusKm: radiusKm,
        query: null,
        category: cat,
        minRating: minRating,
        limit: 100,
      );
    } catch (_) {
      rpcList = [];
    }

    final rpcById = {for (final p in rpcList) p.id: p};

    var merged = base.map((rest) {
      final rpc = rpcById[rest.id];
      if (rpc == null) return rest;
      return ProviderSearchResult(
        id: rest.id,
        businessName: rest.businessName ?? rpc.businessName,
        category: rest.category ?? rpc.category,
        description: rest.description,
        averageRating: rest.averageRating ?? rpc.averageRating,
        reviewCount: rest.reviewCount ?? rpc.reviewCount,
        fullName: rest.fullName ?? rpc.fullName,
        avatarUrl: rest.avatarUrl ?? rpc.avatarUrl,
        city: rest.city ?? rpc.city,
        username: rest.username ?? rpc.username,
        distanceKm: rpc.distanceKm ?? rest.distanceKm,
        latitude: rest.latitude ?? rpc.latitude,
        longitude: rest.longitude ?? rpc.longitude,
        minPrice: rest.minPrice ?? rpc.minPrice,
        isOnline: rest.isOnline ?? rpc.isOnline,
      );
    }).toList();

    if (hasText) {
      final q = trimmedQuery.toLowerCase();
      merged = merged
          .where(
            (p) =>
                p.displayName.toLowerCase().contains(q) ||
                (p.category?.toLowerCase().contains(q) ?? false) ||
                (p.city?.toLowerCase().contains(q) ?? false) ||
                (p.username?.toLowerCase().contains(q) ?? false) ||
                (p.businessName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    // Complète distance_km pour affichage / tri si client + pro ont des coords
    // mais que la fusion n’a pas rempli la distance (ex. pro absent du résultat RPC).
    // On ne filtre jamais sur lat/lng NULL : distance inconnue → pas de filtre distance ici.
    if (clientLat != null && clientLng != null) {
      merged = merged.map((p) {
        if (p.latitude == null || p.longitude == null) return p;
        if (p.distanceKm != null) return p;
        final d = _haversineKm(
          clientLat,
          clientLng,
          p.latitude!,
          p.longitude!,
        );
        return p.copyWith(distanceKm: d);
      }).toList();
    }

    merged.sort(_compareDiscoverProviders);
    return merged;
  }
}

int _compareDiscoverProviders(ProviderSearchResult a, ProviderSearchResult b) {
  final da = a.distanceKm;
  final db = b.distanceKm;
  if (da != null && db != null) return da.compareTo(db);
  if (da != null) return -1;
  if (db != null) return 1;
  final rc = (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0);
  if (rc != 0) return rc;
  return (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
}
