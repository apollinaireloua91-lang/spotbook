/// Sous-domaine Stream du type `customer-xxxx` (sans `.cloudflarestream.com`).
String? cloudflareStreamSubdomain() {
  const raw = String.fromEnvironment('CLOUDFLARE_CUSTOMER_CODE');
  if (raw.isEmpty) return null;
  if (raw.contains('cloudflarestream.com')) {
    final host = raw.replaceFirst(RegExp(r'^https?://'), '').split('/').first;
    return host.replaceAll('.cloudflarestream.com', '');
  }
  return raw.startsWith('customer-') ? raw : 'customer-$raw';
}

/// Hôte complet, ex. `customer-abc.cloudflarestream.com`.
String? cloudflareStreamHost() {
  final sub = cloudflareStreamSubdomain();
  if (sub == null) return null;
  return '$sub.cloudflarestream.com';
}

/// Identifiant vidéo Cloudflare depuis une ligne JSON Supabase (`cloudflare_id` ou `cloudflare_uid`).
String? cloudflareIdFromRow(Map<String, dynamic> json) {
  final a = json['cloudflare_id'] as String?;
  final b = json['cloudflare_uid'] as String?;
  final id = (a != null && a.isNotEmpty) ? a : b;
  if (id == null || id.isEmpty) return null;
  return id;
}

/// Manifest HLS public Stream.
/// Format : `https://<subdomain>.cloudflarestream.com/<VIDEO_ID>/manifest/video.m3u8`
String? cloudflareManifestUrl(String? cloudflareId) {
  if (cloudflareId == null || cloudflareId.isEmpty) return null;
  final host = cloudflareStreamHost();
  if (host == null) return null;
  return 'https://$host/$cloudflareId/manifest/video.m3u8';
}

/// Miniature publique (même host que le manifest).
String? cloudflareThumbnailUrl(String? cloudflareId) {
  if (cloudflareId == null || cloudflareId.isEmpty) return null;
  final host = cloudflareStreamHost();
  if (host == null) return null;
  return 'https://$host/$cloudflareId/thumbnails/thumbnail.jpg';
}
