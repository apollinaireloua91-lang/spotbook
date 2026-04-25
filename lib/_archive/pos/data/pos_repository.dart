import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/pos_models.dart';

/// Thin wrapper around the three POS Edge Functions + direct PostgREST
/// reads on `pos_transactions`. The Stripe Terminal SDK interactions live
/// in [PosTerminalDataSource]; this repository only speaks HTTP/SQL.
final posRepositoryProvider = Provider<PosRepository>((ref) {
  return PosRepository(supabase: Supabase.instance.client);
});

class PosRepository {
  PosRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ── Edge Functions ─────────────────────────────────────────────────────

  /// Calls `create-pos-payment-intent` which validates the payload, creates
  /// the Stripe PaymentIntent + a matching `pos_transactions` row (status
  /// `pending`), and returns the Terminal SDK client_secret.
  ///
  /// When [bookingId] is provided, [kind] MUST be `'booking_balance'` — the
  /// edge function rewrites `amount_subtotal_cents` to the booking's
  /// `remaining_amount` so the client side can pass a placeholder safely.
  /// For walk-in sales leave both nulls (defaults to `'standalone'`).
  Future<PosPaymentIntentRef> createPaymentIntent({
    required int amountSubtotalCents,
    required int tipCents,
    required int tpsCents,
    required int tvqCents,
    required String clientRequestId,
    String? customerEmail,
    String? customerPhone,
    String currency = 'cad',
    String? bookingId,
    String kind = 'standalone',
  }) async {
    final res = await _supabase.functions.invoke(
      'create-pos-payment-intent',
      body: {
        'amount_subtotal_cents': amountSubtotalCents,
        'tip_cents': tipCents,
        'tps_cents': tpsCents,
        'tvq_cents': tvqCents,
        'currency': currency,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'client_request_id': clientRequestId,
        if (bookingId != null) 'booking_id': bookingId,
        'kind': kind,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw StateError('create-pos-payment-intent: unexpected response');
    }
    final error = data['error'];
    if (error is String) {
      throw PosRepositoryException(error);
    }
    return PosPaymentIntentRef(
      clientSecret: data['client_secret'] as String,
      transactionId: data['transaction_id'] as String,
      paymentIntentId: data['payment_intent_id'] as String,
    );
  }

  /// Calls `send-pos-receipt` to email (or later SMS) a digital receipt for
  /// a succeeded transaction. The transaction MUST belong to the caller.
  Future<bool> sendReceipt({
    required String transactionId,
    String? email,
    String? phone,
  }) async {
    final res = await _supabase.functions.invoke(
      'send-pos-receipt',
      body: {
        'transaction_id': transactionId,
        'email': email,
        'phone': phone,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw StateError('send-pos-receipt: unexpected response');
    }
    final error = data['error'];
    if (error is String) {
      throw PosRepositoryException(error);
    }
    return (data['email_sent'] as bool?) ?? false;
  }

  /// Calls `refund-pos-transaction` for a full or partial refund.
  Future<PosRefundResult> refund({
    required String transactionId,
    int? amountCents,
    String reason = 'requested_by_customer',
  }) async {
    final res = await _supabase.functions.invoke(
      'refund-pos-transaction',
      body: {
        'transaction_id': transactionId,
        'amount_cents': amountCents,
        'reason': reason,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw StateError('refund-pos-transaction: unexpected response');
    }
    final error = data['error'];
    if (error is String) {
      throw PosRepositoryException(error);
    }
    return PosRefundResult.fromJson(Map<String, dynamic>.from(data));
  }

  // ── Direct reads (RLS policies enforce pro_id = auth.uid()) ─────────────

  /// Paginated list of the current Pro's POS transactions, newest first.
  /// RLS filters to `pro_id = auth.uid()` automatically.
  Future<List<PosTransaction>> listTransactions({
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await _supabase
        .from('pos_transactions')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((r) => PosTransaction.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<PosTransaction?> getTransaction(String id) async {
    final row = await _supabase
        .from('pos_transactions')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return PosTransaction.fromJson(Map<String, dynamic>.from(row));
  }

  /// Aggregated "today's POS revenue" displayed on the Pro dashboard.
  /// Returns (count, totalCents). Only counts `succeeded` and
  /// `partially_refunded` rows, and subtracts refunded portions.
  Future<({int count, int netCents})> todayTotals() async {
    final uid = currentUserId;
    if (uid == null) return (count: 0, netCents: 0);

    final startOfDay = DateTime.now().toLocal();
    final dayStart = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);

    final rows = await _supabase
        .from('pos_transactions')
        .select('amount_total_cents, refunded_amount_cents, status')
        .eq('pro_id', uid)
        .gte('created_at', dayStart.toIso8601String())
        .inFilter('status', ['succeeded', 'partially_refunded']);

    var count = 0;
    var net = 0;
    for (final r in rows as List) {
      final m = r as Map;
      count += 1;
      final total = (m['amount_total_cents'] as num).toInt();
      final refunded = (m['refunded_amount_cents'] as num?)?.toInt() ?? 0;
      net += (total - refunded);
    }
    return (count: count, netCents: net);
  }
}

/// Transport-level / domain error raised when an Edge Function returns a
/// well-formed { error: '<code>' } payload. UI maps the code to French copy.
class PosRepositoryException implements Exception {
  PosRepositoryException(this.code);
  final String code;
  @override
  String toString() => 'PosRepositoryException($code)';
}
