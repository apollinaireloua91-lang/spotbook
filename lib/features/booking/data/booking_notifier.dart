import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/realtime/realtime_events.dart';
import '../../../core/realtime/realtime_manager.dart';
import '../domain/booking_models.dart';
import '../domain/service_addon_models.dart';
import 'booking_repository.dart';

// ─── Booking flow state ─────────────────────────────────────

class BookingFlowState {
  const BookingFlowState({
    this.step = 0,
    this.services = const [],
    this.selectedService,
    this.cart = const BookingCart(),
    this.promoCode,
    this.promoApplied = false,
    this.availableDates = const [],
    this.selectedDate,
    this.timeSlots = const [],
    this.selectedSlot,
    this.isLoading = false,
    this.isCreating = false,
    this.isPaying = false,
    this.bookingResult,
    this.clientSecret,
    this.error,
    this.personCount = 1,
  });

  final int step;
  final List<ServiceModel> services;
  final ServiceModel? selectedService;
  /// Multi-service cart (priority #1 feature). For single-service bookings,
  /// this cart has exactly 1 item and mirrors `selectedService`.
  final BookingCart cart;
  final PromoCodeModel? promoCode;
  final bool promoApplied;
  final List<String> availableDates;
  final String? selectedDate;
  final List<TimeSlotModel> timeSlots;
  final TimeSlotModel? selectedSlot;
  final bool isLoading;
  final bool isCreating;
  final bool isPaying;
  final Map<String, dynamic>? bookingResult;
  final String? clientSecret;
  final String? error;
  final int personCount;

  /// True when user has picked at least one service (multi-service flow).
  bool get hasCartItems => cart.items.isNotEmpty;

  /// Total duration in minutes across all cart items (services + their add-ons).
  int get cartTotalDurationMinutes => cart.totalDurationMinutes;

  /// Cart subtotal (services + add-ons, before promo).
  double get cartSubtotal => cart.subtotal;

  double get totalPrice {
    // New path: use cart if populated
    if (cart.items.isNotEmpty) {
      double price = cart.subtotal;
      if (promoCode != null) {
        if (promoCode!.discountType == 'percentage') {
          price -= price * promoCode!.discountValue / 100;
        } else {
          price -= promoCode!.discountValue;
        }
      }
      return price < 0 ? 0 : price;
    }
    // Legacy path: single selectedService (back-compat)
    if (selectedService == null) return 0;
    double price;
    if (selectedService!.isTraiteurService) {
      price = selectedService!.totalForPersons(personCount);
    } else {
      price = selectedService!.price;
    }
    if (promoCode != null) {
      if (promoCode!.discountType == 'percentage') {
        price -= price * promoCode!.discountValue / 100;
      } else {
        price -= promoCode!.discountValue;
      }
    }
    return price < 0 ? 0 : price;
  }

  double get depositPrice => (totalPrice * 0.30 * 100).roundToDouble() / 100;

  BookingFlowState copyWith({
    int? step,
    List<ServiceModel>? services,
    ServiceModel? selectedService,
    BookingCart? cart,
    PromoCodeModel? promoCode,
    bool? promoApplied,
    List<String>? availableDates,
    String? selectedDate,
    List<TimeSlotModel>? timeSlots,
    TimeSlotModel? selectedSlot,
    bool? isLoading,
    bool? isCreating,
    bool? isPaying,
    Map<String, dynamic>? bookingResult,
    String? clientSecret,
    String? error,
    int? personCount,
  }) =>
      BookingFlowState(
        step: step ?? this.step,
        services: services ?? this.services,
        selectedService: selectedService ?? this.selectedService,
        cart: cart ?? this.cart,
        promoCode: promoCode ?? this.promoCode,
        promoApplied: promoApplied ?? this.promoApplied,
        availableDates: availableDates ?? this.availableDates,
        selectedDate: selectedDate ?? this.selectedDate,
        timeSlots: timeSlots ?? this.timeSlots,
        selectedSlot: selectedSlot ?? this.selectedSlot,
        isLoading: isLoading ?? this.isLoading,
        isCreating: isCreating ?? this.isCreating,
        isPaying: isPaying ?? this.isPaying,
        bookingResult: bookingResult ?? this.bookingResult,
        clientSecret: clientSecret ?? this.clientSecret,
        error: error,
        personCount: personCount ?? this.personCount,
      );
}

