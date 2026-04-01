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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final client = json['users'] as Map<String, dynamic>?;
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
    );
  }
}
