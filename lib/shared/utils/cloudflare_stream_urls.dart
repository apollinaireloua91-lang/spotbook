import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URL manifest HLS Cloudflare Stream à partir de [cloudflareId] (customer subdomain).
String? cloudflareManifestUrl(String? cloudflareId) {
  if (cloudflareId == null || cloudflareId.isEmpty) return null;
  final code = dotenv.env['CLOUDFLARE_CUSTOMER_CODE'];
  if (code == null || code.isEmpty) return null;
  return 'https://customer-$code.cloudflarestream.com/$cloudflareId/manifest/video.m3u8';
}
