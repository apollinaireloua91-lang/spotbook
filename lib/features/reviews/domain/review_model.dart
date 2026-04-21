class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.proId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.clientName,
    this.clientAvatarUrl,
    this.serviceName,
  });

  final String id;
  final String bookingId;
  final String clientId;
  final String proId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? clientName;
  final String? clientAvatarUrl;
  final String? serviceName;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final client = json['users'] as Map<String, dynamic>?;
    final services = json['services'] as Map<String, dynamic>?;
    final booking = json['bookings'] as Map<String, dynamic>?;
    final bookingService = booking?['services'] as Map<String, dynamic>?;
    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      clientName: client?['full_name'] as String?,
      clientAvatarUrl: client?['avatar_url'] as String?,
      serviceName: services?['name'] as String? ??
          json['service_name'] as String? ??
          bookingService?['name'] as String?,
    );
  }
}

/// A completed booking that the client can still rate — surfaced in the
/// client's "Reviews" inbox. The DB trigger `tr_review_update_rating`
/// automatically recomputes the pro's `rating_average` / `rating_count`
/// when a review row is inserted, so syncing with the pro account is free.
class ReviewableBookingItem {
  const ReviewableBookingItem({
    required this.bookingId,
    required this.proId,
    required this.proDisplayName,
    required this.completedAt,
    this.serviceName,
    this.proAvatarUrl,
    this.proCategory,
  });

  final String bookingId;
  final String proId;
  final String proDisplayName;
  final DateTime completedAt;
  final String? serviceName;
  final String? proAvatarUrl;
  final String? proCategory;

  factory ReviewableBookingItem.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;
    final pro = json['pro'] as Map<String, dynamic>?;
    final proProfile = pro?['profiles_pro'];
    // profiles_pro is a 1:1 relation — Supabase returns it either as a
    // nested object or as a single-element list depending on the FK setup.
    final proProfileMap = proProfile is List
        ? (proProfile.isNotEmpty
            ? proProfile.first as Map<String, dynamic>
            : null)
        : proProfile as Map<String, dynamic>?;

    final displayName = (proProfileMap?['business_name'] as String?)
            ?.trim()
            .isNotEmpty ==
            true
        ? proProfileMap!['business_name'] as String
        : (pro?['display_name'] as String?) ??
            (pro?['full_name'] as String?) ??
            'Pro';

    return ReviewableBookingItem(
      bookingId: json['id'] as String,
      proId: json['pro_id'] as String,
      proDisplayName: displayName,
      completedAt: DateTime.parse(
        (json['completed_at'] ?? json['created_at']) as String,
      ),
      serviceName: (service?['name'] ?? service?['title']) as String?,
      proAvatarUrl: pro?['avatar_url'] as String?,
      proCategory: proProfileMap?['category'] as String?,
    );
  }
}
