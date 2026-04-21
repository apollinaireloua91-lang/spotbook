import 'dart:typed_data';

import 'package:flutter/material.dart';
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
      '*, users!pro_id(full_name, avatar_url, profiles_pro(business_name)), ticket_types(*)';

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

  Future<EventModel?> getEvent(String eventId) async {
    final data = await _supabase
        .from('events')
        .select(_eventSelect)
        .eq('id', eventId)
        .maybeSingle();
    if (data == null) return null;
    return EventModel.fromJson(data);
  }

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required TimeOfDay startTime,
    required String location,
    String? address,
    int totalCapacity = 0,
  }) async {
    await _supabase.auth.refreshSession();
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    // Format time as HH:mm:ss for PostgreSQL time column
    final timeStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';

    final data = await _supabase
        .from('events')
        .insert({
          'pro_id': uid,
          'title': title,
          'description': description,
          'event_date': eventDate.toIso8601String().split('T').first,
          'start_time': timeStr,
          'location': location,
          'address': address,
          'is_active': true,
          'status': 'published',
          'total_capacity': totalCapacity,
        })
        .select(_eventSelect)
        .single();

    return EventModel.fromJson(data);
  }

  Future<String> uploadCover(String eventId, Uint8List bytes) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Non connecté');

    // RLS policy requires first folder = auth.uid()
    final path = '$uid/$eventId.jpg';
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

  /// Update total_capacity on the event after all ticket types are added.
  Future<void> updateTotalCapacity(String eventId, int totalCapacity) async {
    await _supabase
        .from('events')
        .update({'total_capacity': totalCapacity})
        .eq('id', eventId);
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

  /// Buy ticket: create PaymentIntent → confirm → sign QR.
  ///
  /// [purchaseNonce] — jeton d'idempotence généré côté client (UUID simplifié).
  /// L'Edge Function l'utilise comme clé Stripe pour que les retries réseau
  /// renvoient le MÊME PaymentIntent au lieu d'en créer un second.
  Future<String> createTicketPaymentIntent({
    required String ticketTypeId,
    required int quantity,
    required String purchaseNonce,
  }) async {
    // Même pattern que `stripe-create-intent` (booking) : on rafraîchit la
    // session avant l'invoke pour que l'Authorization header envoyé par
    // supabase_flutter ne soit pas un JWT expiré — l'Edge Function rejette
    // en 401 sinon (verify_jwt=false mais checks manuellement le header).
    await _supabase.auth.refreshSession();
    final res = await _supabase.functions.invoke(
      'stripe-create-ticket-intent',
      body: {
        'ticketTypeId': ticketTypeId,
        'quantity': quantity,
        'purchaseNonce': purchaseNonce,
      },
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Payment failed';
      throw Exception(err ?? 'Payment failed');
    }
    final data = res.data as Map<String, dynamic>;
    final clientSecret = data['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('No client secret returned');
    }
    return clientSecret;
  }

  /// Matérialise les tickets après un PaymentIntent payé.
  ///
  /// **Ne fait plus d'INSERT client-side** (vecteur de fraude 🔴 fermé par
  /// la migration 20260421120000 qui restreint la policy tickets INSERT
  /// au service_role). Délègue à l'Edge Function `purchase-tickets-atomic`
  /// qui :
  ///   1. vérifie que le PaymentIntent est `succeeded` côté Stripe,
  ///   2. re-vérifie les metadata (userId, ticketTypeId, quantity, eventId),
  ///   3. INSERT atomique des N tickets + signe leur QR en HMAC serveur,
  ///   4. se déduplique avec le webhook Stripe s'il a été plus rapide.
  ///
  /// Après la réponse de l'Edge Function, on fetch les tickets complets
  /// (avec join `events` + `ticket_types`) depuis la DB pour garder le
  /// même contrat de retour côté caller (`buy_ticket_sheet` n'est pas
  /// impacté). Lecture autorisée par la policy `tickets_own_select`.
  Future<List<TicketModel>> createTickets({
    required String ticketTypeId,
    required String eventId,
    required int quantity,
    required String stripePaymentIntentId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final resp = await _supabase.functions.invoke(
      'purchase-tickets-atomic',
      body: {
        'paymentIntentId': stripePaymentIntentId,
        'ticketTypeId': ticketTypeId,
        'eventId': eventId,
        'quantity': quantity,
      },
    );

    final data = resp.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      final errCode = data?['error'] as String? ?? 'purchase_failed';
      throw Exception('Ticket purchase failed: $errCode');
    }

    final tickets = (data['tickets'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final ids = tickets.map((t) => t['id'] as String).toList();
    if (ids.isEmpty) return const [];

    final rows = await _supabase
        .from('tickets')
        .select(
            '*, events(title, event_date, location, cover_url), ticket_types(name)')
        .inFilter('id', ids)
        .order('purchased_at', ascending: false);

    return (rows as List)
        .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
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

  /// Rejoint la waitlist d'un ticket type de façon atomique.
  ///
  /// Délègue à l'Edge Function `join-waitlist-atomic` qui utilise un
  /// `pg_advisory_xact_lock(hashtext(ticket_type_id))` côté Postgres pour
  /// sérialiser les inscriptions concurrentes — le pattern client-side
  /// count+upsert précédent créait une race où deux users simultanés
  /// obtenaient la même `position`.
  ///
  /// Retourne la position finale (1-indexed). Si l'utilisateur était déjà
  /// inscrit, on renvoie la position existante (pas d'erreur).
  Future<int> joinWaitlist(String ticketTypeId) async {
    await _supabase.auth.refreshSession();
    final resp = await _supabase.functions.invoke(
      'join-waitlist-atomic',
      body: {'ticketTypeId': ticketTypeId},
    );

    final data = resp.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      final err = data?['error'] as String? ?? 'waitlist_failed';
      throw Exception('Join waitlist failed: $err');
    }
    return (data['position'] as num?)?.toInt() ?? 0;
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
