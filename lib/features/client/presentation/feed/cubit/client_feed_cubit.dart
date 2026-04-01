import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../feed/data/video_repository.dart';
import '../../../../feed/domain/video_model.dart';
import '../../../../notifications/data/notification_repository.dart';
import '../../../../feed/data/feed_notifier.dart';

/// État du feed client (Découvrir / Abonnements) — aligné sur [VideoModel] / table `videos`.
class ClientFeedState extends Equatable {
  const ClientFeedState({
    this.videos = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.currentIndex = 0,
    this.activeTab = FeedTab.discover,
    this.unreadNotifications = 0,
    this.error,
  });

  final List<VideoModel> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentIndex;
  final FeedTab activeTab;
  final int unreadNotifications;
  final String? error;

  ClientFeedState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentIndex,
    FeedTab? activeTab,
    int? unreadNotifications,
    String? error,
    bool clearError = false,
  }) {
    return ClientFeedState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentIndex: currentIndex ?? this.currentIndex,
      activeTab: activeTab ?? this.activeTab,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        videos,
        isLoading,
        isLoadingMore,
        currentIndex,
        activeTab,
        unreadNotifications,
        error,
      ];
}

class ClientFeedCubit extends Cubit<ClientFeedState> {
  ClientFeedCubit({
    required VideoRepository videoRepository,
    required NotificationRepository notificationRepository,
  })  : _video = videoRepository,
        _notifications = notificationRepository,
        super(const ClientFeedState()) {
    Future<void>.microtask(() async {
      await refreshUnreadCount();
      await _loadFeed();
    });
  }

  final VideoRepository _video;
  final NotificationRepository _notifications;

  Future<void> refreshUnreadCount() async {
    try {
      final n = await _notifications.getUnreadCount();
      if (!isClosed) emit(state.copyWith(unreadNotifications: n));
    } catch (_) {}
  }

  Future<void> _loadFeed() async {
    emit(state.copyWith(isLoading: true, currentIndex: 0, error: null));
    try {
      final list = state.activeTab == FeedTab.discover
          ? await _video.getScoredVideos()
          : await _video.getFollowingFeed();
      if (!isClosed) {
        emit(state.copyWith(videos: list, isLoading: false));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          isLoading: false,
          error: e.toString(),
        ));
      }
    }
  }

  Future<void> switchTab(FeedTab tab) async {
    if (tab == state.activeTab) return;
    emit(state.copyWith(
      activeTab: tab,
      videos: [],
      currentIndex: 0,
      isLoading: true,
    ));
    await _loadFeed();
  }

  void setCurrentIndex(int index) {
    emit(state.copyWith(currentIndex: index));
    if (index > state.videos.length - 3) {
      loadMore();
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final offset = state.videos.length;
      final more = state.activeTab == FeedTab.discover
          ? await _video.getMoreVideos(offset: offset)
          : await _video.getFollowingFeed(offset: offset);
      if (!isClosed) {
        emit(state.copyWith(
          videos: [...state.videos, ...more],
          isLoadingMore: false,
        ));
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> toggleLike(int index, bool liked) async {
    if (index < 0 || index >= state.videos.length) return;
    final v = state.videos[index];
    _updateVideoAt(
      index,
      v.copyWith(
        isLiked: liked,
        likesCount: v.likesCount + (liked ? 1 : -1),
      ),
    );
    try {
      if (liked) {
        await _video.likeVideo(v.id);
      } else {
        await _video.unlikeVideo(v.id);
      }
    } catch (_) {
      _updateVideoAt(index, v);
      if (!isClosed) emit(state.copyWith(error: 'like_failed'));
    }
  }

  Future<void> toggleSave(int index, bool saved) async {
    if (index < 0 || index >= state.videos.length) return;
    final v = state.videos[index];
    _updateVideoAt(
      index,
      v.copyWith(
        isSaved: saved,
        savesCount: v.savesCount + (saved ? 1 : -1),
      ),
    );
    try {
      if (saved) {
        await _video.saveVideo(v.id);
      } else {
        await _video.unsaveVideo(v.id);
      }
    } catch (_) {
      _updateVideoAt(index, v);
      if (!isClosed) emit(state.copyWith(error: 'save_failed'));
    }
  }

  Future<void> toggleFollow(int index, bool followed) async {
    if (index < 0 || index >= state.videos.length) return;
    final v = state.videos[index];
    final previous = List<VideoModel>.from(state.videos);
    final list = List<VideoModel>.from(state.videos);
    for (var i = 0; i < list.length; i++) {
      if (list[i].proId == v.proId) {
        list[i] = list[i].copyWith(isFollowed: followed);
      }
    }
    emit(state.copyWith(videos: list));
    try {
      if (followed) {
        await _video.followPro(v.proId);
      } else {
        await _video.unfollowPro(v.proId);
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(videos: previous));
    }
  }

  void _updateVideoAt(int index, VideoModel updated) {
    final list = List<VideoModel>.from(state.videos);
    list[index] = updated;
    emit(state.copyWith(videos: list));
  }

  void clearTransientError() {
    if (state.error != null) emit(state.copyWith(clearError: true));
  }
}
