import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/video_model.dart';
import 'video_repository.dart';

/// Feed TikTok du compte **pro** : uniquement **ses** vidéos (pas le flux client Découvrir).
class ProOwnFeedState {
  const ProOwnFeedState({
    this.videos = const [],
    this.isLoading = true,
    this.currentIndex = 0,
  });

  final List<VideoModel> videos;
  final bool isLoading;
  final int currentIndex;

  ProOwnFeedState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    int? currentIndex,
  }) =>
      ProOwnFeedState(
        videos: videos ?? this.videos,
        isLoading: isLoading ?? this.isLoading,
        currentIndex: currentIndex ?? this.currentIndex,
      );
}

class ProOwnFeedNotifier extends Notifier<ProOwnFeedState> {
  @override
  ProOwnFeedState build() {
    _load();
    return const ProOwnFeedState();
  }

  VideoRepository get _repo => ref.read(videoRepositoryProvider);

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, currentIndex: 0);
    try {
      final videos = await _repo
          .getMyVideosWithInteractions()
          .timeout(const Duration(seconds: 15));
      state = state.copyWith(videos: videos, isLoading: false, currentIndex: 0);
    } catch (_) {
      state = state.copyWith(videos: [], isLoading: false, currentIndex: 0);
    }
  }

  Future<void> refresh() => _load();

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void _updateVideo(int index, VideoModel updated) {
    final list = List<VideoModel>.from(state.videos);
    list[index] = updated;
    state = state.copyWith(videos: list);
  }

  void toggleLike(int index, bool liked) {
    final v = state.videos[index];
    final delta = liked ? 1 : -1;
    final nextCount = max(0, v.likesCount + delta);
    _updateVideo(
      index,
      v.copyWith(isLiked: liked, likesCount: nextCount),
    );
    if (liked) {
      _repo.likeVideo(v.id);
    } else {
      _repo.unlikeVideo(v.id);
    }
  }

  void toggleSave(int index, bool saved) {
    final v = state.videos[index];
    final delta = saved ? 1 : -1;
    final nextSaves = max(0, v.savesCount + delta);
    _updateVideo(
      index,
      v.copyWith(isSaved: saved, savesCount: nextSaves),
    );
    if (saved) {
      _repo.saveVideo(v.id);
    } else {
      _repo.unsaveVideo(v.id);
    }
  }
}

final proOwnFeedProvider =
    NotifierProvider<ProOwnFeedNotifier, ProOwnFeedState>(
  ProOwnFeedNotifier.new,
  isAutoDispose: true,
);
