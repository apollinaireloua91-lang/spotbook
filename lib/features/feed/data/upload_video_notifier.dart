import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';

import '../../../core/services/cloudflare_stream_service.dart';

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
      final cfService = CloudflareStreamService(Supabase.instance.client);

      // Compress
      state = state.copyWith(uploadProgress: 0.05);
      final compressed = await VideoCompress.compressVideo(
        state.videoFile!.path,
        quality: VideoQuality.MediumQuality,
      );
      final compressedFile = compressed?.file;
      if (compressedFile == null) throw Exception('Compression failed');

      state = state.copyWith(uploadProgress: 0.10);

      // Parse hashtags
      final tags = hashtags
          .split(',')
          .map((h) => h.trim().replaceAll('#', ''))
          .where((h) => h.isNotEmpty)
          .take(5)
          .toList();

      // Full pipeline: get URL → TUS upload → submit metadata
      await cfService.publishVideo(
        videoFile: compressedFile,
        title: title,
        description: description,
        category: state.selectedCategory!,
        duration: state.videoDuration,
        hashtags: tags,
        serviceId: linkedServiceId,
        onProgress: (progress) {
          // Scale from 0.10 to 1.0 (compression took 0-0.10)
          state = state.copyWith(uploadProgress: 0.10 + progress * 0.90);
        },
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
