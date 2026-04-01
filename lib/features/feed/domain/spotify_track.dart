class SpotifyTrack {
  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    this.albumArt,
    this.previewUrl,
    this.durationMs = 0,
    this.spotifyUri,
  });

  final String id;
  final String name;
  final String artist;
  final String? albumArt;
  final String? previewUrl;
  final int durationMs;
  final String? spotifyUri;

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) => SpotifyTrack(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        artist: json['artist'] as String? ?? '',
        albumArt: json['albumArt'] as String?,
        previewUrl: json['previewUrl'] as String?,
        durationMs: json['durationMs'] as int? ?? 0,
        spotifyUri: json['spotifyUri'] as String?,
      );

  String get durationFormatted {
    final total = durationMs ~/ 1000;
    final min = total ~/ 60;
    final sec = total % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
