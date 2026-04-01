import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

final spotifyOAuthServiceProvider = Provider<SpotifyOAuthService>((ref) {
  return SpotifyOAuthService();
});

/// OAuth Spotify côté app : uniquement [clientId] + redirect (le secret reste sur Supabase).
class SpotifyOAuthService {
  SpotifyOAuthService();

  static const _scopes =
      'user-read-private playlist-read-private user-top-read user-library-read';

  static const clientId = String.fromEnvironment('SPOTIFY_CLIENT_ID');

  /// Doit être identique au Dashboard Spotify et à `SPOTIFY_REDIRECT_URI` (Edge Function).
  static const redirectUri = String.fromEnvironment(
    'SPOTIFY_REDIRECT_URI',
    defaultValue: 'app.spotbook://spotify-callback',
  );

  /// Même schéma que dans AndroidManifest / Info.plist (`app.spotbook`).
  String get callbackUrlScheme => 'app.spotbook';

  bool get isConfigured => clientId.isNotEmpty;

  /// Ouvre le navigateur / ASWebAuthenticationSession et renvoie le `code` OAuth.
  Future<String> authorizeInteractive() async {
    if (!isConfigured) {
      throw StateError('SPOTIFY_CLIENT_ID manquant dans .env');
    }
    final uri = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': _scopes,
      'show_dialog': 'true',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: callbackUrlScheme,
    );

    final returned = Uri.parse(result);
    final err = returned.queryParameters['error'];
    if (err != null) {
      final desc = returned.queryParameters['error_description'] ?? err;
      throw Exception(desc);
    }

    final code = returned.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('Code Spotify absent');
    }
    return code;
  }
}
