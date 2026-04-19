// Pro-side payout preferences and request history.
// Supports Squire-style "Get Paid Faster" via Stripe Instant Payouts.

enum PayoutSchedule { standard, daily, weekly, manual }

enum PayoutMethod { standard, instant }

enum PayoutStatus { pending, processing, paid, failed, cancelled }

/// Pro's preference for how they receive their earnings.
class PayoutPreferences {
  const PayoutPreferences({
    required this.proId,
    this.schedule = PayoutSchedule.standard,
    this.instantEnabled = false,
    this.minAutoPayoutCents = 5000,
  });

  final String proId;
  final PayoutSchedule schedule;
  final bool instantEnabled;
  final int minAutoPayoutCents;

  factory PayoutPreferences.fromJson(Map<String, dynamic> json) {
    PayoutSchedule s(String v) {
      return PayoutSchedule.values.firstWhere(
        (e) => e.name == v,
        orElse: () => PayoutSchedule.standard,
      );
    }

    return PayoutPreferences(
      proId: json['pro_id'] as String,
      schedule: s(json['schedule'] as String? ?? 'standard'),
      instantEnabled: json['instant_enabled'] as bool? ?? false,
      minAutoPayoutCents: json['min_auto_payout_cents'] as int? ?? 5000,
    );
  }

  PayoutPreferences copyWith({
    PayoutSchedule? schedule,
    bool? instantEnabled,
    int? minAutoPayoutCents,
  }) =>
      PayoutPreferences(
        proId: proId,
        schedule: schedule ?? this.schedule,
        instantEnabled: instantEnabled ?? this.instantEnabled,
        minAutoPayoutCents: minAutoPayoutCents ?? this.minAutoPayoutCents,
      );

  Map<String, dynamic> toUpsertJson() => {
        'pro_id': proId,
        'schedule': schedule.name,
        'instant_enabled': instantEnabled,
        'min_auto_payout_cents': minAutoPayoutCents,
      };
}

/// One entry in the Pro's payout history.
class PayoutRequest {
  const PayoutRequest({
    required this.id,
    required this.proId,
    required this.amountCents,
    required this.currency,
    required this.method,
    required this.feeCents,
    required this.netCents,
    required this.status,
    this.stripePayoutId,
    this.failureReason,
    required this.requestedAt,
    this.completedAt,
    this.expectedArrival,
  });

  final String id;
  final String proId;
  final int amountCents;
  final String currency;
  final PayoutMethod method;
  final int feeCents;
  final int netCents;
  final PayoutStatus status;
  final String? stripePayoutId;
  final String? failureReason;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? expectedArrival;

  double get amountDollars => amountCents / 100.0;
  double get feeDollars => feeCents / 100.0;
  double get netDollars => netCents / 100.0;

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    PayoutMethod m(String v) => v == 'instant'
        ? PayoutMethod.instant
        : PayoutMethod.standard;
    PayoutStatus s(String v) => PayoutStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => PayoutStatus.pending,
        );
    return PayoutRequest(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      amountCents: json['amount_cents'] as int,
      currency: json['currency'] as String? ?? 'CAD',
      method: m(json['method'] as String? ?? 'standard'),
      feeCents: json['fee_cents'] as int? ?? 0,
      netCents: json['net_cents'] as int,
      status: s(json['status'] as String? ?? 'pending'),
      stripePayoutId: json['stripe_payout_id'] as String?,
      failureReason: json['failure_reason'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expectedArrival: json['expected_arrival'] != null
          ? DateTime.parse(json['expected_arrival'] as String)
          : null,
    );
  }
}

/// Snapshot of the Pro's available/pending balance, used by the dashboard.
class PayoutBalance {
  const PayoutBalance({
    required this.availableCents,
    required this.pendingCents,
    this.currency = 'CAD',
  });

  final int availableCents;
  final int pendingCents;
  final String currency;

  double get availableDollars => availableCents / 100.0;
  double get pendingDollars => pendingCents / 100.0;
}
