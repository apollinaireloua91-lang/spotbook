import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/video_model.dart';
import 'video_repository.dart';

class CommentsState {
  const CommentsState({
    this.comments = const [],
    this.isLoading = true,
  });
  final List<CommentModel> comments;
  final bool isLoading;

  CommentsState copyWith({
    List<CommentModel>? comments,
    bool? isLoading,
  }) =>
      CommentsState(
        comments: comments ?? this.comments,
        isLoading: isLoading ?? this.isLoading,
      );
}

class CommentsNotifier extends Notifier<CommentsState> {
  StreamSubscription<List<CommentModel>>? _subscription;

  @override
  CommentsState build() => const CommentsState();

  Future<void> loadComments(String videoId) async {
    state = state.copyWith(isLoading: true);
    try {
      final comments =
          await ref.read(videoRepositoryProvider).getComments(videoId);
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
    _subscribeRealtime(videoId);
  }

  void _subscribeRealtime(String videoId) {
    _subscription?.cancel();
    _subscription = ref
        .read(videoRepositoryProvider)
        .streamComments(videoId)
        .listen((newComments) {
      state = state.copyWith(comments: newComments);
    });
  }

  Future<void> addComment(String videoId, String content) async {
    try {
      final comment =
          await ref.read(videoRepositoryProvider).addComment(videoId, content);
      state = state.copyWith(comments: [comment, ...state.comments]);
    } catch (_) {}
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
  }
}

final commentsProvider = NotifierProvider<CommentsNotifier, CommentsState>(
  CommentsNotifier.new,
  isAutoDispose: true,
);
