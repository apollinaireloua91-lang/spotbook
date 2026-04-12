/// État de liaison Spotify (sans tokens — renvoyé par l’Edge Function `spotify-account`).
class SpotifyAccountInfo {
  const SpotifyAccountInfo({
    required this.linked,
    this.expiresAt,
    this.spotifyUserId,
  });

  final bool linked;
  final String? expiresAt;
  final String? spotifyUserId;

  factory SpotifyAccountInfo.fromJson(Map<String, dynamic> json) {
    return SpotifyAccountInfo(
      linked: json['linked'] as bool? ?? false,
      expiresAt: json['expiresAt'] as String?,
      spotifyUserId: json['spotifyUserId'] as String?,
    );
  }
}
