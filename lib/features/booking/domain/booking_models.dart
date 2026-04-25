class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.proId,
    required this.name,
    this.description,
    this.durationMinutes = 60,
    required this.price,
    this.currency = 'CAD',
    this.isActive = true,
    this.depositType,
    this.depositValue,
    this.paymentMode,
    // Traiteur-specific fields
    this.cuisineType,
    this.minPersons,
    this.maxPersons,
    this.pricePerPerson,
    this.menuItems = const [],
    this.extraOptions = const [],
  });

  final String id;
  final String proId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final String currency;
  final bool isActive;
  final String? depositType;
  final double? depositValue;
  final String? paymentMode;

  // Traiteur-specific
  final String? cuisineType;
  final int? minPersons;
  final int? maxPersons;
  final double? pricePerPerson;
  final List<MenuItemModel> menuItems;
  final List<TraiteurExtraOption> extraOptions;

  bool get isDepositMode => paymentMode == 'deposit';
  bool get isTraiteurService => pricePerPerson != null;

  double totalForPersons(int persons) {
    if (pricePerPerson != null) return pricePerPerson! * persons;
    return price;
  }

  /// Calcule le montant d'acompte attendu pour un [total] donné, en
  /// appliquant la configuration du service.
  ///
  /// Règles (alignées sur la table `services` et
  /// `create_booking_atomic` côté Postgres) :
  /// - `payment_mode = 'full'` → [total] (tout est encaissé d'un coup, pas
  ///   d'acompte distinct).
  /// - `payment_mode = 'deposit'` + `deposit_type = 'percentage'` →
  ///   `total * deposit_value / 100`, borné à [total].
  /// - `payment_mode = 'deposit'` + `deposit_type = 'fixed'` →
  ///   `min(deposit_value, total)`.
  /// - Config incomplète (services legacy sans ces colonnes) → fallback
  ///   historique 30 % — voir CLAUDE.md. Ne pas relâcher ce fallback tant
  ///   qu'un batch de re-seed n'a pas garni toutes les lignes.
  double computeDeposit(double total) {
    if (paymentMode == 'full') return total;
    final v = depositValue;
    if (paymentMode == 'deposit' && v != null) {
      if (depositType == 'fixed') return v > total ? total : v;
      if (depositType == 'percentage') {
        final raw = total * v / 100;
        return (raw > total ? total : raw);
      }
    }
    // Fallback historique — préserve le comportement antérieur pour les
    // services sans config deposit_* remplie.
    return (total * 0.30 * 100).roundToDouble() / 100;
  }

  /// Pourcentage à afficher dans l'UI (ex : "Acompte 25 %"). Nullable si
  /// la config ne permet pas de l'inférer (mode 'full' ou deposit fixed).
  int? get displayDepositPercent {
    if (paymentMode == 'deposit' && depositType == 'percentage') {
      return depositValue?.round();
    }
    return null;
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final menuItemsRaw = json['menu_items'] as List<dynamic>? ?? [];
    final extrasRaw = json['extra_options'] as List<dynamic>? ?? [];

    return ServiceModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'CAD',
      isActive: json['is_active'] as bool? ?? true,
      depositType: json['deposit_type'] as String?,
      depositValue: (json['deposit_value'] as num?)?.toDouble(),
      paymentMode: json['payment_mode'] as String?,
      cuisineType: json['cuisine_type'] as String?,
      minPersons: json['min_persons'] as int?,
      maxPersons: json['max_persons'] as int?,
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble(),
      menuItems: menuItemsRaw
          .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      extraOptions: extrasRaw
          .map((e) => TraiteurExtraOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.category,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String? category;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      category: json['category'] as String?,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isGlutenFree: json['is_gluten_free'] as bool? ?? false,
    );
  }
}

class TraiteurExtraOption {
  const TraiteurExtraOption({
    required this.id,
    required this.name,
    required this.pricePerPerson,
  });

  final String id;
  final String name;
  final double pricePerPerson;

  factory TraiteurExtraOption.fromJson(Map<String, dynamic> json) {
    return TraiteurExtraOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble() ?? 0,
    );
  }
}

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

  factory AvailabilityRuleModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityRuleModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 30,
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
    this.remainingAmount,
    this.remainingPaymentStatus,
    this.isDepositMode = false,
    this.qrHash,
    this.qrCodeUrl,
    this.scannedAt,
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
  final double? remainingAmount;
  final String? remainingPaymentStatus;
  final bool isDepositMode;
  final String? qrHash;
  final String? qrCodeUrl;
  final DateTime? scannedAt;

  bool get hasQrCode => qrHash != null && qrHash!.isNotEmpty;
  bool get isScanned => scannedAt != null;
  String? get qrData => hasQrCode ? 'B:$id|$qrHash' : null;

  bool get isUpcoming =>
      status == 'pending_payment' || status == 'confirmed';
  bool get isCancelled =>
      status == 'cancelled_full_refund' || status == 'cancelled_no_refund';
  bool get isPast => status == 'completed';
  bool get hasRemainingPayment =>
      isDepositMode && (remainingAmount ?? 0) > 0;
  /// True once the on-site solde has been collected (Tap to Pay or manual)
  /// or explicitly waived. The DB column never stores `'paid'` — historical
  /// values are `'paid_on_site'` (POS / manual mark) and `'waived'` (Pro
  /// chose to absorb the difference). Anything else means still due.
  bool get isRemainingPaid =>
      remainingPaymentStatus == 'paid_on_site' ||
      remainingPaymentStatus == 'waived';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;
    final slot = json['time_slots'] as Map<String, dynamic>?;
    // New structure: pro:users!pro_id(..., profiles_pro(...))
    final proUser = json['pro'] as Map<String, dynamic>?;
    final pro = proUser?['profiles_pro'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>? ??
        json['users'] as Map<String, dynamic>?;

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
      serviceName: service?['title'] as String? ?? service?['name'] as String?,
      slotDate: slot?['date'] as String?,
      slotStartTime: slot?['start_time'] as String?,
      proAvatarUrl: proUser?['avatar_url'] as String?,
      clientName: client?['full_name'] as String?,
      clientAvatarUrl: client?['avatar_url'] as String?,
      serviceDurationMinutes: service?['duration_minutes'] as int?,
      slotEndTime: slot?['end_time'] as String?,
      remainingAmount: total - deposit,
      remainingPaymentStatus: json['remaining_payment_status'] as String?,
      isDepositMode: deposit > 0 && deposit < total,
      qrHash: json['qr_hash'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      scannedAt: json['scanned_at'] != null
          ? DateTime.tryParse(json['scanned_at'] as String)
          : null,
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
