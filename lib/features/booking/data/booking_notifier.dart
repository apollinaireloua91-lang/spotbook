import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/booking_models.dart';
import 'booking_repository.dart';

// ─── Booking flow state ─────────────────────────────────────

class BookingFlowState {
  const BookingFlowState({
    this.step = 0,
    this.services = const [],
    this.selectedService,
    this.promoCode,
    this.promoApplied = false,
    this.availableDates = const [],
    this.selectedDate,
    this.timeSlots = const [],
    this.selectedSlot,
    this.isLoading = false,
    this.isCreating = false,
    this.bookingResult,
    this.error,
  });

  final int step;
  final List<ServiceModel> services;
  final ServiceModel? selectedService;
  final PromoCodeModel? promoCode;
  final bool promoApplied;
  final List<String> availableDates;
  final String? selectedDate;
  final List<TimeSlotModel> timeSlots;
  final TimeSlotModel? selectedSlot;
  final bool isLoading;
  final bool isCreating;
  final Map<String, dynamic>? bookingResult;
  final String? error;

  double get totalPrice {
    if (selectedService == null) return 0;
    double price = selectedService!.price;
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
    PromoCodeModel? promoCode,
    bool? promoApplied,
    List<String>? availableDates,
    String? selectedDate,
    List<TimeSlotModel>? timeSlots,
    TimeSlotModel? selectedSlot,
    bool? isLoading,
    bool? isCreating,
    Map<String, dynamic>? bookingResult,
    String? error,
  }) =>
      BookingFlowState(
        step: step ?? this.step,
        services: services ?? this.services,
        selectedService: selectedService ?? this.selectedService,
        promoCode: promoCode ?? this.promoCode,
        promoApplied: promoApplied ?? this.promoApplied,
        availableDates: availableDates ?? this.availableDates,
        selectedDate: selectedDate ?? this.selectedDate,
        timeSlots: timeSlots ?? this.timeSlots,
        selectedSlot: selectedSlot ?? this.selectedSlot,
        isLoading: isLoading ?? this.isLoading,
        isCreating: isCreating ?? this.isCreating,
        bookingResult: bookingResult ?? this.bookingResult,
        error: error,
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
    state = state.copyWith(selectedService: service);
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
    state = state.copyWith(selectedDate: date, isLoading: true);

    _slotChannel?.unsubscribe();
    _slotChannel = _repo.subscribeSlotChanges(
      proId: _proId,
      date: date,
      onUpdate: _onSlotUpdate,
    );

    final slots = await _repo.getTimeSlots(_proId, date);
    state = state.copyWith(timeSlots: slots, isLoading: false);
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
    if (state.selectedSlot == null || state.selectedService == null) return;
    state = state.copyWith(isCreating: true, error: null);
    try {
      final result = await _repo.createBooking(
        slotId: state.selectedSlot!.id,
        serviceId: state.selectedService!.id,
        promoCodeId: state.promoCode?.id,
      );
      state = state.copyWith(bookingResult: result, isCreating: false);
    } catch (e) {
      state = state.copyWith(
          isCreating: false, error: e.toString());
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
  });
  final List<BookingModel> bookings;
  final bool isLoading;

  List<BookingModel> get upcoming => bookings.where((b) => b.isUpcoming).toList();
  List<BookingModel> get past => bookings.where((b) => b.isPast).toList();
  List<BookingModel> get cancelled => bookings.where((b) => b.isCancelled).toList();

  ClientBookingsState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
  }) =>
      ClientBookingsState(
        bookings: bookings ?? this.bookings,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ClientBookingsNotifier extends Notifier<ClientBookingsState> {
  @override
  ClientBookingsState build() {
    _load();
    return const ClientBookingsState();
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
}

final clientBookingsProvider =
    NotifierProvider<ClientBookingsNotifier, ClientBookingsState>(
  ClientBookingsNotifier.new,
  isAutoDispose: true,
);

// ─── Pro bookings list ──────────────────────────────────────

class ProBookingsNotifier extends Notifier<ClientBookingsState> {
  @override
  ClientBookingsState build() {
    _load();
    return const ClientBookingsState();
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
    this.stats = const {},
    this.upcomingBookings = const [],
  });
  final bool isLoading;
  final Map<String, dynamic> stats;
  final List<BookingModel> upcomingBookings;

  ProDashboardState copyWith({
    bool? isLoading,
    Map<String, dynamic>? stats,
    List<BookingModel>? upcomingBookings,
  }) =>
      ProDashboardState(
        isLoading: isLoading ?? this.isLoading,
        stats: stats ?? this.stats,
        upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      );
}

class ProDashboardNotifier extends Notifier<ProDashboardState> {
  @override
  ProDashboardState build() {
    _load();
    return const ProDashboardState();
  }

  Future<void> _load() async {
    final repo = ref.read(bookingRepositoryProvider);
    final results = await Future.wait([
      repo.getProDashboardStats(),
      repo.getUpcomingProBookings(),
    ]);
    state = state.copyWith(
      isLoading: false,
      stats: results[0] as Map<String, dynamic>,
      upcomingBookings: results[1] as List<BookingModel>,
    );
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
