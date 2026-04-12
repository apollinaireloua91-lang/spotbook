import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/search_models.dart';

// ─── State ───────────────────────────────────────────────────────────

class ClientSearchState extends Equatable {
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
    try {
      return pros.firstWhere((p) => p.id == selectedProId);
    } catch (_) {
      return null;
    }
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

  @override
  List<Object?> get props => [
        pros,
        events,
        query,
        activeCategory,
        viewMode,
        selectedProId,
        isLoading,
        showDetailPanel,
        userLat,
        userLng,
        error,
      ];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class ClientSearchCubit extends Cubit<ClientSearchState> {
  ClientSearchCubit() : super(const ClientSearchState()) {
    _loadInitialData();
    _subscribeToEvents();
  }

  Timer? _debounce;
  List<ProSearchResult> _allPros = [];
  RealtimeChannel? _eventsChannel;

  // Fallback center (Montréal)
  static const _defaultLat = 45.5100;
  static const _defaultLng = -73.5700;

  // ── Initial load ──

  Future<void> _loadInitialData() async {
    emit(state.copyWith(isLoading: true));
    try {
      // Fetch user position via Geolocator
      double userLat = _defaultLat;
      double userLng = _defaultLng;
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
          userLat = pos.latitude;
          userLng = pos.longitude;
        }
      } catch (_) {
        // Fallback silently to default Montréal coords
      }

      final supabase = Supabase.instance.client;

      // Fetch pros with joined user data in a single query
      final prosData = await supabase
          .from('profiles_pro')
          .select(
              '*, users!id(full_name, display_name, avatar_url, username, latitude, longitude, city)')
          .eq('is_public', true)
          .eq('search_visible', true)
          .order('rating_average', ascending: false);

      final proIds =
          prosData.map((p) => p['id'] as String).toList();

      // Fetch services for all pros
      final servicesData = proIds.isEmpty
          ? <dynamic>[]
          : await supabase
              .from('services')
              .select('id, title, price, duration_minutes, pro_id')
              .inFilter('pro_id', proIds)
              .eq('is_active', true);

      final servicesMap = <String, List<ProService>>{};
      for (final s in servicesData) {
        final proId = s['pro_id'] as String;
        servicesMap.putIfAbsent(proId, () => []);
        final mins = s['duration_minutes'] as int? ?? 30;
        final dur = mins >= 60 ? '${mins ~/ 60}h${mins % 60 > 0 ? '${mins % 60}' : ''}' : '$mins min';
        servicesMap[proId]!.add(ProService(
          id: s['id'] as String,
          name: s['title'] as String? ?? '',
          duration: dur,
          price: (s['price'] as num?)?.toDouble() ?? 0,
        ));
      }

      final prosWithDist = prosData.map((raw) {
        final p = Map<String, dynamic>.from(raw as Map);
        final id = p['id'] as String;
        final u = (p['users'] as Map<String, dynamic>?) ?? {};
        // Use real GPS coordinates from users table, or from profiles_pro
        final rawLat = (u['latitude'] as num?)?.toDouble() ??
            (p['latitude'] as num?)?.toDouble();
        final rawLng = (u['longitude'] as num?)?.toDouble() ??
            (p['longitude'] as num?)?.toDouble();
        final hasReal = rawLat != null && rawLng != null;
        final lat = rawLat ?? _defaultLat;
        final lng = rawLng ?? _defaultLng;

        final services = servicesMap[id] ?? [];
        final prices = services.map((s) => s.price).toList()..sort();
        final priceRange = prices.isEmpty
            ? ''
            : prices.length == 1
                ? '${prices.first.toInt()}'
                : '${prices.first.toInt()}-${prices.last.toInt()}';

        return ProSearchResult(
          id: id,
          name: (u['full_name'] as String?) ??
              (p['business_name'] as String?) ??
              '',
          category: (p['category'] as String?) ?? '',
          location: (u['city'] as String?) ?? 'Montréal',
          lat: lat,
          lng: lng,
          rating: (p['rating_average'] as num?)?.toDouble() ?? 0,
          reviews: (p['review_count'] as int?) ?? 0,
          distKm: hasReal
              ? _haversineKm(userLat, userLng, lat, lng)
              : 0,
          priceRange: priceRange,
          online: false,
          avatarUrl: u['avatar_url'] as String?,
          services: services,
          hasRealCoords: hasReal,
        );
      }).toList()
        ..sort((a, b) => a.distKm.compareTo(b.distKm));

      // Fetch upcoming events — price lives in ticket_types, not events
      final eventsData = await supabase
          .from('events')
          .select('*, ticket_types(id, name, price, quantity, sold_count)')
          .eq('is_active', true)
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date');

      final eventProIds = eventsData
          .map((e) => e['pro_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final eventUsersData = eventProIds.isEmpty
          ? <dynamic>[]
          : await supabase
              .from('users')
              .select('id, full_name')
              .inFilter('id', eventProIds);

      final eventUserMap = <String, String>{
        for (final u in eventUsersData)
          u['id'] as String: u['full_name'] as String? ?? '',
      };

      final events = eventsData.map((raw) {
        final e = Map<String, dynamic>.from(raw as Map);
        final dateStr = e['event_date'] as String? ?? '';
        // Price comes from the first ticket type, not from the events table
        final ticketTypes =
            (e['ticket_types'] as List<dynamic>?) ?? [];
        final startingPrice = ticketTypes.isNotEmpty
            ? (ticketTypes[0]['price'] as num?)?.toDouble() ?? 0
            : 0.0;
        return EventSearchResult(
          id: e['id'] as String,
          title: e['title'] as String? ?? '',
          location: e['location'] as String? ?? '',
          lat: (e['latitude'] as num?)?.toDouble() ?? _defaultLat,
          lng: (e['longitude'] as num?)?.toDouble() ?? _defaultLng,
          date: DateTime.tryParse(dateStr) ?? DateTime.now(),
          time: e['start_time'] as String? ?? '',
          totalSpots: (e['total_capacity'] as int?) ?? 0,
          soldSpots: (e['tickets_sold'] as int?) ?? 0,
          price: startingPrice,
          imageUrl: e['cover_url'] as String?,
          proName: eventUserMap[e['pro_id'] as String?],
        );
      }).toList();

      _allPros = prosWithDist;

      if (!isClosed) {
        emit(state.copyWith(
          pros: prosWithDist,
          events: events,
          userLat: userLat,
          userLng: userLng,
          isLoading: false,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  // ── Search with debounce ──

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters(query: query);
    });
  }

  // ── Category filter ──

  void filterByCategory(String category) {
    _applyFilters(category: category);
  }

  // ── Toggle map / list ──

  void toggleViewMode() {
    final next = state.viewMode == 'map' ? 'list' : 'map';
    emit(state.copyWith(viewMode: next));
  }

  // ── Select pro (marker tap / card tap) ──

  void selectPro(String? proId) {
    if (proId == null) {
      emit(state.copyWith(clearSelection: true, showDetailPanel: false));
    } else {
      emit(state.copyWith(selectedProId: proId, showDetailPanel: false));
    }
  }

  // ── Open / close detail panel ──

  void openDetailPanel(String proId) {
    emit(state.copyWith(selectedProId: proId, showDetailPanel: true));
  }

  void closeDetailPanel() {
    emit(state.copyWith(showDetailPanel: false));
  }

  Future<void> refresh() => _loadInitialData();

  // ── Realtime subscription for events ──

  void _subscribeToEvents() {
    final supabase = Supabase.instance.client;
    _eventsChannel = supabase
        .channel('public:events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (_) => _refreshEvents(),
        )
        .subscribe();
  }

  Future<void> _refreshEvents() async {
    try {
      final supabase = Supabase.instance.client;

      final eventsData = await supabase
          .from('events')
          .select('*, ticket_types(id, name, price, quantity, sold_count)')
          .eq('is_active', true)
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date');

      final eventProIds = eventsData
          .map((e) => e['pro_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final eventUsersData = eventProIds.isEmpty
          ? <dynamic>[]
          : await supabase
              .from('users')
              .select('id, full_name')
              .inFilter('id', eventProIds);

      final eventUserMap = <String, String>{
        for (final u in eventUsersData)
          u['id'] as String: u['full_name'] as String? ?? '',
      };

      final events = eventsData.map((raw) {
        final e = Map<String, dynamic>.from(raw as Map);
        final dateStr = e['event_date'] as String? ?? '';
        final ticketTypes = (e['ticket_types'] as List<dynamic>?) ?? [];
        final startingPrice = ticketTypes.isNotEmpty
            ? (ticketTypes[0]['price'] as num?)?.toDouble() ?? 0
            : 0.0;
        return EventSearchResult(
          id: e['id'] as String,
          title: e['title'] as String? ?? '',
          location: e['location'] as String? ?? '',
          lat: (e['latitude'] as num?)?.toDouble() ?? _defaultLat,
          lng: (e['longitude'] as num?)?.toDouble() ?? _defaultLng,
          date: DateTime.tryParse(dateStr) ?? DateTime.now(),
          time: e['start_time'] as String? ?? '',
          totalSpots: (e['total_capacity'] as int?) ?? 0,
          soldSpots: (e['tickets_sold'] as int?) ?? 0,
          price: startingPrice,
          imageUrl: e['cover_url'] as String?,
          proName: eventUserMap[e['pro_id'] as String?],
        );
      }).toList();

      if (!isClosed) {
        emit(state.copyWith(events: events));
      }
    } catch (_) {
      // Silently fail — events will refresh on next manual refresh
    }
  }

  // ── Internal filter logic ──

  void _applyFilters({String? query, String? category}) {
    final q = (query ?? state.query).toLowerCase().trim();
    final cat = category ?? state.activeCategory;
    final uLat = state.userLat ?? _defaultLat;
    final uLng = state.userLng ?? _defaultLng;

    var filtered = _allPros.map((p) {
      return p.copyWith(
        distKm: p.hasRealCoords
            ? _haversineKm(uLat, uLng, p.lat, p.lng)
            : 0,
      );
    }).toList();

    // Category filter
    if (cat != 'all') {
      filtered = filtered.where((p) => p.category == cat).toList();
    }

    // Text search (AND with category)
    if (q.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q);
      }).toList();
    }

    filtered.sort((a, b) => a.distKm.compareTo(b.distKm));

    emit(state.copyWith(
      pros: filtered,
      query: q,
      activeCategory: cat,
      clearSelection: true,
      showDetailPanel: false,
    ));
  }

  // ── Haversine formula (km) ──

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth radius km
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

  @override
  Future<void> close() {
    _debounce?.cancel();
    if (_eventsChannel != null) {
      Supabase.instance.client.removeChannel(_eventsChannel!);
    }
    return super.close();
  }
}
