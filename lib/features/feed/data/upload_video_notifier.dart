import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';

import '../../../shared/utils/agent_debug_log.dart';
import '../../../shared/utils/cloudflare_stream_urls.dart';
import 'video_repository.dart';

String? _videoMimeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.m4v')) return 'video/x-m4v';
  return null;
}

class UploadVideoState {
  const UploadVideoState({
    this.videoFile,
    this.videoDuration,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.selectedCategory,
  });
  final XFile? videoFile;
  final double? videoDuration;
  final bool isUploading;
  final double uploadProgress;
  final String? selectedCategory;

  UploadVideoState copyWith({
    XFile? videoFile,
    double? videoDuration,
    bool? isUploading,
    double? uploadProgress,
    String? selectedCategory,
    bool clearVideo = false,
    bool clearCategory = false,
  }) =>
      UploadVideoState(
        videoFile: clearVideo ? null : (videoFile ?? this.videoFile),
        videoDuration: clearVideo ? null : (videoDuration ?? this.videoDuration),
        isUploading: isUploading ?? this.isUploading,
        uploadProgress: uploadProgress ?? this.uploadProgress,
        selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      );
}

class UploadVideoNotifier extends Notifier<UploadVideoState> {
  @override
  UploadVideoState build() => const UploadVideoState();

  void setCategory(String? cat) => state = state.copyWith(selectedCategory: cat);

  Future<bool> pickVideo() async {
    final file = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file == null) return false;
    final pathMime = _videoMimeFromPath(file.path);
    final xMime = file.mimeType?.toLowerCase();
    final mimeOk = pathMime != null ||
        xMime == 'video/mp4' ||
        xMime == 'video/quicktime' ||
        xMime == 'video/x-m4v';
    if (!mimeOk) return false;
    final info = await VideoCompress.getMediaInfo(file.path);
    final durationSec = (info.duration ?? 0) / 1000;
    if (durationSec > 60) return false;
    state = state.copyWith(videoFile: file, videoDuration: durationSec);
    return true;
  }

  void setProgress(double p) => state = state.copyWith(uploadProgress: p);

  Future<void> publish({
    required String title,
    required String description,
    required String hashtags,
    String? linkedServiceId,
  }) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0);
    try {
      final repo = ref.read(videoRepositoryProvider);
      final xfile = state.videoFile!;
      var pathMime = _videoMimeFromPath(xfile.path);
      final xMime = xfile.mimeType?.toLowerCase();
      pathMime ??= (xMime == 'video/mp4' ||
              xMime == 'video/quicktime' ||
              xMime == 'video/x-m4v')
          ? xMime
          : null;
      if (pathMime == null) {
        throw Exception('Format vidéo non supporté (mp4, mov, m4v)');
      }

      state = state.copyWith(uploadProgress: 0.1);
      final compressed = await VideoCompress.compressVideo(
        xfile.path,
        quality: VideoQuality.MediumQuality,
      );
      // Sur simulateur ou certains codecs, la compression échoue — on envoie l’original.
      final compressedFile = compressed?.file;
      final uploadPath = compressedFile?.path ?? xfile.path;

      final bytes = compressedFile != null
          ? await compressedFile.readAsBytes()
          : await xfile.readAsBytes();
      final rawBytes = bytes.length;
      if (rawBytes > 500 * 1024 * 1024) {
        throw Exception('Fichier trop volumineux');
      }

      final outMime = _videoMimeFromPath(uploadPath) ?? pathMime;

      state = state.copyWith(uploadProgress: 0.3);
      final s = Supabase.instance.client.auth.currentSession;
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H2',
        location: 'upload_video_notifier.dart:publish',
        message: 'Avant getCloudflareUploadUrl (après compression)',
        data: {
          'hasSession': s != null,
          'sessionExpired': s?.isExpired,
        },
      );
      // #endregion
      final uploadData = await repo.getCloudflareUploadUrl(
        fileSizeBytes: rawBytes,
        mimeType: outMime,
      );
      final cloudflareId = uploadData['videoId'] as String;
      final uploadUrl = uploadData['uploadURL'] as String;

      state = state.copyWith(uploadProgress: 0.5);
      final filename = xfile.name.isNotEmpty ? xfile.name : 'upload.mp4';
      final mimeParts = outMime.split('/');
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType(mimeParts.first, mimeParts.last),
        ));
      final uploadResponse = await request.send();
      if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
        throw Exception('Cloudflare upload failed (${uploadResponse.statusCode})');
      }

      state = state.copyWith(uploadProgress: 0.8);
      final tags = hashtags
          .split(',')
          .map((h) => h.trim().replaceAll('#', ''))
          .where((h) => h.isNotEmpty)
          .take(5)
          .toList();

      await repo.submitForModeration(
        title: title,
        description: description,
        category: state.selectedCategory!,
        duration: state.videoDuration,
        cloudflareId: cloudflareId,
        thumbnailUrl: cloudflareThumbnailUrl(cloudflareId) ?? '',
        hashtags: tags,
        serviceId: linkedServiceId,
      );

      state = state.copyWith(uploadProgress: 1.0);
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadProgress: 0);
      rethrow;
    }
    state = state.copyWith(isUploading: false, uploadProgress: 0);
  }
}

final uploadVideoProvider =
    NotifierProvider<UploadVideoNotifier, UploadVideoState>(
  UploadVideoNotifier.new,
  isAutoDispose: true,
);
