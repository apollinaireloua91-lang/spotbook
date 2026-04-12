import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../../core/services/cloudflare_stream_service.dart';

/// Steps in the video upload pipeline.
enum UploadStep { idle, capturing, previewing, compressing, uploading, processing, done, error }

class VideoUploadState extends Equatable {
  const VideoUploadState({
    this.step = UploadStep.idle,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.videoId,
  });

  final UploadStep step;

  /// Upload progress from 0.0 to 1.0.
  final double uploadProgress;

  final String? errorMessage;

  /// Supabase video ID after successful insert.
  final String? videoId;

  bool get isWorking =>
      step == UploadStep.compressing ||
      step == UploadStep.uploading ||
      step == UploadStep.processing;

  VideoUploadState copyWith({
    UploadStep? step,
    double? uploadProgress,
    String? errorMessage,
    String? videoId,
    bool clearError = false,
    bool clearVideoId = false,
  }) {
    return VideoUploadState(
      step: step ?? this.step,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      videoId: clearVideoId ? null : (videoId ?? this.videoId),
    );
  }

  @override
  List<Object?> get props => [step, uploadProgress, errorMessage, videoId];
}

class VideoUploadCubit extends Cubit<VideoUploadState> {
  VideoUploadCubit({required CloudflareStreamService cfService})
      : _cfService = cfService,
        super(const VideoUploadState());

  final CloudflareStreamService _cfService;

  void setStep(UploadStep step) => emit(state.copyWith(step: step));

  void reset() => emit(const VideoUploadState());

  /// Run the full publish pipeline: compress → upload → submit metadata.
  Future<void> publishVideo({
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
  }) async {
    try {
      // ── Compress ──
      emit(state.copyWith(
        step: UploadStep.compressing,
        uploadProgress: 0.0,
        clearError: true,
        clearVideoId: true,
      ));

      final compressed = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
      );
      final compressedFile = compressed?.file;
      if (compressedFile == null) {
        throw Exception('La compression a échoué');
      }

      // ── Upload + metadata via CloudflareStreamService ──
      emit(state.copyWith(step: UploadStep.uploading, uploadProgress: 0.0));

      final videoId = await _cfService.publishVideo(
        videoFile: compressedFile,
        title: title,
        description: description,
        category: category,
        duration: duration,
        hashtags: hashtags,
        serviceId: serviceId,
        eventId: eventId,
        spotifyTrackTitle: spotifyTrackTitle,
        spotifyTrackArtist: spotifyTrackArtist,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
        },
      );

      // ── Done ──
      emit(state.copyWith(
        step: UploadStep.processing,
        uploadProgress: 1.0,
      ));

      // Brief delay so user sees "processing" state before transition
      await Future<void>.delayed(const Duration(milliseconds: 500));

      emit(state.copyWith(step: UploadStep.done, videoId: videoId));
    } catch (e) {
      emit(state.copyWith(
        step: UploadStep.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
