import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/spotify_account_info.dart';
import '../domain/spotify_track.dart';

final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  return SpotifyRepository(supabase: Supabase.instance.client);
});

class SpotifyRepository {
  SpotifyRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  Future<SpotifyAccountInfo> getAccountStatus() async {
    try {
      final res = await _supabase.functions.invoke('spotify-account');
      if (res.status != 200) {
        return const SpotifyAccountInfo(linked: false);
      }
      final data = res.data as Map<String, dynamic>? ?? {};
      return SpotifyAccountInfo.fromJson(data);
    } catch (_) {
      return const SpotifyAccountInfo(linked: false);
    }
  }

  /// Échange le code OAuth (après [SpotifyOAuthService.authorizeInteractive]).
  Future<void> exchangeOAuthCode(String code) async {
    final res = await _supabase.functions.invoke(
      'spotify-oauth-exchange',
      body: {'code': code},
    );
    if (res.status != 200) {
      final err = res.data is Map
          ? (res.data as Map)['error']?.toString()
          : 'Échec liaison Spotify';
      throw Exception(err ?? 'Échec liaison Spotify');
    }
  }

  Future<void> disconnect() async {
    final res = await _supabase.functions.invoke('spotify-disconnect');
    if (res.status != 200) {
      final err = res.data is Map
          ? (res.data as Map)['error']?.toString()
          : 'Déconnexion impossible';
      throw Exception(err ?? 'Déconnexion impossible');
    }
  }

  /// Titres les plus joués (compte Spotify lié uniquement).
  Future<List<SpotifyTrack>> getTopTracks({
    String timeRange = 'short_term',
  }) async {
    final res = await _supabase.functions.invoke(
      'spotify-top-tracks',
      body: {'time_range': timeRange},
    );
    if (res.status != 200) return [];
    final data = res.data as Map<String, dynamic>? ?? {};
    final linked = data['linked'] as bool? ?? false;
    if (!linked) return [];
    final tracks = data['tracks'] as List<dynamic>? ?? [];
    return tracks
        .map((e) => SpotifyTrack.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Recherche (token pro si lié, sinon client credentials).
  Future<List<SpotifyTrack>> searchTracks(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _supabase.functions.invoke(
      'spotify-search',
      body: {'query': query.trim(), 'type': 'track'},
    );
    if (res.status != 200) return [];
    final data = res.data as Map<String, dynamic>? ?? {};
    final tracks = data['tracks'] as List<dynamic>? ?? [];
    return tracks
        .map((e) => SpotifyTrack.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
