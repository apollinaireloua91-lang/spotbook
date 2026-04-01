import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/event_models.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(supabase: Supabase.instance.client);
});

class EventRepository {
  EventRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  static const _eventSelect =
      '*, profiles_pro(business_name, users(full_name, avatar_url)), ticket_types(*)';

  Future<List<EventModel>> getEvents() async {
    final data = await _supabase
        .from('events')
        .select(_eventSelect)
        .eq('is_active', true)
        .order('event_date', ascending: true);

    return (data as List)
        .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<EventModel>> getEventsByProId(String proId) async {
    final data = await _supabase
        .from('events')
        .select(_eventSelect)
        .eq('pro_id', proId)
        .order('event_date', ascending: true);

    return (data as List)
        .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel> getEvent(String eventId) async {
    final data = await _supabase
        .from('events')
        .select(_eventSelect)
        .eq('id', eventId)
        .single();

    return EventModel.fromJson(data);
  }

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String location,
    String? address,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final data = await _supabase
        .from('events')
        .insert({
          'pro_id': uid,
          'title': title,
          'description': description,
          'event_date': eventDate.toIso8601String(),
          'location': location,
          'address': address,
        })
        .select(_eventSelect)
        .single();

    return EventModel.fromJson(data);
  }

  Future<String> uploadCover(String eventId, Uint8List bytes) async {
    final path = '$eventId/cover.jpg';
    await _supabase.storage
        .from('event-covers')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    final url = _supabase.storage.from('event-covers').getPublicUrl(path);

    await _supabase
        .from('events')
        .update({'cover_url': url})
        .eq('id', eventId);

    return url;
  }

  Future<void> addTicketType({
    required String eventId,
    required String name,
    required double price,
    required int quantity,
  }) async {
    await _supabase.from('ticket_types').insert({
      'event_id': eventId,
      'name': name,
      'price': price,
      'quantity': quantity,
    });
  }

  Future<List<TicketTypeModel>> getTicketTypes(String eventId) async {
    final data = await _supabase
        .from('ticket_types')
        .select()
        .eq('event_id', eventId)
        .order('price');

    return (data as List)
        .map((json) => TicketTypeModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Buy ticket: create PaymentIntent → confirm → sign QR
  Future<String> createTicketPaymentIntent({
    required String ticketTypeId,
    required int quantity,
  }) async {
    final res = await _supabase.functions.invoke(
      'stripe-create-ticket-intent',
      body: {'ticketTypeId': ticketTypeId, 'quantity': quantity},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Payment failed';
      throw Exception(err ?? 'Payment failed');
    }
    return (res.data as Map<String, dynamic>)['clientSecret'] as String;
  }

  /// After payment success, create ticket records + sign QR
  Future<List<TicketModel>> createTickets({
    required String ticketTypeId,
    required String eventId,
    required int quantity,
    required String stripePaymentIntentId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final tickets = <TicketModel>[];
    for (int i = 0; i < quantity; i++) {
      final data = await _supabase
          .from('tickets')
          .insert({
            'event_id': eventId,
            'ticket_type_id': ticketTypeId,
            'user_id': uid,
            'stripe_payment_intent_id': stripePaymentIntentId,
          })
          .select('*, events(title, event_date, location, cover_url), ticket_types(name)')
          .single();

      final ticket = TicketModel.fromJson(data);

      // Sign QR server-side
      await _supabase.functions.invoke(
        'sign-qr-ticket',
        body: {'ticketId': ticket.id},
      );

      tickets.add(ticket);
    }

    // Increment sold count
    await _supabase.rpc('increment_sold_count', params: {
      'p_ticket_type_id': ticketTypeId,
      'p_quantity': quantity,
    });

    return tickets;
  }

  Future<List<TicketModel>> getUserTickets() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final data = await _supabase
        .from('tickets')
        .select(
            '*, events(title, event_date, location, cover_url), ticket_types(name)')
        .eq('user_id', uid)
        .order('purchased_at', ascending: false);

    return (data as List)
        .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> validateTicket({
    required String ticketId,
    required String qrHash,
  }) async {
    final res = await _supabase.functions.invoke(
      'validate-qr-ticket',
      body: {'ticketId': ticketId, 'qrHash': qrHash},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> joinWaitlist(String ticketTypeId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    // Get current position
    final count = await _supabase
        .from('waitlist')
        .select()
        .eq('ticket_type_id', ticketTypeId)
        .count(CountOption.exact);

    await _supabase.from('waitlist').insert({
      'ticket_type_id': ticketTypeId,
      'user_id': uid,
      'position': (count.count) + 1,
    });
  }

  Future<int> getScannedCount(String eventId) async {
    final result = await _supabase
        .from('tickets')
        .select()
        .eq('event_id', eventId)
        .eq('status', 'used')
        .count(CountOption.exact);
    return result.count;
  }

  Future<int> getTotalTicketsSold(String eventId) async {
    final result = await _supabase
        .from('tickets')
        .select()
        .eq('event_id', eventId)
        .count(CountOption.exact);
    return result.count;
  }
}
