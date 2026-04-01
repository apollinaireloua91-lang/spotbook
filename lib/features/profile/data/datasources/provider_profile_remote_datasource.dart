import 'dart:developer' show log;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/utils/cloudflare_stream_urls.dart';
import '../../../reviews/domain/review_model.dart';
import '../../domain/entities/provider_profile_data.dart';

class ProviderProfileRemoteDatasource {
  const ProviderProfileRemoteDatasource(this._client);

  final SupabaseClient _client;

  /// Charge le profil puis les listes associées (les listes peuvent échouer sans bloquer l’écran).
  Future<ProviderProfileData> getProviderProfile(
    String providerId, {
    bool isOwnerView = false,
  }) async {
    final providerJson = await _fetchProvider(providerId);

    final servicesJson = await _safeList(() => _fetchServices(providerId));
    final videosJson = await _safeList(
      () => isOwnerView
          ? _fetchVideosOwner(providerId)
          : _fetchVideosPublicGrid(providerId),
    );
    final eventsJson = await _safeList(
      () => isOwnerView
          ? _fetchEvents(providerId)
          : _fetchEventsPublic(providerId),
    );

    return ProviderProfileData(
      provider: ProviderEntity.fromJson(providerJson),
      services: _parseServices(servicesJson),
      videos: _parseVideos(videosJson),
      events: _parseEvents(eventsJson),
    );
  }

  List<ServiceEntity> _parseServices(List<dynamic> raw) {
    final out = <ServiceEntity>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(ServiceEntity.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return out;
  }

  List<VideoEntity> _parseVideos(List<dynamic> raw) {
    final out = <VideoEntity>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(VideoEntity.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return out;
  }

  List<EventEntity> _parseEvents(List<dynamic> raw) {
    final out = <EventEntity>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(EventEntity.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return out;
  }

  Future<void> updateProviderProfile(ProviderEntity provider) async {
    final uid = provider.id;

    await Future.wait([
      // Mise à jour table users
      _client.from('users').update({
        'full_name': provider.fullName,
        'username': provider.username,
        'city': provider.location,
        'avatar_url': provider.avatarUrl,
        'cover_url': provider.coverUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid),

      // Mise à jour table profiles_pro
      _client.from('profiles_pro').update({
        'description': provider.bio,
        'category': provider.profession,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid),
    ]);
  }

  Future<List<dynamic>> _safeList(
    Future<List<dynamic>> Function() load,
  ) async {
    try {
      return await load();
    } catch (e, st) {
      log(
        'ProviderProfileRemoteDatasource subquery failed',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // ─── Requêtes privées ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchProvider(String providerId) async {
    return _client
        .from('profiles_pro')
        .select('*, users(*), social_connections(*)')
        .eq('id', providerId)
        .single();
  }

  Future<List<dynamic>> _fetchServices(String providerId) async {
    // Pas de filtre `is_active` en SQL : colonne parfois absente sur des bases distantes.
    final rows = await _client
        .from('services')
        .select()
        .eq('pro_id', providerId);
    return (rows as List).where((row) {
      final m = row as Map<String, dynamic>;
      final v = m['is_active'];
      if (v == null) return true;
      return v == true;
    }).toList();
  }

  /// Toutes les vidéos du compte pro (tous statuts) — onglet « Mes vidéos » / hub pro.
  Future<List<dynamic>> _fetchVideosOwner(String providerId) async {
    final rows = await _client
        .from('videos')
        .select()
        .eq('pro_id', providerId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
      final derived = cloudflareManifestUrl(m['cloudflare_id'] as String?);
      if (derived != null) m['stream_url'] = derived;
      return m;
    }).toList();
  }

  /// Alias historique (bloc profil public) — aligné sur [getProviderProfile] vue client.
  Future<ProviderProfileData> getProviderProfileForPublicClientView(
    String providerId,
  ) =>
      getProviderProfile(providerId, isOwnerView: false);

  Future<List<dynamic>> _fetchVideosPublicGrid(String providerId) async {
    final rows = await _client
        .from('videos')
        .select()
        .eq('pro_id', providerId)
        .eq('status', 'approved')
        .eq('visibility', 'public')
        .order('created_at', ascending: false)
        .limit(60);
    return (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
      final derived = cloudflareManifestUrl(m['cloudflare_id'] as String?);
      if (derived != null) m['stream_url'] = derived;
      return m;
    }).toList();
  }

  Future<List<dynamic>> _fetchEventsPublic(String providerId) async {
    return _client
        .from('events')
        .select()
        .eq('pro_id', providerId)
        .gte('event_date', DateTime.now().toIso8601String())
        .order('event_date')
        .limit(50);
  }

  Future<List<dynamic>> _fetchEvents(String providerId) async {
    return _client
        .from('events')
        .select()
        .eq('pro_id', providerId)
        .gte('event_date', DateTime.now().toIso8601String())
        .order('event_date')
        .limit(3);
  }

  /// Upsert un lien social dans la table social_connections.
  Future<void> upsertSocialLink({
    required String proId,
    required String platform,
    required String url,
  }) async {
    // Extraire le handle depuis l'URL (dernière partie du path).
    final uri = Uri.tryParse(url);
    final handle = uri?.pathSegments.lastWhere(
          (s) => s.isNotEmpty,
          orElse: () => platform,
        ) ??
        platform;

    await _client.from('social_connections').upsert(
      {
        'pro_id': proId,
        'platform': platform,
        'handle': handle,
        'url': url,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'pro_id,platform',
    );
  }

  /// Avis publics avec nom de prestation (via réservation).
  Future<List<ReviewModel>> fetchReviewsForPro(String proId) async {
    try {
      final data = await _client
          .from('reviews')
          .select(
            '*, users:client_id(full_name, avatar_url), bookings(services(name, title))',
          )
          .eq('pro_id', proId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      log('fetchReviewsForPro failed', error: e, stackTrace: st);
      return [];
    }
  }
}
