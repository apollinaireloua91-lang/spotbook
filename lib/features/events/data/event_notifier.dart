import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/event_models.dart';
import 'event_repository.dart';

// ─── Events list ────────────────────────────────────────────

class EventsState {
  const EventsState({this.events = const [], this.isLoading = true});
  final List<EventModel> events;
  final bool isLoading;

  EventsState copyWith({List<EventModel>? events, bool? isLoading}) =>
      EventsState(
        events: events ?? this.events,
        isLoading: isLoading ?? this.isLoading,
      );
}

class EventsNotifier extends Notifier<EventsState> {
  @override
  EventsState build() {
    _load();
    return const EventsState();
  }

  Future<void> _load() async {
    final repo = ref.read(eventRepositoryProvider);
    final events = await repo.getEvents();
    state = state.copyWith(events: events, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, EventsState>(
  EventsNotifier.new,
  isAutoDispose: true,
);

// ─── Pro events (async) ──────────────────────────────────────

final proEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  return ref.read(eventRepositoryProvider).getEvents();
});

// ─── Single event detail ────────────────────────────────────

final eventDetailProvider =
    FutureProvider.family<EventModel, String>((ref, eventId) async {
  return ref.read(eventRepositoryProvider).getEvent(eventId);
});

// ─── User tickets ───────────────────────────────────────────

class UserTicketsState {
  const UserTicketsState({this.tickets = const [], this.isLoading = true});
  final List<TicketModel> tickets;
  final bool isLoading;

  UserTicketsState copyWith({List<TicketModel>? tickets, bool? isLoading}) =>
      UserTicketsState(
        tickets: tickets ?? this.tickets,
        isLoading: isLoading ?? this.isLoading,
      );
}

class UserTicketsNotifier extends Notifier<UserTicketsState> {
  @override
  UserTicketsState build() {
    _load();
    return const UserTicketsState();
  }

  Future<void> _load() async {
    final repo = ref.read(eventRepositoryProvider);
    final tickets = await repo.getUserTickets();
    state = state.copyWith(tickets: tickets, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }
}

final userTicketsProvider =
    NotifierProvider<UserTicketsNotifier, UserTicketsState>(
  UserTicketsNotifier.new,
  isAutoDispose: true,
);

// ─── Buy ticket flow ────────────────────────────────────────

class BuyTicketState {
  const BuyTicketState({
    this.selectedType,
    this.quantity = 1,
    this.isLoading = false,
    this.clientSecret,
    this.error,
  });
  final TicketTypeModel? selectedType;
  final int quantity;
  final bool isLoading;
  final String? clientSecret;
  final String? error;

  double get total =>
      (selectedType?.price ?? 0) * quantity;
  double get commission => total * 0.07;
  double get grandTotal => total + commission;
  int get totalCents => (grandTotal * 100).round();

  BuyTicketState copyWith({
    TicketTypeModel? selectedType,
    int? quantity,
    bool? isLoading,
    String? clientSecret,
    String? error,
  }) =>
      BuyTicketState(
        selectedType: selectedType ?? this.selectedType,
        quantity: quantity ?? this.quantity,
        isLoading: isLoading ?? this.isLoading,
        clientSecret: clientSecret ?? this.clientSecret,
        error: error,
      );
}

class BuyTicketNotifier extends Notifier<BuyTicketState> {
  @override
  BuyTicketState build() => const BuyTicketState();

  void selectType(TicketTypeModel type) {
    state = state.copyWith(selectedType: type, quantity: 1);
  }

  void setQuantity(int q) {
    if (q >= 1 && q <= 4) {
      state = state.copyWith(quantity: q);
    }
  }

  Future<void> createIntent() async {
    if (state.selectedType == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final secret = await repo.createTicketPaymentIntent(
        ticketTypeId: state.selectedType!.id,
        quantity: state.quantity,
      );
      state = state.copyWith(clientSecret: secret, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final buyTicketProvider = NotifierProvider<BuyTicketNotifier, BuyTicketState>(
  BuyTicketNotifier.new,
  isAutoDispose: true,
);
