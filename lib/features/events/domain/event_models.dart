class EventModel {
  const EventModel({
    required this.id,
    required this.proId,
    required this.title,
    this.description,
    this.coverUrl,
    this.eventDate,
    this.location,
    this.address,
    this.isActive = true,
    required this.createdAt,
    this.proName,
    this.proAvatarUrl,
    this.ticketTypes = const [],
  });

  final String id;
  final String proId;
  final String title;
  final String? description;
  final String? coverUrl;
  final DateTime? eventDate;
  final String? location;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final String? proName;
  final String? proAvatarUrl;
  final List<TicketTypeModel> ticketTypes;

  double get minPrice {
    if (ticketTypes.isEmpty) return 0;
    return ticketTypes.map((t) => t.price).reduce((a, b) => a < b ? a : b);
  }

  bool get isSoldOut =>
      ticketTypes.isNotEmpty &&
      ticketTypes.every((t) => t.soldCount >= t.quantity);

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final pro = json['profiles_pro'] as Map<String, dynamic>?;
    final proUser = pro?['users'] as Map<String, dynamic>?;
    final types = (json['ticket_types'] as List<dynamic>?)
            ?.map((e) => TicketTypeModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return EventModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
      location: json['location'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      proName:
          proUser?['full_name'] as String? ?? pro?['business_name'] as String?,
      proAvatarUrl: proUser?['avatar_url'] as String?,
      ticketTypes: types,
    );
  }
}

class TicketTypeModel {
  const TicketTypeModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.quantity,
    this.soldCount = 0,
  });

  final String id;
  final String eventId;
  final String name;
  final double price;
  final int quantity;
  final int soldCount;

  int get remaining => quantity - soldCount;
  bool get isSoldOut => remaining <= 0;

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      soldCount: json['sold_count'] as int? ?? 0,
    );
  }
}

class TicketModel {
  const TicketModel({
    required this.id,
    required this.eventId,
    required this.ticketTypeId,
    required this.userId,
    this.qrHash,
    required this.status,
    this.scannedAt,
    required this.purchasedAt,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.eventCoverUrl,
    this.ticketTypeName,
  });

  final String id;
  final String eventId;
  final String ticketTypeId;
  final String userId;
  final String? qrHash;
  final String status;
  final DateTime? scannedAt;
  final DateTime purchasedAt;
  final String? eventTitle;
  final DateTime? eventDate;
  final String? eventLocation;
  final String? eventCoverUrl;
  final String? ticketTypeName;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final event = json['events'] as Map<String, dynamic>?;
    final ticketType = json['ticket_types'] as Map<String, dynamic>?;

    return TicketModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      ticketTypeId: json['ticket_type_id'] as String,
      userId: json['user_id'] as String,
      qrHash: json['qr_hash'] as String?,
      status: json['status'] as String? ?? 'valid',
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'] as String)
          : null,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      eventTitle: event?['title'] as String?,
      eventDate: event?['event_date'] != null
          ? DateTime.parse(event!['event_date'] as String)
          : null,
      eventLocation: event?['location'] as String?,
      eventCoverUrl: event?['cover_url'] as String?,
      ticketTypeName: ticketType?['name'] as String?,
    );
  }
}
