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
    this.nearbyProviders = const [],
    this.isLoading = false,
    this.hasError = false,
    this.selectedCategory = 'All',
    this.maxDistance = 50.0,
    this.minRating = 0.0,
    this.availableToday = false,
    this.maxPrice = 200.0,
    this.searchHistory = const [],
    this.showHistory = false,
    this.activeQuery,
  });

  final List<VideoModel>? results;
  final List<ProviderSearchResult> nearbyProviders;
  final bool isLoading;
  final bool hasError;
  final String selectedCategory;
  final double maxDistance;
  final double minRating;
  final bool availableToday;
  final double maxPrice;
  final List<String> searchHistory;
  final bool showHistory;
  final String? activeQuery;

  DiscoverState copyWith({
    List<VideoModel>? results,
    List<ProviderSearchResult>? nearbyProviders,
    bool? isLoading,
    bool? hasError,
    String? selectedCategory,
    double? maxDistance,
    double? minRating,
    bool? availableToday,
    double? maxPrice,
    List<String>? searchHistory,
    bool? showHistory,
    String? activeQuery,
    bool clearActiveQuery = false,
    bool clearResults = false,
  }) =>
      DiscoverState(
        results: clearResults ? null : (results ?? this.results),
        nearbyProviders: nearbyProviders ?? this.nearbyProviders,
        isLoading: isLoading ?? this.isLoading,
        hasError: hasError ?? this.hasError,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        maxDistance: maxDistance ?? this.maxDistance,
        minRating: minRating ?? this.minRating,
        availableToday: availableToday ?? this.availableToday,
        maxPrice: maxPrice ?? this.maxPrice,
        searchHistory: searchHistory ?? this.searchHistory,
        showHistory: showHistory ?? this.showHistory,
        activeQuery:
            clearActiveQuery ? null : (activeQuery ?? this.activeQuery),
      );
}

class DiscoverNotifier extends Notifier<DiscoverState> {
  Timer? _debounce;

  @override
  DiscoverState build() {
    _loadHistory();
    // Premier frame = chargement (évite « Aucun résultat » avant la requête Supabase).
    Future<void>.microtask(_loadDefault);
    return const DiscoverState(isLoading: true);
  }

  Future<void> _loadHistory() async {
    final box = await Hive.openBox<List<String>>('search_history');
    final history = box.get('history') ?? [];
    state = state.copyWith(searchHistory: history);
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final q = query.trim();
    final newHistory =
        [q, ...state.searchHistory.where((e) => e != q)].take(10).toList();
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
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final searchRepo = ref.read(discoverSearchRepositoryProvider);
      final videoRepo = ref.read(videoRepositoryProvider);

      // Coords are optional — getCurrentUserCoordinates() never throws.
      final coords = await searchRepo.getCurrentUserCoordinates();

      // PostgREST = liste complète ; RPC = distance / coords enrichis (sans écraser la liste).
      final providers = await searchRepo.fetchDiscoverProviders(
        clientLat: coords.lat,
        clientLng: coords.lng,
        radiusKm: state.maxDistance,
        textQuery: null,
        categoryChip: state.selectedCategory,
        minRating: state.minRating,
      );

      final videos = state.selectedCategory == 'All'
          ? await videoRepo.searchVideos('')
          : await videoRepo
              .getVideosByCategory(state.selectedCategory.toLowerCase());


      state = state.copyWith(
        results: videos,
        nearbyProviders: providers,
        isLoading: false,
        hasError: false,
        clearActiveQuery: true,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _loadDefault();
  }

  void setShowHistory(bool show) {
    state = state.copyWith(showHistory: show);
  }

  void setDistance(double v) => state = state.copyWith(maxDistance: v);

  void setRating(double v) => state = state.copyWith(minRating: v);

  void setPrice(double v) => state = state.copyWith(maxPrice: v);

  void setAvailableToday(bool v) => state = state.copyWith(availableToday: v);

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

  Future<void> reloadWithFilters() => _loadDefault();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _loadDefault();
      return;
    }
    _saveToHistory(query);
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final searchRepo = ref.read(discoverSearchRepositoryProvider);
      final videoRepo = ref.read(videoRepositoryProvider);
      final coords = await searchRepo.getCurrentUserCoordinates();

      final providers = await searchRepo.fetchDiscoverProviders(
        clientLat: coords.lat,
        clientLng: coords.lng,
        radiusKm: state.maxDistance,
        textQuery: query.trim(),
        categoryChip: state.selectedCategory,
        minRating: state.minRating,
      );

      final videos = await videoRepo.searchVideos(query.trim());


      state = state.copyWith(
        results: videos,
        nearbyProviders: providers,
        isLoading: false,
        hasError: false,
        activeQuery: query.trim(),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }
}

final discoverProvider = NotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
);
