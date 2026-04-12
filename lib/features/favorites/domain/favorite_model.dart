class FavoriteModel {
  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.createdAt,
    this.targetName,
    this.targetImageUrl,
    this.targetSubtitle,
  });

  final String id;
  final String userId;
  final String targetId;
  final String targetType;
  final DateTime createdAt;
  final String? targetName;
  final String? targetImageUrl;
  final String? targetSubtitle;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetId: json['target_id'] as String,
      targetType: json['target_type'] as String? ?? 'pro',
      createdAt: DateTime.parse(json['created_at'] as String),
      targetName: json['target_name'] as String?,
      targetImageUrl: json['target_image_url'] as String?,
      targetSubtitle: json['target_subtitle'] as String?,
    );
  }
}
