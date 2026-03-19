import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/video_model.dart';
import 'video_repository.dart';

class DiscoverState {
  const DiscoverState({
    this.results,
    this.isLoading = false,
    this.selectedCategory = 'All',
    this.maxDistance = 50.0,
    this.minRating = 0.0,
    this.availableToday = false,
    this.maxPrice = 200.0,
    this.searchHistory = const [],
  });

  final List<VideoModel>? results;
  final bool isLoading;
  final String selectedCategory;
  final double maxDistance;
  final double minRating;
  final bool availableToday;
  final double maxPrice;
  final List<String> searchHistory;

  DiscoverState copyWith({
    List<VideoModel>? results,
    bool? isLoading,
    String? selectedCategory,
    double? maxDistance,
    double? minRating,
    bool? availableToday,
    double? maxPrice,
    List<String>? searchHistory,
    bool clearResults = false,
  }) =>
      DiscoverState(
        results: clearResults ? null : (results ?? this.results),
        isLoading: isLoading ?? this.isLoading,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        maxDistance: maxDistance ?? this.maxDistance,
        minRating: minRating ?? this.minRating,
        availableToday: availableToday ?? this.availableToday,
        maxPrice: maxPrice ?? this.maxPrice,
        searchHistory: searchHistory ?? this.searchHistory,
      );
}

class DiscoverNotifier extends Notifier<DiscoverState> {
  Timer? _debounce;

  @override
  DiscoverState build() {
    _loadHistory();
    _loadDefault();
    return const DiscoverState();
  }

  Future<void> _loadHistory() async {
    final box = await Hive.openBox<List<String>>('search_history');
    final history = box.get('history') ?? [];
    state = state.copyWith(searchHistory: history);
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final q = query.trim();
    final newHistory = [q, ...state.searchHistory.where((e) => e != q)].take(10).toList();
    state = state.copyWith(searchHistory: newHistory);
    final box = await Hive.openBox<List<String>>('search_history');
    await box.put('history', newHistory);
  }

  Future<void> clearHistory() async {
    state = state.copyWith(searchHistory: []);
    final box = await Hive.openBox<List<String>>('search_history');
    await box.put('history', []);
  }

  Future<void> _loadDefault() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(videoRepositoryProvider);
      final videos = state.selectedCategory == 'All'
          ? await repo.searchVideos('')
          : await repo.getVideosByCategory(state.selectedCategory.toLowerCase());
      state = state.copyWith(results: videos, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _loadDefault();
  }

  void setFilters({
    double? maxDistance,
    double? minRating,
    bool? availableToday,
    double? maxPrice,
  }) {
    state = state.copyWith(
      maxDistance: maxDistance,
      minRating: minRating,
      availableToday: availableToday,
      maxPrice: maxPrice,
    );
    // In a real app, we would re-trigger search with these filters
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      search(query);
    });
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _loadDefault();
      return;
    }
    _saveToHistory(query);
    state = state.copyWith(isLoading: true);
    try {
      final videos = await ref.read(videoRepositoryProvider).searchVideos(query.trim());
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