class BookingFlowNotifier extends Notifier<BookingFlowState> {
  late final BookingRepository _repo;
  late final String _proId;
  RealtimeChannel? _slotChannel;

  @override
  BookingFlowState build() {
    return const BookingFlowState();
  }

  void init(String proId) {
    _repo = ref.read(bookingRepositoryProvider);
    _proId = proId;
    _loadServices();
  }

  Future<void> _loadServices() async {
    state = state.copyWith(isLoading: true);
    final services = await _repo.getProServices(_proId);
    state = state.copyWith(services: services, isLoading: false);
  }

  void selectService(ServiceModel service) {
    state = state.copyWith(
      selectedService: service,
      personCount: service.minPersons ?? 1,
    );
  }

  // ─── Multi-service cart operations (priority #1) ─────────────────────

  /// Adds a service to the cart. If already present, no-op.
  void addToCart(ServiceModel service) {
    if (state.cart.items.any((it) => it.serviceId == service.id)) return;
    final item = BookingCartItem(
      serviceId: service.id,
      serviceName: service.name,
      servicePrice: service.price,
      serviceDurationMinutes: service.durationMinutes,
    );
    state = state.copyWith(cart: state.cart.addItem(item));
  }

  /// Removes a service from the cart by index.
  void removeFromCart(int index) {
    state = state.copyWith(cart: state.cart.removeAt(index));
  }

  /// Toggles an add-on on/off for a given cart item.
  void toggleCartAddon(int itemIndex, ServiceAddon addon) {
    if (itemIndex < 0 || itemIndex >= state.cart.items.length) return;
    final updated = state.cart.items[itemIndex].toggleAddon(addon);
    state = state.copyWith(cart: state.cart.updateAt(itemIndex, updated));
  }

  /// Clears the cart (used when user exits the flow).
  void clearCart() {
    state = state.copyWith(cart: const BookingCart());
  }

  void setPersonCount(int count) {
    state = state.copyWith(personCount: count);
  }

  Future<void> validatePromo(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    final promo = await _repo.validatePromoCode(code, _proId);
    if (promo == null) {
      state = state.copyWith(
          isLoading: false, error: 'Code promo invalide');
    } else {
      state = state.copyWith(
          promoCode: promo, promoApplied: true, isLoading: false);
    }
  }

  void nextStep() {
    state = state.copyWith(step: state.step + 1);
  }

  void previousStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  Future<void> loadDates() async {
    state = state.copyWith(isLoading: true);
    final dates = await _repo.getAvailableDates(_proId);
    state = state.copyWith(availableDates: dates, isLoading: false);
  }

  Future<void> selectDate(String date) async {
    state = state.copyWith(selectedDate: date, isLoading: true, error: null);

    _slotChannel?.unsubscribe();
    _slotChannel = _repo.subscribeSlotChanges(
      proId: _proId,
      date: date,
      onUpdate: _onSlotUpdate,
    );

    // Compute slots on-the-fly from the pro's availability_rules, respecting
    // lunch breaks + exceptions + existing bookings. This works even if
    // generate-slots hasn't run yet for the freshly-saved schedule.
    try {
      // Primary path: full computation with exceptions, lunch breaks, bookings
      final slots = await _repo.computeSlotsForDate(
        proId: _proId,
        date: DateTime.parse(date),
      );
      state = state.copyWith(timeSlots: slots, isLoading: false);
    } catch (e, st) {
      // ignore: avoid_print
      print('[booking] computeSlotsForDate failed, falling back: $e\n$st');
      try {
        // Fallback: simple rules-based slots (no exceptions, no lunch, no bookings)
        final slots = await _repo.computeSlotsSimple(
          proId: _proId,
          date: DateTime.parse(date),
        );
        state = state.copyWith(timeSlots: slots, isLoading: false);
      } catch (e2, st2) {
        // ignore: avoid_print
        print('[booking] computeSlotsSimple also failed: $e2\n$st2');
        state = state.copyWith(
          timeSlots: const [],
          isLoading: false,
          error: 'Erreur chargement créneaux',
        );
      }
    }
  }

