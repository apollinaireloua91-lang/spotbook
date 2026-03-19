class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.proId,
    required this.name,
    this.description,
    this.durationMinutes = 60,
    required this.price,
    this.isActive = true,
  });

  final String id;
  final String proId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool isActive;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
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

  bool get isUpcoming =>
      status == 'pending_payment' || status == 'confirmed';
  bool get isCancelled =>
      status == 'cancelled_full_refund' || status == 'cancelled_no_refund';
  bool get isPast => status == 'completed';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;
    final slot = json['time_slots'] as Map<String, dynamic>?;
    final pro = json['profiles_pro'] as Map<String, dynamic>?;
    final proUser = pro?['users'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      serviceId: json['service_id'] as String,
      timeSlotId: json['time_slot_id'] as String,
      status: json['status'] as String? ?? 'pending_payment',
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
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
    );
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
