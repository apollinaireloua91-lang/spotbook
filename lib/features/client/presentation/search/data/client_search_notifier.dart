import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/search_repository.dart';
import '../models/search_models.dart';

/// State immuable de la recherche Client. Ne contient pas de closures ni de
/// RealtimeChannel — ce dernier vit dans le Notifier (objet mutable).
class ClientSearchState {
  const ClientSearchState({
    this.pros = const [],
    this.events = const [],
    this.query = '',
    this.activeCategory = 'all',
    this.viewMode = 'list',
    this.selectedProId,
    this.isLoading = true,
    this.showDetailPanel = false,
    this.userLat,
    this.userLng,
    this.error,
  });

  final List<ProSearchResult> pros;
  final List<EventSearchResult> events;
  final String query;
  final String activeCategory;
  final String viewMode; // 'map' | 'list'
  final String? selectedProId;
  final bool isLoading;
  final bool showDetailPanel;
  final double? userLat;
  final double? userLng;
  final String? error;

  ProSearchResult? get selectedPro {
    if (selectedProId == null) return null;
    for (final p in pros) {
      if (p.id == selectedProId) return p;
    }
    return null;
  }

  ClientSearchState copyWith({
    List<ProSearchResult>? pros,
    List<EventSearchResult>? events,
    String? query,
    String? activeCategory,
    String? viewMode,
    String? selectedProId,
    bool? isLoading,
    bool? showDetailPanel,
    double? userLat,
    double? userLng,
    String? error,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return ClientSearchState(
      pros: pros ?? this.pros,
      events: events ?? this.events,
      query: query ?? this.query,
      activeCategory: activeCategory ?? this.activeCategory,
      viewMode: viewMode ?? this.viewMode,
      selectedProId:
          clearSelection ? null : (selectedProId ?? this.selectedProId),
      isLoading: isLoading ?? this.isLoading,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier Riverpod (ex-`ClientSearchCubit`). Orchestration pure : il
/// consomme `SearchRepository` pour tous les accès Supabase et conserve la
/// logique géoloc + filtrage/Haversine en mémoire.
class ClientSearchNotifier extends Notifier<ClientSearchState> {
  Timer? _debounce;
  List<ProSearchResult> _allPros = const [];
  RealtimeChannel? _eventsChannel;
  bool _disposed = false;

  @override
  ClientSearchState build() {
    // Riverpod appelle onDispose quand le provider est détruit (autoDispose).
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      final ch = _eventsChannel;
      if (ch != null) {
        // Fire-and-forget : le repository gère l'API asynchrone.
        ref.read(searchRepositoryProvider).unsubscribe(ch);
      }
    });
    // Chargement initial déclenché après build pour laisser Riverpod assigner
    // l'état initial avant toute mutation.
    Future.microtask(_loadInitialData);
    _subscribeToEvents();
    return const ClientSearchState();
  }

  // ── Initial load ──

  Future<void> _loadInitialData() async {
    if (_disposed) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final location = await _resolveUserLocation();
      final userLat = location.$1;
      final userLng = location.$2;

      final repo = ref.read(searchRepositoryProvider);
      final results = await Future.wait([
        repo.fetchPros(),
        repo.fetchUpcomingEvents(),
      ]);
      if (_disposed) return;

      final rawPros = results[0] as List<ProSearchResult>;
      final events = results[1] as List<EventSearchResult>;

      // Tous les Pros retournés par le repo ont des coordonnées (exactes ou
      // dérivées de leur ville via geocode-city). On calcule donc la distance
      // pour tous, plus besoin de garder 0 pour les fallbacks.
      final prosWithDist = rawPros
          .map((p) => p.copyWith(
                distKm: _haversineKm(userLat, userLng, p.lat, p.lng),
              ))
          .toList()
        ..sort((a, b) => a.distKm.compareTo(b.distKm));

      _allPros = prosWithDist;

      state = state.copyWith(
        pros: prosWithDist,
        events: events,
        userLat: userLat,
        userLng: userLng,
        isLoading: false,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Renvoie la position de l'utilisateur, ou les coordonnées de Montréal par
  /// défaut. Toute erreur (permission refusée, timeout) est absorbée.
  Future<(double, double)> _resolveUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        return (pos.latitude, pos.longitude);
      }
    } catch (_) {
      // Fallback silently
    }
    return (SearchRepository.fallbackLat, SearchRepository.fallbackLng);
  }

  // ── Search with debounce ──

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters(query: query);
    });
  }

  void filterByCategory(String category) {
    _applyFilters(category: category);
  }

  void toggleViewMode() {
    final next = state.viewMode == 'map' ? 'list' : 'map';
    state = state.copyWith(viewMode: next);
  }

  void selectPro(String? proId) {
    if (proId == null) {
      state = state.copyWith(clearSelection: true, showDetailPanel: false);
    } else {
      state = state.copyWith(selectedProId: proId, showDetailPanel: false);
    }
  }

  void openDetailPanel(String proId) {
    state = state.copyWith(selectedProId: proId, showDetailPanel: true);
  }

  void closeDetailPanel() {
    state = state.copyWith(showDetailPanel: false);
  }

  Future<void> refresh() => _loadInitialData();

  // ── Realtime events ──

  void _subscribeToEvents() {
    _eventsChannel = ref
        .read(searchRepositoryProvider)
        .subscribeEvents(_refreshEvents);
  }

  Future<void> _refreshEvents() async {
    try {
      final events =
          await ref.read(searchRepositoryProvider).fetchUpcomingEvents();
      if (_disposed) return;
      state = state.copyWith(events: events);
    } catch (_) {
      // Silently fail — events will refresh on next manual refresh.
    }
  }

  // ── Filter application ──

  void _applyFilters({String? query, String? category}) {
    final q = (query ?? state.query).toLowerCase().trim();
    final cat = category ?? state.activeCategory;
    final uLat = state.userLat ?? SearchRepository.fallbackLat;
    final uLng = state.userLng ?? SearchRepository.fallbackLng;

    var filtered = _allPros
        .map((p) => p.copyWith(
              distKm: _haversineKm(uLat, uLng, p.lat, p.lng),
            ))
        .toList();

    if (cat != 'all') {
      filtered = filtered.where((p) => p.category == cat).toList();
    }

    if (q.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q);
      }).toList();
    }

    filtered.sort((a, b) => a.distKm.compareTo(b.distKm));

    state = state.copyWith(
      pros: filtered,
      query: q,
      activeCategory: cat,
      clearSelection: true,
      showDetailPanel: false,
    );
  }

  // ── Haversine km ──

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return double.parse((R * c).toStringAsFixed(1));
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);
}

final clientSearchProvider =
    NotifierProvider<ClientSearchNotifier, ClientSearchState>(
  ClientSearchNotifier.new,
  isAutoDispose: true,
);
