/// POS (Tap to Pay) domain models.
///
/// All monetary values are stored in minor units (cents) to match the
/// server-side `pos_transactions` schema and Stripe's wire format. UI
/// formatting to "12,34 $" is done at the presentation layer.
library;

/// Quebec sales-tax rates. Not hard-coded as percentages on the UI — the
/// Pro can disable tax application entirely via `profiles_pro.pos_apply_taxes`.
const double kTpsRate = 0.05; // 5 %
const double kTvqRate = 0.09975; // 9,975 %

/// Terminal state machine for a single Tap to Pay collection.
///
/// Mirrors the Stripe Terminal SDK lifecycle so the UI can render the right
/// copy at each stage ("Initialisation", "Approchez la carte", "Lecture",
/// "Traitement", "Succès", "Erreur").
enum PosReaderState {
  idle,
  initializing,
  discoveringReaders,
  connectingReader,
  readerReady,
  collectingPaymentMethod,
  processingPayment,
  succeeded,
  failed,
  canceled,
}

/// Terminal status code for user-facing error mapping.
enum PosErrorCode {
  permissionsDenied,
  nfcDisabled,
  bluetoothDisabled,
  cardDeclined,
  timeout,
  network,
  stripeConnectNotReady,
  unknown,
}

/// User-editable input: subtotal + optional tip, in cents.
///
/// Computes TPS/TVQ on the fly given the pro's tax-application toggle, and
/// exposes the final total. Kept as an immutable value so Riverpod's
/// `select()` can efficiently track field-level changes.
class PosAmount {
  const PosAmount({
    this.subtotalCents = 0,
    this.tipCents = 0,
    this.applyTaxes = true,
  });

  final int subtotalCents;
  final int tipCents;
  final bool applyTaxes;

  /// Taxable base = subtotal only (tip is never taxed in Canada).
  int get tpsCents => applyTaxes ? (subtotalCents * kTpsRate).round() : 0;
  int get tvqCents => applyTaxes ? (subtotalCents * kTvqRate).round() : 0;

  int get totalCents => subtotalCents + tipCents + tpsCents + tvqCents;

  /// Stripe CAD minimum is 50 ¢. Below this, the UI disables "Encaisser".
  bool get isAboveStripeMinimum => totalCents >= 50;

  PosAmount copyWith({
    int? subtotalCents,
    int? tipCents,
    bool? applyTaxes,
  }) =>
      PosAmount(
        subtotalCents: subtotalCents ?? this.subtotalCents,
        tipCents: tipCents ?? this.tipCents,
        applyTaxes: applyTaxes ?? this.applyTaxes,
      );

  @override
  bool operator ==(Object other) =>
      other is PosAmount &&
      other.subtotalCents == subtotalCents &&
      other.tipCents == tipCents &&
      other.applyTaxes == applyTaxes;

  @override
  int get hashCode => Object.hash(subtotalCents, tipCents, applyTaxes);
}

/// Server-side transaction row (a snapshot of `pos_transactions`).
class PosTransaction {
  const PosTransaction({
    required this.id,
    required this.proId,
    required this.stripePaymentIntentId,
    required this.amountSubtotalCents,
    required this.tipCents,
    required this.tpsCents,
    required this.tvqCents,
    required this.amountTotalCents,
    required this.applicationFeeCents,
    required this.currency,
    required this.status,
    this.paymentMethodType,
    this.paymentMethodBrand,
    this.paymentMethodLast4,
    this.customerEmail,
    this.customerPhone,
    this.receiptSent = false,
    this.receiptSentAt,
    this.refundedAmountCents = 0,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String proId;
  final String stripePaymentIntentId;

  final int amountSubtotalCents;
  final int tipCents;
  final int tpsCents;
  final int tvqCents;
  final int amountTotalCents;
  final int applicationFeeCents;
  final String currency;

  final String status; // see SQL check constraint
  final String? paymentMethodType;
  final String? paymentMethodBrand;
  final String? paymentMethodLast4;

  final String? customerEmail;
  final String? customerPhone;
  final bool receiptSent;
  final DateTime? receiptSentAt;

  final int refundedAmountCents;
  final String? failureReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSucceeded => status == 'succeeded';
  bool get isRefundable =>
      status == 'succeeded' || status == 'partially_refunded';
  int get netToProCents => amountTotalCents - applicationFeeCents;

  factory PosTransaction.fromJson(Map<String, dynamic> json) => PosTransaction(
        id: json['id'] as String,
        proId: json['pro_id'] as String,
        stripePaymentIntentId: json['stripe_payment_intent_id'] as String,
        amountSubtotalCents: (json['amount_subtotal_cents'] as num).toInt(),
        tipCents: (json['tip_cents'] as num).toInt(),
        tpsCents: (json['tps_cents'] as num).toInt(),
        tvqCents: (json['tvq_cents'] as num).toInt(),
        amountTotalCents: (json['amount_total_cents'] as num).toInt(),
        applicationFeeCents: (json['application_fee_cents'] as num).toInt(),
        currency: json['currency'] as String? ?? 'cad',
        status: json['status'] as String,
        paymentMethodType: json['payment_method_type'] as String?,
        paymentMethodBrand: json['payment_method_brand'] as String?,
        paymentMethodLast4: json['payment_method_last4'] as String?,
        customerEmail: json['customer_email'] as String?,
        customerPhone: json['customer_phone'] as String?,
        receiptSent: json['receipt_sent'] as bool? ?? false,
        receiptSentAt: json['receipt_sent_at'] == null
            ? null
            : DateTime.parse(json['receipt_sent_at'] as String),
        refundedAmountCents:
            (json['refunded_amount_cents'] as num?)?.toInt() ?? 0,
        failureReason: json['failure_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

/// Response from `create-pos-payment-intent` — everything the Stripe
/// Terminal SDK needs to collect + confirm on-device.
class PosPaymentIntentRef {
  const PosPaymentIntentRef({
    required this.clientSecret,
    required this.transactionId,
    required this.paymentIntentId,
  });

  final String clientSecret;
  final String transactionId;
  final String paymentIntentId;
}

/// Terminal collection outcome for UI routing.
class PosPaymentResult {
  const PosPaymentResult.success({
    required this.transactionId,
    required this.paymentIntentId,
    this.cardBrand,
    this.cardLast4,
  })  : success = true,
        errorCode = null,
        errorMessage = null;

  const PosPaymentResult.failure({
    required this.errorCode,
    required this.errorMessage,
    this.transactionId,
    this.paymentIntentId,
  })  : success = false,
        cardBrand = null,
        cardLast4 = null;

  final bool success;
  final String? transactionId;
  final String? paymentIntentId;
  final String? cardBrand;
  final String? cardLast4;
  final PosErrorCode? errorCode;
  final String? errorMessage;
}

/// Refund server response.
class PosRefundResult {
  const PosRefundResult({
    required this.refundId,
    required this.refundedAmountCents,
    required this.status,
  });

  final String refundId;
  final int refundedAmountCents;
  final String status; // 'refunded' | 'partially_refunded'

  factory PosRefundResult.fromJson(Map<String, dynamic> json) =>
      PosRefundResult(
        refundId: json['refund_id'] as String,
        refundedAmountCents: (json['refunded_amount_cents'] as num).toInt(),
        status: json['status'] as String,
      );
}
