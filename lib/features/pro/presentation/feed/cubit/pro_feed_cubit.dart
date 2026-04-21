import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../feed/data/video_repository.dart';
import '../../../../feed/domain/video_model.dart';
import '../../../../notifications/data/notification_repository.dart';

/// Même pattern d'observabilité que `feed_notifier.dart` — on ne rethrow
/// jamais (l'UI doit juste annuler l'optimistic + afficher un toast), mais
/// on n'avale pas l'erreur sans trace : debugPrint en dev, Sentry en prod.
void _reportCubitError(String where, Object e, StackTrace st) {
  if (kDebugMode) {
    debugPrint('ProFeedCubit.$where failed: $e\n$st');
  }
  try {
    Sentry.captureException(e, stackTrace: st);
  } catch (_) {
    // Sentry pas initialisé (dev sans DSN) — on ignore.
  }
}

class ProFeedState extends Equatable {
  const ProFeedState({
    this.videos = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.currentIndex = 0,
    this.unreadNotif = 0,
    this.unreadRdv = 0,
    this.unreadTickets = 0,
    this.unreadMessages = 0,
    this.error,
  });

  final List<VideoModel> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentIndex;
  final int unreadNotif;
  final int unreadRdv;
  final int unreadTickets;
  final int unreadMessages;
  final String? error;

  ProFeedState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentIndex,
    int? unreadNotif,
    int? unreadRdv,
    int? unreadTickets,
    int? unreadMessages,
    String? error,
    bool clearError = false,
  }) {
    return ProFeedState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentIndex: currentIndex ?? this.currentIndex,
      unreadNotif: unreadNotif ?? this.unreadNotif,
      unreadRdv: unreadRdv ?? this.unreadRdv,
      unreadTickets: unreadTickets ?? this.unreadTickets,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        videos,
        isLoading,
        isLoadingMore,
        currentIndex,
        unreadNotif,
        unreadRdv,
        unreadTickets,
        unreadMessages,
        error,
      ];
}

class ProFeedCubit extends Cubit<ProFeedState> {
  ProFeedCubit({
    required VideoRepository videoRepository,
    required NotificationRepository notificationRepository,
  })  : _video = videoRepository,
        _notif = notificationRepository,
        super(const ProFeedState()) {
    Future<void>.microtask(() async {
      await refreshUnreadCounts();
      await _loadFeed();
    });
  }

  final VideoRepository _video;
  final NotificationRepository _notif;

  static const _rdvTypes = {'booking_new', 'booking_confirmed', 'booking_cancelled', 'booking_reminder'};
  static const _ticketTypes = {'ticket_sold', 'event_update', 'event_reminder'};
  static const _messageTypes = {'chat', 'message'};

  /// Refresh all 4 unread counters from the notifications table.
  Future<void> refreshUnreadCounts() async {
    try {
      final counts = await _notif.getUnreadCountsByCategory();
      int notif = 0, rdv = 0, tickets = 0, messages = 0;
      for (final entry in counts.entries) {
        final type = entry.key;
        final count = entry.value;
        if (_rdvTypes.contains(type)) {
          rdv += count;
        } else if (_ticketTypes.contains(type)) {
          tickets += count;
        } else if (_messageTypes.contains(type)) {
          messages += count;
        } else {
          notif += count;
        }
      }
      if (!isClosed) {
        emit(state.copyWith(
          unreadNotif: notif,
          unreadRdv: rdv,
          unreadTickets: tickets,
          unreadMessages: messages,
        ));
      }
    } catch (_) {}
  }

  Future<void> _loadFeed() async {
    emit(state.copyWith(isLoading: true, currentIndex: 0, error: null));
    try {
      final list = await _video.getScoredVideos();
      if (!isClosed) {
        emit(state.copyWith(videos: list, isLoading: false));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
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
      final more = await _video.getMoreVideos(offset: offset);
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
    } catch (e, st) {
      _reportCubitError('toggleLike', e, st);
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
    } catch (e, st) {
      _reportCubitError('toggleSave', e, st);
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
    } catch (e, st) {
      _reportCubitError('toggleFollow', e, st);
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

  Future<void> refresh() async {
    await refreshUnreadCounts();
    await _loadFeed();
  }
}