  void _onSlotUpdate(Map<String, dynamic> payload) {
    final updated = TimeSlotModel.fromJson(payload);
    final newSlots = state.timeSlots.map((s) {
      return s.id == updated.id ? updated : s;
    }).toList();

    final selectedStillAvailable = state.selectedSlot != null &&
        state.selectedSlot!.id == updated.id &&
        !updated.isAvailable;

    state = state.copyWith(
      timeSlots: newSlots,
      selectedSlot: selectedStillAvailable ? null : state.selectedSlot,
      error: selectedStillAvailable
          ? 'Ce créneau vient d\'être réservé'
          : state.error,
    );
  }

  void selectSlot(TimeSlotModel slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  Future<void> createBooking() async {
    if (state.selectedSlot == null) return;
    // Resolve service id from cart first (V2 flow), then fall back to legacy.
    final String? serviceId = state.cart.items.isNotEmpty
        ? state.cart.items.first.serviceId
        : state.selectedService?.id;
    if (serviceId == null) return;
    state = state.copyWith(isCreating: true, error: null);
    try {
      final result = await _repo.createBooking(
        slotId: state.selectedSlot!.id,
        serviceId: serviceId,
        promoCodeId: state.promoCode?.id,
      );
      // create-booking-atomic renvoie déjà le clientSecret — on le récupère
      // directement sans rappeler stripe-create-intent (évite le 401 du 2e appel).
      final secret = result['clientSecret'] as String?;
      state = state.copyWith(
        bookingResult: result,
        clientSecret: secret,
        isCreating: false,
      );
    } catch (e) {
      state = state.copyWith(
          isCreating: false, error: e.toString());
    }
  }

  Future<bool> confirmPayment() async {
    if (state.clientSecret == null) return false;
    state = state.copyWith(isPaying: true, error: null);
    try {
      // Payment is confirmed via Stripe SDK in the UI layer
      // This method is called after successful confirmation
      state = state.copyWith(isPaying: false);
      return true;
    } catch (e) {
      state = state.copyWith(isPaying: false, error: e.toString());
      return false;
    }
  }

  void dispose() {
    _slotChannel?.unsubscribe();
  }
}

final bookingFlowProvider =
    NotifierProvider<BookingFlowNotifier, BookingFlowState>(
  BookingFlowNotifier.new,
  isAutoDispose: true,
);

// ─── Client bookings list ─────────────────────────────────

class ClientBookingsState {
  const ClientBookingsState({
    this.bookings = const [],
    this.isLoading = true,
    this.isCancelling = false,
    this.cancellationError,
  });
  final List<BookingModel> bookings;
  final bool isLoading;
  final bool isCancelling;
  final String? cancellationError;

  List<BookingModel> get upcoming => bookings.where((b) => b.isUpcoming).toList();
  List<BookingModel> get past => bookings.where((b) => b.isPast).toList();
  List<BookingModel> get cancelled => bookings.where((b) => b.isCancelled).toList();

  ClientBookingsState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
    bool? isCancelling,
    String? cancellationError,
  }) =>
      ClientBookingsState(
        bookings: bookings ?? this.bookings,
        isLoading: isLoading ?? this.isLoading,
        isCancelling: isCancelling ?? this.isCancelling,
        cancellationError: cancellationError,
      );
}

class ClientBookingsNotifier extends Notifier<ClientBookingsState> {
  StreamSubscription<RealtimeEvent>? _rtSub;

  @override
  ClientBookingsState build() {
    _listenRealtime();
    _load();
    ref.onDispose(() => _rtSub?.cancel());
    return const ClientBookingsState();
  }

  void _listenRealtime() {
    _rtSub = ref.read(realtimeManagerProvider).bookingStream.listen((event) {
      if (event is BookingStatusChanged) {
        // Refetch the full list to get JOINed data (pro name, service, etc.)
        _load();
      }
    });
  }

