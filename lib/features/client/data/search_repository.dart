import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../presentation/search/models/search_models.dart';

/// Repository Supabase pour la recherche Client. Déporte TOUT l'accès DB
/// hors de la couche présentation (règle CLAUDE.md : pas de Supabase dans un
/// Widget/Notifier d'écran). Le `ClientSearchNotifier` consomme uniquement les
/// méthodes ci-dessous — il ne construit jamais de `PostgrestQueryBuilder`.
class SearchRepository {
  SearchRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  /// Montréal par défaut si la géoloc échoue — valeurs utilisées pour le
  /// fallback lat/lng des entités sans coordonnées réelles.
  static const fallbackLat = 45.5100;
  static const fallbackLng = -73.5700;

  /// Rayon maximum (mètres) du jitter appliqué aux Pros dont on ne connaît
  /// que la ville. Deterministic (dérivé du hash du pro.id), donc chaque Pro
  /// reste toujours au même endroit entre sessions.
  static const _kCityJitterMaxMeters = 220.0;

  /// Cache en mémoire des résolutions geocode-city pour cette session.
  /// Évite un rebond Edge Function quand plusieurs Pros partagent la ville.
  final Map<String, ({double lat, double lng})> _cityCoordsCache = {};

  /// Récupère les Pros publics triés par rating, avec leurs services actifs.
  /// Tous les Pros retournés ont des coordonnées : soit exactes (flag
  /// `hasRealCoords = true`), soit dérivées de leur ville via geocode-city
  /// + jitter déterministe (`hasRealCoords = false`). Renvoie sans distance
  /// calculée (responsabilité du Notifier qui connaît la position utilisateur).
  Future<List<ProSearchResult>> fetchPros() async {
    final prosData = await _supabase
        .from('profiles_pro')
        .select(
            '*, users!id(full_name, display_name, avatar_url, username, latitude, longitude, city, country)')
        .eq('is_public', true)
        .eq('search_visible', true)
        .order('rating_average', ascending: false);

    final proIds = (prosData as List)
        .map((p) => (p as Map)['id'] as String)
        .toList();

    final servicesData = proIds.isEmpty
        ? const <dynamic>[]
        : await _supabase
            .from('services')
            .select('id, title, price, duration_minutes, pro_id')
            .inFilter('pro_id', proIds)
            .eq('is_active', true);

    final servicesMap = <String, List<ProService>>{};
    for (final raw in servicesData) {
      final s = raw as Map;
      final proId = s['pro_id'] as String;
      servicesMap.putIfAbsent(proId, () => []);
      final mins = s['duration_minutes'] as int? ?? 30;
      final dur = mins >= 60
          ? '${mins ~/ 60}h${mins % 60 > 0 ? '${mins % 60}' : ''}'
          : '$mins min';
      servicesMap[proId]!.add(ProService(
        id: s['id'] as String,
        name: s['title'] as String? ?? '',
        duration: dur,
        price: (s['price'] as num?)?.toDouble() ?? 0,
      ));
    }

    // ── Phase 1 : construction de la liste brute (sans garantie de coords) ──
    final rawPros = prosData.map((raw) {
      final p = Map<String, dynamic>.from(raw as Map);
      final id = p['id'] as String;
      final u = (p['users'] as Map<String, dynamic>?) ?? const {};
      final rawLat = (u['latitude'] as num?)?.toDouble() ??
          (p['latitude'] as num?)?.toDouble();
      final rawLng = (u['longitude'] as num?)?.toDouble() ??
          (p['longitude'] as num?)?.toDouble();
      final hasReal = rawLat != null && rawLng != null;
      final city = (u['city'] as String?) ?? 'Montréal';
      final country = (u['country'] as String?) ?? '';

      final services = servicesMap[id] ?? const [];
      final prices = services.map((s) => s.price).toList()..sort();
      final priceRange = prices.isEmpty
          ? ''
          : prices.length == 1
              ? '${prices.first.toInt()}'
              : '${prices.first.toInt()}-${prices.last.toInt()}';

      return _PendingPro(
        proResult: ProSearchResult(
          id: id,
          name: (u['full_name'] as String?) ??
              (p['business_name'] as String?) ??
              '',
          category: (p['category'] as String?) ?? '',
          location: city,
          // Coords à résoudre en phase 2 si hasRealCoords == false.
          lat: rawLat ?? fallbackLat,
          lng: rawLng ?? fallbackLng,
          rating: (p['rating_average'] as num?)?.toDouble() ?? 0,
          reviews: (p['review_count'] as int?) ?? 0,
          distKm: 0, // Le Notifier applique Haversine après géoloc.
          priceRange: priceRange,
          online: false,
          avatarUrl: u['avatar_url'] as String?,
          services: services,
          hasRealCoords: hasReal,
        ),
        city: city,
        country: country,
      );
    }).toList();

    // ── Phase 2 : résolution des villes pour Pros sans coords réelles ──
    final uniqueCityKeys = <String>{};
    for (final pp in rawPros) {
      if (pp.proResult.hasRealCoords) continue;
      if (pp.city.trim().isEmpty) continue;
      uniqueCityKeys.add(_cityKey(pp.city, pp.country));
    }

    // Geocoding parallèle, un appel par ville unique.
    await Future.wait(uniqueCityKeys.map((key) async {
      if (_cityCoordsCache.containsKey(key)) return;
      final parts = key.split('|');
      final city = parts.isNotEmpty ? parts[0] : '';
      final country = parts.length > 1 ? parts[1] : '';
      final coords = await _resolveCityCoords(city, country);
      if (coords != null) _cityCoordsCache[key] = coords;
    }));

    // ── Phase 3 : application coords + jitter déterministe par Pro ──
    return rawPros.map((pp) {
      if (pp.proResult.hasRealCoords) return pp.proResult;

      final key = _cityKey(pp.city, pp.country);
      final base = _cityCoordsCache[key];
      if (base == null) {
        // Dernier recours : Montréal. Le Pro sera visible mais flottant.
        return pp.proResult;
      }

      final jittered = _applyDeterministicJitter(
        base.lat,
        base.lng,
        pp.proResult.id,
      );
      return pp.proResult.copyWith(
        lat: jittered.$1,
        lng: jittered.$2,
        // hasRealCoords reste `false` : l'UI peut afficher un badge
        // "approximatif" si souhaité. Le map n'utilise plus ce flag pour
        // filtrer — tous les Pros apparaissent.
      );
    }).toList();
  }

