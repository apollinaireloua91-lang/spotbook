import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/realtime/realtime_events.dart';
import '../../../core/realtime/realtime_manager.dart';
import '../domain/video_model.dart';
import 'video_repository.dart';

/// Wall-clock budget for any feed-loading Supabase round-trip. The Dart
/// Supabase client has no default socket timeout, so without this the feed
/// spinner can hang forever if the network stalls (DNS failure, Cloudflare
/// origin down, RLS recursion, etc.). Matches `pro_own_feed_notifier` for
/// consistency.
const _feedLoadTimeout = Duration(seconds: 15);

/// Centralised error sink for feed failures. We never rethrow here — the feed
/// must degrade gracefully (empty state or last-known videos) rather than
/// crash — but swallowing without observability is the other failure mode we
/// refuse. debugPrint surfaces the cause in dev; Sentry keeps prod auditable.
void _reportFeedError(String where, Object e, StackTrace st) {
  if (kDebugMode) {
    debugPrint('FeedNotifier.$where failed: $e\n$st');
  }
  try {
    Sentry.captureException(e, stackTrace: st);
  } catch (_) {
    // Sentry not initialized (dev without DSN) — ignore.
  }
}

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
  StreamSubscription<RealtimeEvent>? _rtSub;

  @override
  FeedState build() {
    _listenRealtime();
    _loadInitial();
    ref.onDispose(() => _rtSub?.cancel());
    return const FeedState();
  }

  void _listenRealtime() {
    _rtSub = ref.read(realtimeManagerProvider).feedStream.listen((event) {
      switch (event) {
        case FeedNewPost(:final videoId):
          _onNewPost(videoId);
        case FeedPostUpdated(
            :final videoId,
            :final likesCount,
            :final commentsCount,
            :final viewsCount,
            :final savesCount,
          ):
          _onPostUpdated(
            videoId,
            likesCount: likesCount,
            commentsCount: commentsCount,
            viewsCount: viewsCount,
            savesCount: savesCount,
          );
        default:
          break;
      }
    });
  }

  /// Fetch the full video record and prepend it to the feed.
  Future<void> _onNewPost(String videoId) async {
    // Avoid duplicates
    if (state.videos.any((v) => v.id == videoId)) return;
    try {
      final repo = ref.read(videoRepositoryProvider);
      final freshVideos =
          await repo.getScoredVideos(limit: 1).timeout(_feedLoadTimeout);
      final match = freshVideos.where((v) => v.id == videoId);
      if (match.isNotEmpty) {
        state = state.copyWith(videos: [match.first, ...state.videos]);
      }
    } catch (e, st) {
      // Non-critical — user can still scroll to see new content — but we
      // still want to know when realtime inserts silently miss.
      _reportFeedError('_onNewPost', e, st);
    }
  }

  /// Update counters in-place without refetching.
  void _onPostUpdated(
    String videoId, {
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    int? savesCount,
  }) {
    final updated = state.videos.map((v) {
      if (v.id != videoId) return v;
      return v.copyWith(
        likesCount: likesCount ?? v.likesCount,
        commentsCount: commentsCount ?? v.commentsCount,
        viewsCount: viewsCount ?? v.viewsCount,
        savesCount: savesCount ?? v.savesCount,
      );
    }).toList();
    state = state.copyWith(videos: updated);
  }

  Future<void> _loadInitial() async {
    try {
      final repo = ref.read(videoRepositoryProvider);
      // Le tab Abonnements doit filtrer sur `follows` — auparavant on
      // retombait toujours sur getScoredVideos() (Discover), ce qui faisait
      // que les deux onglets affichaient le même contenu.
      // Timeout 15s — sans ça, un DNS qui stall ou un Supabase qui ne répond
      // pas laisse l'UI bloquée sur son spinner indéfiniment (bug feed client
      // remonté le 2026-04-21).
      final videos = await (state.activeTab == FeedTab.following
              ? repo.getFollowingFeed(offset: 0)
              : repo.getScoredVideos())
          .timeout(_feedLoadTimeout);
      state = state.copyWith(videos: videos, isLoading: false);
    } catch (e, st) {
      _reportFeedError('_loadInitial', e, st);
      // Empty list + isLoading=false → l'UI bascule sur l'empty state
      // « Aucune vidéo ». Jamais on ne laisse le spinner figé.
      state = state.copyWith(videos: [], isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = ref.read(videoRepositoryProvider);
      final more = await (state.activeTab == FeedTab.following
              ? repo.getFollowingFeed(offset: state.videos.length)
              : repo.getMoreVideos(offset: state.videos.length))
          .timeout(_feedLoadTimeout);
      state = state.copyWith(
        videos: [...state.videos, ...more],
        isLoadingMore: false,
      );
    } catch (e, st) {
      _reportFeedError('loadMore', e, st);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void switchTab(FeedTab tab) {
    if (tab == state.activeTab) return;
    state = state.copyWith(activeTab: tab, videos: [], currentIndex: 0, isLoading: true);
    _loadInitial();
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
    updated[index] = v.copyWith(
      isLiked: liked,
      likesCount: v.likesCount + (liked ? 1 : -1),
    );
    state = state.copyWith(videos: updated);

    // Sync with Supabase
    final repo = ref.read(videoRepositoryProvider);
    (liked ? repo.likeVideo(v.id) : repo.unlikeVideo(v.id)).catchError((_) {
      // Rollback on error
      final rollback = List<VideoModel>.from(state.videos);
      if (index < rollback.length) {
        rollback[index] = v;
        state = state.copyWith(videos: rollback);
      }
    });
  }

  void toggleSave(int index, bool saved) {
    final v = state.videos[index];
    final updated = List<VideoModel>.from(state.videos);
    updated[index] = v.copyWith(
      isSaved: saved,
      savesCount: v.savesCount + (saved ? 1 : -1),
    );
    state = state.copyWith(videos: updated);

    final repo = ref.read(videoRepositoryProvider);
    (saved ? repo.saveVideo(v.id) : repo.unsaveVideo(v.id)).catchError((_) {
      final rollback = List<VideoModel>.from(state.videos);
      if (index < rollback.length) {
        rollback[index] = v;
        state = state.copyWith(videos: rollback);
      }
    });
  }

  void toggleFollow(int index, bool followed) {
    final v = state.videos[index];
    // Update all videos from the same pro
    final updated = state.videos
        .map((video) => video.proId == v.proId
            ? video.copyWith(isFollowed: followed)
            : video)
        .toList();
    state = state.copyWith(videos: updated);

    final repo = ref.read(videoRepositoryProvider);
    (followed ? repo.followPro(v.proId) : repo.unfollowPro(v.proId))
        .catchError((_) {
      final rollback = state.videos
          .map((video) => video.proId == v.proId
              ? video.copyWith(isFollowed: !followed)
              : video)
          .toList();
      state = state.copyWith(videos: rollback);
    });
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
  isAutoDispose: true,
);