  Future<void> _load() async {
    final repo = ref.read(bookingRepositoryProvider);
    final bookings = await repo.getClientBookings();
    state = state.copyWith(bookings: bookings, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Future<bool> cancelBooking(String bookingId) async {
    state = state.copyWith(isCancelling: true, cancellationError: null);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.cancelBooking(bookingId);
      await _load();
      state = state.copyWith(isCancelling: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCancelling: false,
        cancellationError: e.toString(),
      );
      return false;
    }
  }

  Future<bool> submitReview({
    required String bookingId,
    required String proId,
    required int rating,
    required String comment,
  }) async {
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.submitReview(
        bookingId: bookingId,
        proId: proId,
        rating: rating,
        comment: comment,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final clientBookingsProvider =
    NotifierProvider<ClientBookingsNotifier, ClientBookingsState>(
  ClientBookingsNotifier.new,
  isAutoDispose: true,
);

// ─── Pro bookings list ──────────────────────────────────────

class ProBookingsNotifier extends Notifier<ClientBookingsState> {
  StreamSubscription<RealtimeEvent>? _rtSub;

  @override
  ClientBookingsState build() {
    _listenRealtime();
    _load();
    ref.onDispose(() => _rtSub?.cancel());
    return const ClientBookingsState();
  }

  void _listenRealtime() {
    _rtSub = ref.read(realtimeManagerProvider).bookingStream.listen((event) {
      if (event is BookingCreated || event is BookingStatusChanged) {
        // Refetch full list — new booking or status change
        _load();
      }
    });
  }

  Future<void> _load() async {
    final repo = ref.read(bookingRepositoryProvider);
    final bookings = await repo.getProBookings();
    state = state.copyWith(bookings: bookings, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }
}

final proBookingsProvider =
    NotifierProvider<ProBookingsNotifier, ClientBookingsState>(
  ProBookingsNotifier.new,
  isAutoDispose: true,
);

// ─── Pro dashboard ──────────────────────────────────────────

class ProDashboardState {
  const ProDashboardState({
    this.isLoading = true,
    this.error,
    this.stats = const {},
    this.upcomingBookings = const [],
    this.proName,
    this.proAvatarUrl,
    this.nextEvent,
    this.ticketsSold = 0,
    this.revenueChange,
  });
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> stats;
  final List<BookingModel> upcomingBookings;
  final String? proName;
  final String? proAvatarUrl;
  final Map<String, dynamic>? nextEvent;
  final int ticketsSold;
  final double? revenueChange;

  ProDashboardState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
    List<BookingModel>? upcomingBookings,
    String? proName,
    String? proAvatarUrl,
    Map<String, dynamic>? nextEvent,
    int? ticketsSold,
    double? revenueChange,
  }) =>
      ProDashboardState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        stats: stats ?? this.stats,
        upcomingBookings: upcomingBookings ?? this.upcomingBookings,
        proName: proName ?? this.proName,
        proAvatarUrl: proAvatarUrl ?? this.proAvatarUrl,
        nextEvent: nextEvent ?? this.nextEvent,
        ticketsSold: ticketsSold ?? this.ticketsSold,
        revenueChange: revenueChange ?? this.revenueChange,
      );
}

class ProDashboardNotifier extends Notifier<ProDashboardState> {
  StreamSubscription<RealtimeEvent>? _bookingSub;
  StreamSubscription<RealtimeEvent>? _ticketSub;

  @override
  ProDashboardState build() {
    _listenRealtime();
    _load();
    ref.onDispose(() {
      _bookingSub?.cancel();
      _ticketSub?.cancel();
    });
    return const ProDashboardState();
  }

  void _listenRealtime() {
    final rt = ref.read(realtimeManagerProvider);
    // New booking or status change → refresh dashboard stats
    _bookingSub = rt.bookingStream.listen((event) {
      if (event is BookingCreated || event is BookingStatusChanged) {
        _load();
      }
    });
    // Ticket sold → refresh
    _ticketSub = rt.ticketStream.listen((event) {
      if (event is TicketSold) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        state = state.copyWith(isLoading: false, error: 'Non connecté');
        return;
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        repo.getProDashboardStats(),
        repo.getUpcomingProBookings(limit: 3),
        _fetchProInfo(supabase, uid),
        _fetchNextEvent(supabase, uid),
        _fetchTicketsSold(supabase, uid),
        _fetchRevenueChange(supabase, uid),
      ]);

      final proInfo = results[2] as Map<String, dynamic>;
      final nextEvent = results[3] as Map<String, dynamic>?;

      state = state.copyWith(
        isLoading: false,
        stats: results[0] as Map<String, dynamic>,
        upcomingBookings: results[1] as List<BookingModel>,
        proName: proInfo['name'] as String?,
        proAvatarUrl: proInfo['avatar_url'] as String?,
        nextEvent: nextEvent,
        ticketsSold: results[4] as int,
        revenueChange: results[5] as double?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>> _fetchProInfo(
      SupabaseClient supabase, String uid) async {
    final data = await supabase
        .from('profiles_pro')
        .select('business_name, users(full_name, avatar_url)')
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return {};
    final user = data['users'] as Map<String, dynamic>?;
    return {
      'name': user?['full_name'] ?? data['business_name'] ?? 'Pro',
      'avatar_url': user?['avatar_url'],
    };
  }

  Future<Map<String, dynamic>?> _fetchNextEvent(
      SupabaseClient supabase, String uid) async {
    final data = await supabase
        .from('events')
        .select('id, title, event_date, location, cover_url')
        .eq('pro_id', uid)
        .eq('is_active', true)
        .gte('event_date', DateTime.now().toIso8601String())
        .order('event_date')
        .limit(1)
        .maybeSingle();
    return data;
  }

  Future<int> _fetchTicketsSold(
      SupabaseClient supabase, String uid) async {
    final data = await supabase
        .from('tickets')
        .select('id')
        .eq('status', 'valid')
        .inFilter('event_id',
          (await supabase
            .from('events')
            .select('id')
            .eq('pro_id', uid))
            .map((e) => e['id'] as String)
            .toList(),
        );
    return (data as List).length;
  }

  Future<double?> _fetchRevenueChange(
      SupabaseClient supabase, String uid) async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final bookings = await supabase
        .from('bookings')
        .select('deposit_amount, created_at')
        .eq('pro_id', uid)
        .inFilter('status', ['confirmed', 'completed'])
        .gte('created_at', lastMonthStart.toIso8601String());

    double thisMonth = 0;
    double lastMonth = 0;
    for (final b in bookings as List) {
      final created = DateTime.parse(b['created_at'] as String);
      final amount = (b['deposit_amount'] as num?)?.toDouble() ?? 0;
      if (created.isAfter(thisMonthStart) || created.isAtSameMomentAs(thisMonthStart)) {
        thisMonth += amount;
      } else {
        lastMonth += amount;
      }
    }
    if (lastMonth == 0) return null;
    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }
}

final proDashboardProvider =
    NotifierProvider<ProDashboardNotifier, ProDashboardState>(
  ProDashboardNotifier.new,
  isAutoDispose: true,
);

// ─── Revenue daily data point ────────────────────────────────

class RevenueDayPoint {
  const RevenueDayPoint({required this.day, required this.amount});
  final DateTime day;
  final double amount;
}

// ─── Pro revenue daily provider ──────────────────────────────

final proRevenueDailyProvider =
    FutureProvider.autoDispose.family<List<RevenueDayPoint>, int>((ref, periodDays) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final bookings = await repo.getProBookings();
  final now = DateTime.now();
  final cutoff = now.subtract(Duration(days: periodDays));
  final confirmed = bookings.where((b) =>
    (b.status == 'confirmed' || b.status == 'completed') &&
    b.createdAt.isAfter(cutoff),
  ).toList();

  final map = <String, double>{};
  for (var i = 0; i < periodDays; i++) {
    final d = now.subtract(Duration(days: periodDays - 1 - i));
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    map[key] = 0;
  }
  for (final b in confirmed) {
    final key = '${b.createdAt.year}-${b.createdAt.month.toString().padLeft(2, '0')}-${b.createdAt.day.toString().padLeft(2, '0')}';
    map[key] = (map[key] ?? 0) + b.depositAmount;
  }
  return map.entries.map((e) => RevenueDayPoint(
    day: DateTime.parse(e.key),
    amount: e.value,
  )).toList();
});

// ─── Pro transactions provider ───────────────────────────────

final proTransactionsProvider =
    FutureProvider.autoDispose.family<List<BookingModel>, int>((ref, periodDays) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final bookings = await repo.getProBookings();
  final cutoff = DateTime.now().subtract(Duration(days: periodDays));
  return bookings.where((b) =>
    (b.status == 'confirmed' || b.status == 'completed') &&
    b.createdAt.isAfter(cutoff),
  ).toList();
});

// ─── Booking detail provider ─────────────────────────────────

final bookingDetailProvider =
    FutureProvider.autoDispose.family<BookingModel?, String>((ref, bookingId) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingById(bookingId);
});
