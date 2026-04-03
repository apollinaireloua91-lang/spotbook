import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of requesting a direct upload URL from Cloudflare Stream.
class UploadSession {
  const UploadSession({
    required this.uploadUrl,
    required this.videoUid,
  });

  /// TUS upload URL — send the file bytes here.
  final String uploadUrl;

  /// Cloudflare Stream UID (hex32).
  final String videoUid;

  /// HLS playback URL (available after processing).
  String get playbackUrl {
    const customerCode = String.fromEnvironment('CLOUDFLARE_CUSTOMER_CODE');
    return 'https://customer-$customerCode.cloudflarestream.com/$videoUid/manifest/video.m3u8';
  }

  /// Thumbnail URL (available after processing).
  String get thumbnailUrl {
    const customerCode = String.fromEnvironment('CLOUDFLARE_CUSTOMER_CODE');
    return 'https://customer-$customerCode.cloudflarestream.com/$videoUid/thumbnails/thumbnail.jpg';
  }
}

/// Service that handles the complete Cloudflare Stream upload pipeline:
/// 1. Request a direct upload URL via Supabase Edge Function
/// 2. Upload video bytes directly to Cloudflare via TUS protocol
/// 3. Submit metadata to Supabase for moderation
class CloudflareStreamService {
  CloudflareStreamService(this._supabase);

  final SupabaseClient _supabase;

  /// Chunk size for TUS upload — 1 MB for reliable progress tracking.
  static const int _chunkSize = 1024 * 1024;

  /// Step 1: Request a direct upload URL from the Edge Function.
  ///
  /// The Edge Function verifies the user is a Pro and calls Cloudflare's
  /// `direct_upload` endpoint to get a TUS-compatible upload URL.
  Future<UploadSession> requestUploadUrl({
    String? mimeType,
    int? fileSizeBytes,
  }) async {
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

  /// Step 2: Upload video file directly to Cloudflare via TUS protocol.
  ///
  /// Uses chunked upload (1MB) for progress tracking and memory efficiency.
  /// [onProgress] reports 0.0 → 1.0.
  Future<void> uploadVideo({
    required String uploadUrl,
    required File videoFile,
    required void Function(double progress) onProgress,
  }) async {
    final fileSize = await videoFile.length();
    if (fileSize == 0) throw Exception('Video file is empty');

    // TUS protocol: send the file via PATCH with Upload-Offset header
    final uri = Uri.parse(uploadUrl);
    int uploadedBytes = 0;

    final fileStream = videoFile.openSync();
    try {
      while (uploadedBytes < fileSize) {
        final remaining = fileSize - uploadedBytes;
        final chunkLen = remaining < _chunkSize ? remaining : _chunkSize;
        final chunk = fileStream.readSync(chunkLen);

        final request = http.Request('PATCH', uri)
          ..headers['Content-Type'] = 'application/offset+octet-stream'
          ..headers['Upload-Offset'] = '$uploadedBytes'
          ..headers['Tus-Resumable'] = '1.0.0'
          ..bodyBytes = chunk;

        final streamedResponse = await request.send();
        final statusCode = streamedResponse.statusCode;

        if (statusCode != 204 && statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          throw Exception('TUS upload failed ($statusCode): $body');
        }

        uploadedBytes += chunkLen;
        onProgress(uploadedBytes / fileSize);
      }
    } finally {
      fileStream.closeSync();
    }
  }

  /// Step 3: Submit video metadata to Supabase via the moderate-video Edge Function.
  ///
  /// This creates the video row in the `videos` table with status `processing`.
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
    final body = <String, dynamic>{
      'cloudflare_id': cloudflareId,
      'title': title,
      'description': description,
      'category': category,
      'hashtags': hashtags,
      if (duration != null) 'duration': duration,
      if (serviceId != null) 'service_id': serviceId,
      if (eventId != null) 'event_id': eventId,
    };

    final response = await _supabase.functions.invoke(
      'moderate-video',
      body: body,
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      final error = response.data is Map
          ? (response.data['error'] ?? 'Metadata submission failed')
          : 'Metadata submission failed';
      throw Exception(error);
    }

    final data = response.data as Map<String, dynamic>;
    return data['videoId'] as String;
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