  /// Appelle l'Edge Function `geocode-city`. Retourne null si la ville est
  /// introuvable ou si l'Edge Function échoue — le Pro utilisera alors le
  /// fallback Montréal.
  Future<({double lat, double lng})?> _resolveCityCoords(
      String city, String country) async {
    if (city.trim().isEmpty) return null;
    try {
      final resp = await _supabase.functions.invoke(
        'geocode-city',
        body: {'city': city, 'country': country},
      );
      final data = resp.data;
      if (data is Map) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return (lat: lat, lng: lng);
        }
      }
    } catch (_) {
      // Silently fall back to null — Pro sera skippé (fallback Montréal).
    }
    return null;
  }

  String _cityKey(String city, String country) =>
      '${city.trim()}|${country.trim()}';

  /// Jitter déterministe : dérive un angle et une distance du hash du pro.id.
  /// Garantit que chaque Pro reste toujours au même point entre sessions
  /// (≠ d'un random qui ferait "danser" les markers à chaque fetch) tout en
  /// évitant l'empilement de Pros au même pixel au centre d'une ville.
  (double, double) _applyDeterministicJitter(
      double lat, double lng, String proId) {
    final hash = proId.hashCode & 0x7FFFFFFF;
    final angle = (hash & 0xFFFF) / 0xFFFF * 2 * math.pi;
    final distMeters =
        ((hash >> 16) & 0xFFFF) / 0xFFFF * _kCityJitterMaxMeters;

    // 1° latitude ≈ 111 320 m. 1° longitude varie avec cos(latitude).
    final dLat = (distMeters * math.cos(angle)) / 111320.0;
    final dLng =
        (distMeters * math.sin(angle)) / (111320.0 * math.cos(lat * math.pi / 180));
    return (lat + dLat, lng + dLng);
  }

  /// Événements à venir, incluant nom du Pro organisateur et starting price.
  Future<List<EventSearchResult>> fetchUpcomingEvents() async {
    final eventsData = await _supabase
        .from('events')
        .select('*, ticket_types(id, name, price, quantity, sold_count)')
        .eq('is_active', true)
        .gte('event_date', DateTime.now().toIso8601String())
        .order('event_date');

    final eventProIds = (eventsData as List)
        .map((e) => (e as Map)['pro_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final eventUsersData = eventProIds.isEmpty
        ? const <dynamic>[]
        : await _supabase
            .from('users')
            .select('id, full_name')
            .inFilter('id', eventProIds);

    final eventUserMap = <String, String>{
      for (final raw in eventUsersData)
        (raw as Map)['id'] as String: raw['full_name'] as String? ?? '',
    };

    return eventsData.map((raw) {
      final e = Map<String, dynamic>.from(raw as Map);
      final dateStr = e['event_date'] as String? ?? '';
      final ticketTypes = (e['ticket_types'] as List<dynamic>?) ?? const [];
      final startingPrice = ticketTypes.isNotEmpty
          ? (ticketTypes[0]['price'] as num?)?.toDouble() ?? 0
          : 0.0;
      return EventSearchResult(
        id: e['id'] as String,
        title: e['title'] as String? ?? '',
        location: e['location'] as String? ?? '',
        lat: (e['latitude'] as num?)?.toDouble() ?? fallbackLat,
        lng: (e['longitude'] as num?)?.toDouble() ?? fallbackLng,
        date: DateTime.tryParse(dateStr) ?? DateTime.now(),
        time: e['start_time'] as String? ?? '',
        totalSpots: (e['total_capacity'] as int?) ?? 0,
        soldSpots: (e['tickets_sold'] as int?) ?? 0,
        price: startingPrice,
        imageUrl: e['cover_url'] as String?,
        proName: eventUserMap[e['pro_id'] as String?],
      );
    }).toList();
  }

  /// Ouvre un canal Realtime sur la table `events`. Le callback est invoqué
  /// pour chaque INSERT/UPDATE/DELETE — le Notifier rafraîchit la liste.
  RealtimeChannel subscribeEvents(void Function() onChange) {
    return _supabase
        .channel('public:events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  /// Ferme le canal Realtime. Toujours appelé dans le dispose du Notifier.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}

/// Intermédiaire en phase 1 — on garde city/country à côté du ProSearchResult
/// pour les réutiliser en phase 2 (geocoding) sans re-parser la Map DB.
class _PendingPro {
  const _PendingPro({
    required this.proResult,
    required this.city,
    required this.country,
  });

  final ProSearchResult proResult;
  final String city;
  final String country;
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(supabase: Supabase.instance.client);
});
