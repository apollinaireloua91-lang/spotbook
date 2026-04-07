import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/utils/cloudflare_stream_urls.dart';

/// Result of requesting a direct upload URL from Cloudflare Stream.
class UploadSession {
  const UploadSession({
    required this.uploadUrl,
    required this.videoUid,
  });

  /// Direct upload URL — send the file bytes here via POST.
  final String uploadUrl;

  /// Cloudflare Stream UID (hex32).
  final String videoUid;

  /// HLS playback URL (available after processing).
  String get playbackUrl =>
      cloudflareManifestUrl(videoUid) ?? '';

  /// Thumbnail URL (available after processing).
  String get thumbnailUrl =>
      cloudflareThumbnailUrl(videoUid) ?? '';
}

/// Service that handles the complete Cloudflare Stream upload pipeline:
/// 1. Request a direct upload URL via Supabase Edge Function
/// 2. Upload video bytes directly to Cloudflare via multipart POST
/// 3. Submit metadata to Supabase (published immediately, no moderation)
class CloudflareStreamService {
  CloudflareStreamService(this._supabase);

  final SupabaseClient _supabase;

  /// Step 1: Request a direct upload URL from the Edge Function.
  ///
  /// The Edge Function verifies the user is a Pro and calls Cloudflare's
  /// `direct_upload` endpoint to get a TUS-compatible upload URL.
  Future<UploadSession> requestUploadUrl({
    String? mimeType,
    int? fileSizeBytes,
  }) async {
    await _supabase.auth.refreshSession();

    final body = <String, dynamic>{};
    if (mimeType != null) body['mimeType'] = mimeType;
    if (fileSizeBytes != null) body['fileSizeBytes'] = fileSizeBytes;

    final response = await _supabase.functions.invoke(
      'generate-cloudflare-upload-url',
      body: body,
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      final error = response.data is Map
          ? (response.data['error'] ?? 'Upload URL request failed')
          : 'Upload URL request failed';
      throw Exception(error);
    }

    final data = response.data as Map<String, dynamic>;

    // The edge function returns the Cloudflare response.
    // The upload URL is in result.uploadURL (direct_upload endpoint).
    final result = data['result'] as Map<String, dynamic>?;
    final uploadUrl = result?['uploadURL'] as String?;
    final uid = data['spotbook']?['uid'] as String? ?? result?['uid'] as String?;

    if (uploadUrl == null || uid == null) {
      throw Exception(
        'Invalid response from upload URL generation: missing uploadURL or uid',
      );
    }

    return UploadSession(uploadUrl: uploadUrl, videoUid: uid);
  }

  /// Step 2: Upload video file directly to Cloudflare via multipart POST.
  ///
  /// Streams the file for progress tracking and memory efficiency.
  /// [onProgress] reports 0.0 → 1.0.
  Future<void> uploadVideo({
    required String uploadUrl,
    required File videoFile,
    required void Function(double progress) onProgress,
  }) async {
    final fileSize = await videoFile.length();
    if (fileSize == 0) throw Exception('Video file is empty');

    final uri = Uri.parse(uploadUrl);

    // Build multipart form data with streaming for progress tracking.
    final boundary = 'SpotbookUpload${DateTime.now().millisecondsSinceEpoch}';
    final headerPart =
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="video.mp4"\r\n'
        'Content-Type: video/mp4\r\n'
        '\r\n';
    final footerPart = '\r\n--$boundary--\r\n';

    final headerBytes = headerPart.codeUnits;
    final footerBytes = footerPart.codeUnits;
    final totalSize = headerBytes.length + fileSize + footerBytes.length;

    final request = http.StreamedRequest('POST', uri);
    request.headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';
    request.contentLength = totalSize;

    // Start sending — the client begins reading from sink.
    final responseFuture = request.send();

    var bytesSent = 0;

    // Multipart header
    request.sink.add(headerBytes);
    bytesSent += headerBytes.length;

    // Stream video file in chunks
    await for (final chunk in videoFile.openRead()) {
      request.sink.add(chunk);
      bytesSent += chunk.length;
      onProgress(bytesSent / totalSize);
    }

    // Multipart footer
    request.sink.add(footerBytes);
    await request.sink.close();

    final response = await responseFuture;
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = await response.stream.bytesToString();
      throw Exception('Upload failed (${response.statusCode}): $body');
    }

    onProgress(1.0);
  }

  /// Step 3: Insert video metadata directly into the `videos` table.
  ///
  /// No moderation — videos publish immediately with status `approved`.
  Future<String> submitMetadata({
    required String cloudflareId,
    required String title,
    required String description,
    required String category,
    double? duration,
    List<String> hashtags = const [],
    String? serviceId,
    String? eventId,
    String? spotifyTrackTitle,
    String? spotifyTrackArtist,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final streamUrl = cloudflareManifestUrl(cloudflareId);
    final thumbUrl = cloudflareThumbnailUrl(cloudflareId);

    final row = <String, dynamic>{
      'pro_id': userId,
      'cloudflare_id': cloudflareId,
      'title': title,
      'description': description,
      'category': category,
      'hashtags': hashtags,
      'status': 'approved',
      'visibility': 'public',
      if (streamUrl != null) 'stream_url': streamUrl,
      if (thumbUrl != null) 'thumbnail_url': thumbUrl,
      if (duration != null) 'duration_seconds': duration.round(),
      if (serviceId != null) 'service_id': serviceId,
      if (eventId != null) 'event_id': eventId,
      if (spotifyTrackTitle != null) 'spotify_track_title': spotifyTrackTitle,
      if (spotifyTrackArtist != null) 'spotify_track_artist': spotifyTrackArtist,
    };

    final response = await _supabase
        .from('videos')
        .insert(row)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Convenience: run the full upload pipeline in one call.
  ///
  /// [onProgress] reports combined progress: 0.0 → 1.0 across all steps.
  Future<String> publishVideo({
    required File videoFile,
    required String title,
    required String description,
    required String category,
    double? duration,
    List<String> hashtags = const [],
    String? serviceId,
    String? eventId,
    String? spotifyTrackTitle,
    String? spotifyTrackArtist,
    required void Function(double progress) onProgress,
  }) async {
    // Phase 1: Get upload URL (0% → 5%)
    onProgress(0.0);
    final session = await requestUploadUrl(
      fileSizeBytes: await videoFile.length(),
    );
    onProgress(0.05);

    // Phase 2: Upload video (5% → 90%)
    await uploadVideo(
      uploadUrl: session.uploadUrl,
      videoFile: videoFile,
      onProgress: (p) => onProgress(0.05 + p * 0.85),
    );

    // Phase 3: Submit metadata (90% → 100%)
    onProgress(0.90);
    final videoId = await submitMetadata(
      cloudflareId: session.videoUid,
      title: title,
      description: description,
      category: category,
      duration: duration,
      hashtags: hashtags,
      serviceId: serviceId,
      eventId: eventId,
      spotifyTrackTitle: spotifyTrackTitle,
      spotifyTrackArtist: spotifyTrackArtist,
    );
    onProgress(1.0);

    return videoId;
  }
}
