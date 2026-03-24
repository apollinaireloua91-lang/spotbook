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
    final userId = json['user_id'] as String;
    final targetId = json['target_id'] as String;
    return FavoriteModel(
      id: json['id'] as String? ?? '${userId}_$targetId',
      userId: userId,
      targetId: targetId,
      targetType: json['target_type'] as String? ?? 'pro',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      targetName: json['target_name'] as String?,
      targetImageUrl: json['target_image_url'] as String?,
      targetSubtitle: json['target_subtitle'] as String?,
    );
  }
}
