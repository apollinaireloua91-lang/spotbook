/// Règle hebdomadaire (alignée sur `generate-slots` : jour 0 = dimanche … 6 = samedi).
class AvailabilityRuleModel {
  const AvailabilityRuleModel({
    required this.id,
    required this.proId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
  });

  final String id;
  final String proId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;

  static String _normTime(Object? raw) {
    if (raw == null) return '00:00';
    final t = raw.toString();
    final parts = t.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return t;
  }

  factory AvailabilityRuleModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityRuleModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: _normTime(json['start_time']),
      endTime: _normTime(json['end_time']),
      slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 60,
    );
  }
}

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.proId,
    required this.name,
    this.description,
    this.durationMinutes = 60,
    required this.price,
    this.isActive = true,
    this.depositPercentage = 0.30,
    this.paymentMode = 'full',
    this.depositType,
    this.depositValue,
  });

  final String id;
  final String proId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool isActive;

  /// Legacy fraction (0.10–1.00). Kept for backward compat.
  final double depositPercentage;

  /// 'full' = client pays everything online, 'deposit' = partial payment.
  final String paymentMode;

  /// 'percentage' or 'fixed' — only meaningful when paymentMode == 'deposit'.
  final String? depositType;

  /// Percentage value (e.g. 20 for 20%) or fixed amount (e.g. 100).
  final double? depositValue;

  bool get isDepositMode => paymentMode == 'deposit';

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    String displayName = '';
    for (final key in ['name', 'title', 'service_name']) {
      final v = json[key];
      if (v is String && v.trim().isNotEmpty) {
        displayName = v.trim();
        break;
      }
    }

    final legacyPct = (json['deposit_percentage'] as num?)?.toDouble() ?? 0.30;

    // Derive payment_mode from legacy deposit_percentage if new columns absent.
    final rawMode = json['payment_mode'] as String?;
    final paymentMode = rawMode ?? (legacyPct >= 1.0 ? 'full' : 'deposit');

    final rawType = json['deposit_type'] as String?;
    final depositType = rawType ?? (paymentMode == 'deposit' ? 'percentage' : null);

    final rawValue = (json['deposit_value'] as num?)?.toDouble();
    final depositValue = rawValue ??
        (paymentMode == 'deposit' ? (legacyPct * 100) : null);

    return ServiceModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      name: displayName,
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      depositPercentage: legacyPct,
      paymentMode: paymentMode,
      depositType: depositType,
      depositValue: depositValue,
    );
  }
}

class TimeSlotModel {
  const TimeSlotModel({
    required this.id,
    required this.proId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  final String id;
  final String proId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.clientId,
    required this.proId,
    required this.serviceId,
    required this.timeSlotId,
    required this.status,
    required this.depositAmount,
    required this.totalAmount,
    required this.currency,
    this.bookingCode,
    this.stripePaymentIntentId,
    this.transferId,
    this.refundAmount,
    this.refundStatus,
    required this.createdAt,
    this.proName,
    this.serviceName,
    this.slotDate,
    this.slotStartTime,
    this.proAvatarUrl,
    this.clientName,
    this.clientAvatarUrl,
    this.serviceDurationMinutes,
    this.slotEndTime,
    this.paymentMode = 'full',
    this.remainingAmount = 0,
    this.remainingPaymentStatus = 'pending',
  });

  final String id;
  final String clientId;
  final String proId;
  final String serviceId;
  final String timeSlotId;
  final String status;
  final double depositAmount;
  final double totalAmount;
  final String currency;
  final String? bookingCode;
  final String? stripePaymentIntentId;
  final String? transferId;
  final double? refundAmount;
  final String? refundStatus;
  final DateTime createdAt;
  final String? proName;
  final String? serviceName;
  final String? slotDate;
  final String? slotStartTime;
  final String? proAvatarUrl;
  final String? clientName;
  final String? clientAvatarUrl;
  final int? serviceDurationMinutes;
  final String? slotEndTime;

  /// 'full' or 'deposit'.
  final String paymentMode;

  /// Amount remaining to be paid on site.
  final double remainingAmount;

  /// 'pending', 'paid_on_site', or 'waived'.
  final String remainingPaymentStatus;

  bool get isDepositMode => paymentMode == 'deposit';
  bool get hasRemainingPayment => remainingAmount > 0;
  bool get isRemainingPaid => remainingPaymentStatus == 'paid_on_site';

  bool get isUpcoming => status == 'pending_payment' || status == 'confirmed';
  bool get isCancelled =>
      status == 'cancelled_full_refund' || status == 'cancelled_no_refund';
  bool get isPast => status == 'completed';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;
    final slot = json['time_slots'] as Map<String, dynamic>?;
    final clientUser = json['client_user'] as Map<String, dynamic>?;

    // Ancien embed `profiles_pro` ou nouveau `pro_user` (users + profiles_pro imbriqué).
    final proUserDirect = json['pro_user'] as Map<String, dynamic>?;
    final legacyPro = json['profiles_pro'] as Map<String, dynamic>?;
    Map<String, dynamic>? pro = legacyPro;
    Map<String, dynamic>? proUser = legacyPro?['users'] as Map<String, dynamic>?;
    if (proUserDirect != null) {
      proUser = proUserDirect;
      final np = proUserDirect['profiles_pro'];
      if (np is Map<String, dynamic>) {
        pro = np;
      } else if (np is List && np.isNotEmpty && np.first is Map<String, dynamic>) {
        pro = np.first as Map<String, dynamic>;
      }
    }

    final deposit = (json['deposit_amount'] as num?)?.toDouble() ?? 0;
    final total = (json['total_amount'] as num?)?.toDouble() ?? 0;

    return BookingModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      serviceId: json['service_id'] as String,
      timeSlotId: json['time_slot_id'] as String,
      status: json['status'] as String? ?? 'pending_payment',
      depositAmount: deposit,
      totalAmount: total,
      currency: json['currency'] as String? ?? 'CAD',
      bookingCode: json['booking_code'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      transferId: json['transfer_id'] as String?,
      refundAmount: (json['refund_amount'] as num?)?.toDouble(),
      refundStatus: json['refund_status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      proName: proUser?['full_name'] as String? ??
          pro?['business_name'] as String?,
      serviceName: service?['name'] as String?,
      slotDate: slot?['date'] as String?,
      slotStartTime: slot?['start_time'] as String?,
      proAvatarUrl: proUser?['avatar_url'] as String?,
      clientName: clientUser?['full_name'] as String?,
      clientAvatarUrl: clientUser?['avatar_url'] as String?,
      serviceDurationMinutes: service?['duration_minutes'] as int?,
      slotEndTime: _normSlotTime(slot?['end_time']),
      paymentMode: json['payment_mode'] as String? ??
          (deposit >= total ? 'full' : 'deposit'),
      remainingAmount:
          (json['remaining_amount'] as num?)?.toDouble() ??
          (total - deposit > 0 ? total - deposit : 0),
      remainingPaymentStatus:
          json['remaining_payment_status'] as String? ?? 'pending',
    );
  }

  static String? _normSlotTime(Object? raw) {
    if (raw == null) return null;
    final t = raw.toString();
    final parts = t.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return t;
  }
}

class PromoCodeModel {
  const PromoCodeModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final bool isActive;

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      discountType: json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
