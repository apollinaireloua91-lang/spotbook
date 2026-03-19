import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/video_model.dart';
import 'video_repository.dart';

class FeedState {
  const FeedState({
    this.videos = const [],
    this.isLoading = true,
    this.currentIndex = 0,
    this.isLoadingMore = false,
  });
  final List<VideoModel> videos;
  final bool isLoading;
  final int currentIndex;
  final bool isLoadingMore;

  FeedState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    int? currentIndex,
    bool? isLoadingMore,
  }) =>
      FeedState(
        videos: videos ?? this.videos,
        isLoading: isLoading ?? this.isLoading,
        currentIndex: currentIndex ?? this.currentIndex,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    _loadInitial();
    return const FeedState();
  }

  Future<void> _loadInitial() async {
    try {
      final videos = await ref.read(videoRepositoryProvider).getScoredVideos();
      state = state.copyWith(videos: videos, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await ref
          .read(videoRepositoryProvider)
          .getMoreVideos(offset: state.videos.length);
      state = state.copyWith(
        videos: [...state.videos, ...more],
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
    if (index > state.videos.length - 3) {
      loadMore();
    }
  }

  void toggleLike(int index, bool liked) {
    final v = state.videos[index];
    final updated = List<VideoModel>.from(state.videos);
    updated[index] = VideoModel(
      id: v.id,
      proId: v.proId,
      cloudflareId: v.cloudflareId,
      streamUrl: v.streamUrl,
      thumbnailUrl: v.thumbnailUrl,
      title: v.title,
      description: v.description,
      category: v.category,
      hashtags: v.hashtags,
      status: v.status,
      rejectionReason: v.rejectionReason,
      likesCount: v.likesCount + (liked ? 1 : -1),
      commentsCount: v.commentsCount,
      viewsCount: v.viewsCount,
      flagCount: v.flagCount,
      createdAt: v.createdAt,
      proName: v.proName,
      proAvatarUrl: v.proAvatarUrl,
      proCity: v.proCity,
      isLiked: liked,
    );
    state = state.copyWith(videos: updated);
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
  isAutoDispose: true,
);
