import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_config_provider.dart';
import '../domain/event_models.dart';
import 'event_repository.dart';

/// Génère un nonce d'idempotence cryptographiquement aléatoire (≈ UUIDv4
/// sans dépendance `uuid`). Utilisé pour que Stripe renvoie le même
/// PaymentIntent si le Flutter rejoue l'appel (retry réseau, double-tap).
String _generatePurchaseNonce() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

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
    // eventsProvider = liste publique (découverte client). Les écrans Pro
    // consomment proEventsProvider / proEventsByProIdProvider pour ne voir
    // QUE leurs propres événements.
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
  final repo = ref.read(eventRepositoryProvider);
  final userId = repo.currentUserId;
  if (userId == null) return [];
  return repo.getEventsByProId(userId);
});

// ─── Single event detail ────────────────────────────────────

final eventDetailProvider =
    FutureProvider.family<EventModel, String>((ref, eventId) async {
  final event = await ref.read(eventRepositoryProvider).getEvent(eventId);
  if (event == null) throw StateError('Event $eventId not found');
  return event;
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
    this.paymentIntentId,
    this.error,
    this.commissionRate = 0.12,
    this.serviceFeePerTicket = 2.50,
    this.purchaseNonce,
  });
  final TicketTypeModel? selectedType;
  final int quantity;
  final bool isLoading;
  final String? clientSecret;
  final String? paymentIntentId;
  final String? error;
  final double commissionRate;

  /// Frais de service facturés au client, par billet (fallback CLAUDE.md 2.50$).
  /// L'edge function `stripe-create-ticket-intent` a la main : c'est
  /// `events.service_fee * quantity * 100` qui est facturé au client — cette
  /// valeur ici sert uniquement à afficher un aperçu avant le tap.
  final double serviceFeePerTicket;

  /// Jeton d'idempotence par tentative d'achat. Régénéré à chaque
  /// [BuyTicketNotifier.createIntent] et verrouillé ensuite : un retry rapide
  /// réutilise le même nonce et Stripe renvoie le PI existant.
  final String? purchaseNonce;

  double get unitPrice => selectedType?.price ?? 0;
  double get subtotal => unitPrice * quantity;
  double get commission => subtotal * commissionRate;
  double get serviceFee => serviceFeePerTicket * quantity;

  /// Montant facturé à la carte du client = prix billets + frais de service.
  /// La commission Spotbook n'est PAS ajoutée au total client : elle est
  /// prélevée côté Stripe via `application_fee_amount` sur le transfert pro.
  double get grandTotal => subtotal + serviceFee;

  int get totalCents => (grandTotal * 100).round();
  int get commissionPct => (commissionRate * 100).round();

  BuyTicketState copyWith({
    TicketTypeModel? selectedType,
    int? quantity,
    bool? isLoading,
    String? clientSecret,
    String? paymentIntentId,
    String? error,
    double? commissionRate,
    double? serviceFeePerTicket,
    String? purchaseNonce,
  }) =>
      BuyTicketState(
        selectedType: selectedType ?? this.selectedType,
        quantity: quantity ?? this.quantity,
        isLoading: isLoading ?? this.isLoading,
        clientSecret: clientSecret ?? this.clientSecret,
        paymentIntentId: paymentIntentId ?? this.paymentIntentId,
        error: error,
        commissionRate: commissionRate ?? this.commissionRate,
        serviceFeePerTicket: serviceFeePerTicket ?? this.serviceFeePerTicket,
        purchaseNonce: purchaseNonce ?? this.purchaseNonce,
      );
}

class BuyTicketNotifier extends Notifier<BuyTicketState> {
  @override
  BuyTicketState build() {
    final config = ref.watch(appConfigProvider).value;
    return BuyTicketState(
      commissionRate: config?.commissionEvents ?? 0.12,
      serviceFeePerTicket: config?.serviceFeeClient ?? 2.50,
    );
  }

  void selectType(TicketTypeModel type) {
    state = state.copyWith(selectedType: type, quantity: 1);
  }

  void setQuantity(int q) {
    if (q >= 1 && q <= 4) {
      // Changer la quantité → le PaymentIntent existant n'est plus valide
      // (son amount est figé). On efface le clientSecret et le nonce pour
      // forcer la création d'un NOUVEAU PI avec le bon montant.
      state = BuyTicketState(
        selectedType: state.selectedType,
        quantity: q,
        commissionRate: state.commissionRate,
        serviceFeePerTicket: state.serviceFeePerTicket,
      );
    }
  }

  Future<void> createIntent() async {
    if (state.selectedType == null) return;
    // Toujours régénérer un nonce si on n'en a pas — ça garantit un PI
    // frais quand la quantité change (setQuantity efface le nonce).
    final nonce = state.purchaseNonce ?? _generatePurchaseNonce();
    state = state.copyWith(
      isLoading: true,
      error: null,
      purchaseNonce: nonce,
    );
    try {
      final repo = ref.read(eventRepositoryProvider);
      final secret = await repo.createTicketPaymentIntent(
        ticketTypeId: state.selectedType!.id,
        quantity: state.quantity,
        purchaseNonce: nonce,
      );
      // Le PI id est dérivé du clientSecret (`pi_XXX_secret_YYY`) — évite
      // un deuxième aller-retour juste pour lier les tickets au paiement.
      final piId = secret.split('_secret_').first;
      state = state.copyWith(
        clientSecret: secret,
        paymentIntentId: piId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final buyTicketProvider = NotifierProvider<BuyTicketNotifier, BuyTicketState>(
  BuyTicketNotifier.new,
  isAutoDispose: true,
);
