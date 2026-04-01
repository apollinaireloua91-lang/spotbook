import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/video_model.dart';
import 'video_repository.dart';

enum FeedTab { discover, following }

class FeedState {
  const FeedState({
    this.videos = const [],
    this.isLoading = true,
    this.currentIndex = 0,
    this.isLoadingMore = false,
    this.activeTab = FeedTab.discover,
  });
  final List<VideoModel> videos;
  final bool isLoading;
  final int currentIndex;
  final bool isLoadingMore;
  final FeedTab activeTab;

  FeedState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    int? currentIndex,
    bool? isLoadingMore,
    FeedTab? activeTab,
  }) =>
      FeedState(
        videos: videos ?? this.videos,
        isLoading: isLoading ?? this.isLoading,
        currentIndex: currentIndex ?? this.currentIndex,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        activeTab: activeTab ?? this.activeTab,
      );
}

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    _loadFeed();
    return const FeedState();
  }

  VideoRepository get _repo => ref.read(videoRepositoryProvider);

  Future<void> _loadFeed() async {
    state = state.copyWith(isLoading: true, currentIndex: 0);
    try {
      final videos = state.activeTab == FeedTab.discover
          ? await _repo.getScoredVideos()
          : await _repo.getFollowingFeed();
      state = state.copyWith(videos: videos, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void switchTab(FeedTab tab) {
    if (tab == state.activeTab) return;
    state = state.copyWith(activeTab: tab, videos: [], currentIndex: 0);
    _loadFeed();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final offset = state.videos.length;
      final more = state.activeTab == FeedTab.discover
          ? await _repo.getMoreVideos(offset: offset)
          : await _repo.getFollowingFeed(offset: offset);
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

  void _updateVideo(int index, VideoModel updated) {
    final list = List<VideoModel>.from(state.videos);
    list[index] = updated;
    state = state.copyWith(videos: list);
  }

  void toggleLike(int index, bool liked) {
    final v = state.videos[index];
    _updateVideo(
      index,
      v.copyWith(
        isLiked: liked,
        likesCount: v.likesCount + (liked ? 1 : -1),
      ),
    );
    if (liked) {
      _repo.likeVideo(v.id);
    } else {
      _repo.unlikeVideo(v.id);
    }
  }

  void toggleSave(int index, bool saved) {
    final v = state.videos[index];
    _updateVideo(
      index,
      v.copyWith(
        isSaved: saved,
        savesCount: v.savesCount + (saved ? 1 : -1),
      ),
    );
    if (saved) {
      _repo.saveVideo(v.id);
    } else {
      _repo.unsaveVideo(v.id);
    }
  }

  void toggleFollow(int index, bool followed) {
    final v = state.videos[index];
    // Update all videos from this pro
    final list = List<VideoModel>.from(state.videos);
    for (int i = 0; i < list.length; i++) {
      if (list[i].proId == v.proId) {
        list[i] = list[i].copyWith(isFollowed: followed);
      }
    }
    state = state.copyWith(videos: list);
    if (followed) {
      _repo.followPro(v.proId);
    } else {
      _repo.unfollowPro(v.proId);
    }
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
  isAutoDispose: true,
);
