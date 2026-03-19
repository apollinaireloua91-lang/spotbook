import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/video_model.dart';
import 'video_repository.dart';

class DiscoverState {
  const DiscoverState({
    this.results,
    this.isLoading = false,
    this.selectedFilter = 'All',
  });
  final List<VideoModel>? results;
  final bool isLoading;
  final String selectedFilter;

  DiscoverState copyWith({
    List<VideoModel>? results,
    bool? isLoading,
    String? selectedFilter,
    bool clearResults = false,
  }) =>
      DiscoverState(
        results: clearResults ? null : (results ?? this.results),
        isLoading: isLoading ?? this.isLoading,
        selectedFilter: selectedFilter ?? this.selectedFilter,
      );
}

class DiscoverNotifier extends Notifier<DiscoverState> {
  @override
  DiscoverState build() {
    _loadDefault();
    return const DiscoverState();
  }

  Future<void> _loadDefault() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(videoRepositoryProvider);
      final videos = state.selectedFilter == 'All'
          ? await repo.searchVideos('')
          : await repo.getVideosByCategory(state.selectedFilter.toLowerCase());
      state = state.copyWith(results: videos, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    _loadDefault();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _loadDefault();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final videos =
          await ref.read(videoRepositoryProvider).searchVideos(query.trim());
      state = state.copyWith(results: videos, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final discoverProvider = NotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
  isAutoDispose: true,
);
