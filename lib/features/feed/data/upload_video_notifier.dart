import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import 'video_repository.dart';

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
  }) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0);
    try {
      final repo = ref.read(videoRepositoryProvider);

      state = state.copyWith(uploadProgress: 0.1);
      final compressed = await VideoCompress.compressVideo(
        state.videoFile!.path,
        quality: VideoQuality.MediumQuality,
      );
      final compressedFile = compressed?.file;
      if (compressedFile == null) throw Exception('Compression failed');

      state = state.copyWith(uploadProgress: 0.3);
      final uploadData = await repo.getCloudflareUploadUrl();
      final cloudflareId = uploadData['videoId'] as String;

      state = state.copyWith(uploadProgress: 0.5);
      // TODO: Use proper TUS upload client in production
      await compressedFile.readAsBytes();

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
        thumbnailUrl:
            'https://customer-${dotenv.env["CLOUDFLARE_CUSTOMER_CODE"]}.cloudflarestream.com/$cloudflareId/thumbnails/thumbnail.jpg',
        hashtags: tags,
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
