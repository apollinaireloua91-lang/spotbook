// Models for multi-service bookings and service add-ons.
//
// Architecture note: these are separate from `booking_models.dart` to keep
// the booking domain layered cleanly — `ServiceAddon` is a Pro-owned catalog
// entity, while `BookingService` and `BookingAddon` are junction/snapshot
// rows tied to a specific booking.

/// A paid optional extra attached to a service (e.g. hair wash +$5).
/// Managed by the Pro. Visible to clients only when `isActive = true`.
class ServiceAddon {
  const ServiceAddon({
    required this.id,
    required this.serviceId,
    required this.proId,
    required this.name,
    this.description,
    required this.price,
    this.durationMinutes = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String serviceId;
  final String proId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final bool isActive;
  final int sortOrder;

  /// Creates a new unsaved addon (before Supabase insert).
  factory ServiceAddon.draft({
    required String serviceId,
    required String proId,
    required String name,
    String? description,
    required double price,
    int durationMinutes = 0,
    int sortOrder = 0,
  }) =>
      ServiceAddon(
        id: '',
        serviceId: serviceId,
        proId: proId,
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        sortOrder: sortOrder,
      );

  ServiceAddon copyWith({
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
    int? sortOrder,
  }) =>
      ServiceAddon(
        id: id,
        serviceId: serviceId,
        proId: proId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toInsertJson() => {
        'service_id': serviceId,
        'pro_id': proId,
        'name': name,
        'description': description,
        'price': price,
        'duration_minutes': durationMinutes,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'price': price,
        'duration_minutes': durationMinutes,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  factory ServiceAddon.fromJson(Map<String, dynamic> json) => ServiceAddon(
        id: json['id'] as String,
        serviceId: json['service_id'] as String,
        proId: json['pro_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        durationMinutes: json['duration_minutes'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

/// Price + duration snapshot of a service at the time of booking.
/// Persisted in `booking_services` junction table.
class BookingService {
  const BookingService({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.price,
    required this.durationMinutes,
    this.sortOrder = 0,
    this.serviceName,
    this.addons = const [],
  });

  final String id;
  final String bookingId;
  final String serviceId;
  final double price;
  final int durationMinutes;
  final int sortOrder;
  final String? serviceName; // Populated via join
  final List<BookingAddon> addons;

  double get totalWithAddons =>
      price + addons.fold<double>(0, (sum, a) => sum + a.price);

  int get totalDurationWithAddons =>
      durationMinutes +
      addons.fold<int>(0, (sum, a) => sum + a.durationMinutes);

  factory BookingService.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;
    final addonsRaw = json['booking_addons'] as List<dynamic>? ?? [];
    return BookingService(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      serviceId: json['service_id'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
      sortOrder: json['sort_order'] as int? ?? 0,
      serviceName: service?['title'] as String? ?? service?['name'] as String?,
      addons: addonsRaw
          .map((e) => BookingAddon.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A chosen add-on for a specific booking. Price & name snapshotted at booking time
/// so historical receipts remain accurate if the Pro later edits the catalog entry.
class BookingAddon {
  const BookingAddon({
    required this.id,
    required this.bookingId,
    this.bookingServiceId,
    required this.addonId,
    required this.nameSnapshot,
    required this.price,
    this.durationMinutes = 0,
  });

  final String id;
  final String bookingId;
  final String? bookingServiceId;
  final String addonId;
  final String nameSnapshot;
  final double price;
  final int durationMinutes;

  factory BookingAddon.fromJson(Map<String, dynamic> json) => BookingAddon(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        bookingServiceId: json['booking_service_id'] as String?,
        addonId: json['addon_id'] as String,
        nameSnapshot: json['name_snapshot'] as String,
        price: (json['price'] as num).toDouble(),
        durationMinutes: json['duration_minutes'] as int? ?? 0,
      );
}

/// DTO for composing a multi-service booking before submission.
/// Used by the client booking flow to accumulate selections across steps.
class BookingCart {
  const BookingCart({
    this.items = const [],
  });

  final List<BookingCartItem> items;

  double get subtotal => items.fold<double>(0, (sum, it) => sum + it.totalPrice);
  int get totalDurationMinutes =>
      items.fold<int>(0, (sum, it) => sum + it.totalDuration);
  bool get isEmpty => items.isEmpty;
  int get serviceCount => items.length;

  BookingCart addItem(BookingCartItem item) =>
      BookingCart(items: [...items, item]);

  BookingCart removeAt(int index) {
    final copy = [...items]..removeAt(index);
    return BookingCart(items: copy);
  }

  BookingCart updateAt(int index, BookingCartItem item) {
    final copy = [...items];
    copy[index] = item;
    return BookingCart(items: copy);
  }
}

/// A single "line" in the booking cart — one service + its chosen add-ons.
class BookingCartItem {
  const BookingCartItem({
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDurationMinutes,
    this.selectedAddons = const [],
  });

  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDurationMinutes;
  final List<ServiceAddon> selectedAddons;

  double get totalPrice =>
      servicePrice +
      selectedAddons.fold<double>(0, (sum, a) => sum + a.price);

  int get totalDuration =>
      serviceDurationMinutes +
      selectedAddons.fold<int>(0, (sum, a) => sum + a.durationMinutes);

  BookingCartItem toggleAddon(ServiceAddon addon) {
    final exists = selectedAddons.any((a) => a.id == addon.id);
    final updated = exists
        ? selectedAddons.where((a) => a.id != addon.id).toList()
        : [...selectedAddons, addon];
    return BookingCartItem(
      serviceId: serviceId,
      serviceName: serviceName,
      servicePrice: servicePrice,
      serviceDurationMinutes: serviceDurationMinutes,
      selectedAddons: updated,
    );
  }
}
