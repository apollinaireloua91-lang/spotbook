import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/provider_search_result.dart';
import '../domain/video_model.dart';
import 'discover_search_repository.dart';
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
    this.showHistory = false,
    this.nearbyProviders = const [],
    this.activeQuery,
    this.error,
  });

  final List<VideoModel>? results;
  final bool isLoading;
  final String selectedCategory;
  final double maxDistance;
  final double minRating;
  final bool availableToday;
  final double maxPrice;
  final List<String> searchHistory;
  final bool showHistory;
  final List<ProviderSearchResult> nearbyProviders;
  final String? activeQuery;
  final String? error;

  bool get hasError => error != null;

  DiscoverState copyWith({
    List<VideoModel>? results,
    bool? isLoading,
    String? selectedCategory,
    double? maxDistance,
    double? minRating,
    bool? availableToday,
    double? maxPrice,
    List<String>? searchHistory,
    bool? showHistory,
    List<ProviderSearchResult>? nearbyProviders,
    String? activeQuery,
    String? error,
    bool clearResults = false,
    bool clearError = false,
    bool clearActiveQuery = false,
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
        showHistory: showHistory ?? this.showHistory,
        nearbyProviders: nearbyProviders ?? this.nearbyProviders,
        activeQuery: clearActiveQuery ? null : (activeQuery ?? this.activeQuery),
        error: clearError ? null : (error ?? this.error),
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

  void setShowHistory(bool show) =>
      state = state.copyWith(showHistory: show);

  void setDistance(double v) =>
      state = state.copyWith(maxDistance: v);

  void setRating(double v) =>
      state = state.copyWith(minRating: v);

  void setPrice(double v) =>
      state = state.copyWith(maxPrice: v);

  void setAvailableToday(bool v) =>
      state = state.copyWith(availableToday: v);

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
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      search(query);
    });
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(clearActiveQuery: true);
      _loadDefault();
      return;
    }
    _saveToHistory(query);
    state = state.copyWith(isLoading: true, activeQuery: query.trim());
    try {
      final videos = await ref.read(videoRepositoryProvider).searchVideos(query.trim());
      // Also search providers
      List<ProviderSearchResult> providers = [];
      try {
        providers = await ref.read(discoverSearchRepositoryProvider).getAllProviders();
      } catch (_) {}
      state = state.copyWith(results: videos, nearbyProviders: providers, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> reloadWithFilters() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      List<ProviderSearchResult> providers = [];
      try {
        providers = await ref.read(discoverSearchRepositoryProvider).getAllProviders(
          category: state.selectedCategory == 'All' ? null : state.selectedCategory,
        );
      } catch (_) {}
      final repo = ref.read(videoRepositoryProvider);
      final videos = state.selectedCategory == 'All'
          ? await repo.searchVideos(state.activeQuery ?? '')
          : await repo.getVideosByCategory(state.selectedCategory.toLowerCase());
      state = state.copyWith(results: videos, nearbyProviders: providers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final discoverProvider = NotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
  isAutoDispose: true,
);
