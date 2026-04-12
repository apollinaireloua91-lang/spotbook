import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/spotify_track.dart';
import 'spotify_repository.dart';

class SpotifySearchState {
  const SpotifySearchState({
    this.tracks = const [],
    this.isLoading = false,
    this.query = '',
    this.selectedTrack,
    this.showingTopTracks = false,
  });

  final List<SpotifyTrack> tracks;
  final bool isLoading;
  final String query;
  final SpotifyTrack? selectedTrack;
  final bool showingTopTracks;

  SpotifySearchState copyWith({
    List<SpotifyTrack>? tracks,
    bool? isLoading,
    String? query,
    SpotifyTrack? selectedTrack,
    bool? showingTopTracks,
    bool clearSelection = false,
  }) =>
      SpotifySearchState(
        tracks: tracks ?? this.tracks,
        isLoading: isLoading ?? this.isLoading,
        query: query ?? this.query,
        selectedTrack:
            clearSelection ? null : (selectedTrack ?? this.selectedTrack),
        showingTopTracks: showingTopTracks ?? this.showingTopTracks,
      );
}

class SpotifySearchNotifier extends Notifier<SpotifySearchState> {
  Timer? _debounce;

  @override
  SpotifySearchState build() => const SpotifySearchState();

  /// Au premier affichage de la sheet musique : reset + top tracks si compte lié.
  Future<void> prepareSheet() async {
    _debounce?.cancel();
    state = const SpotifySearchState();
    await _loadTopTracks();
  }

  void search(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.trim().length < 2) {
      scheduleMicrotask(() => _loadTopTracks());
      return;
    }
    state = state.copyWith(isLoading: true, showingTopTracks: false);
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch());
  }

  Future<void> _loadTopTracks() async {
    final repo = ref.read(spotifyRepositoryProvider);
    final status = await repo.getAccountStatus();
    if (!status.linked) {
      state = state.copyWith(
        tracks: [],
        isLoading: false,
        showingTopTracks: false,
      );
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final tracks = await repo.getTopTracks();
      state = state.copyWith(
        tracks: tracks,
        isLoading: false,
        showingTopTracks: true,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, showingTopTracks: false);
    }
  }

  Future<void> _doSearch() async {
    final repo = ref.read(spotifyRepositoryProvider);
    try {
      final results = await repo.searchTracks(state.query);
      state = state.copyWith(
        tracks: results,
        isLoading: false,
        showingTopTracks: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectTrack(SpotifyTrack track) {
    state = state.copyWith(selectedTrack: track);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  void reset() {
    _debounce?.cancel();
    state = const SpotifySearchState();
  }
}

final spotifySearchProvider =
    NotifierProvider<SpotifySearchNotifier, SpotifySearchState>(
  SpotifySearchNotifier.new,
);
