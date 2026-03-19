import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/favorite_model.dart';
import 'favorite_repository.dart';

// ─── Favorite IDs (optimistic toggle) ───────────────────────

class FavoriteIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final repo = ref.read(favoriteRepositoryProvider);
    final ids = await repo.getFavoriteIds();
    state = ids;
  }

  bool isFavorite(String targetId) => state.contains(targetId);

  Future<void> toggle({
    required String targetId,
    required String targetType,
    String? targetName,
    String? targetImageUrl,
    String? targetSubtitle,
  }) async {
    final repo = ref.read(favoriteRepositoryProvider);
    final wasFavorite = state.contains(targetId);

    // Optimistic update
    if (wasFavorite) {
      state = {...state}..remove(targetId);
    } else {
      state = {...state, targetId};
    }

    try {
      if (wasFavorite) {
        await repo.removeFavorite(targetId);
      } else {
        await repo.addFavorite(
          targetId: targetId,
          targetType: targetType,
          targetName: targetName,
          targetImageUrl: targetImageUrl,
          targetSubtitle: targetSubtitle,
        );
      }
    } catch (_) {
      // Revert on failure
      if (wasFavorite) {
        state = {...state, targetId};
      } else {
        state = {...state}..remove(targetId);
      }
    }
  }
}

final favoriteIdsProvider = NotifierProvider<FavoriteIdsNotifier, Set<String>>(
  FavoriteIdsNotifier.new,
  isAutoDispose: true,
);

// ─── Favorites list ─────────────────────────────────────────

class FavoritesListState {
  const FavoritesListState({
    this.proFavorites = const [],
    this.eventFavorites = const [],
    this.isLoading = true,
  });
  final List<FavoriteModel> proFavorites;
  final List<FavoriteModel> eventFavorites;
  final bool isLoading;

  FavoritesListState copyWith({
    List<FavoriteModel>? proFavorites,
    List<FavoriteModel>? eventFavorites,
    bool? isLoading,
  }) =>
      FavoritesListState(
        proFavorites: proFavorites ?? this.proFavorites,
        eventFavorites: eventFavorites ?? this.eventFavorites,
        isLoading: isLoading ?? this.isLoading,
      );
}

class FavoritesListNotifier extends Notifier<FavoritesListState> {
  @override
  FavoritesListState build() {
    _load();
    return const FavoritesListState();
  }

  Future<void> _load() async {
    final repo = ref.read(favoriteRepositoryProvider);
    final pros = await repo.getFavorites('pro');
    final events = await repo.getFavorites('event');
    state = state.copyWith(
      proFavorites: pros,
      eventFavorites: events,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }
}

final favoritesListProvider =
    NotifierProvider<FavoritesListNotifier, FavoritesListState>(
  FavoritesListNotifier.new,
  isAutoDispose: true,
);
