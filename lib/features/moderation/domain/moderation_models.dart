class BlockModel {
  const BlockModel({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
    this.blockedName,
    this.blockedAvatarUrl,
  });

  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;
  final String? blockedName;
  final String? blockedAvatarUrl;

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    final blocked = json['blocked_user'] as Map<String, dynamic>?;
    return BlockModel(
      id: json['id'] as String,
      blockerId: json['blocker_id'] as String,
      blockedId: json['blocked_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      blockedName: blocked?['full_name'] as String?,
      blockedAvatarUrl: blocked?['avatar_url'] as String?,
    );
  }
}

class ReportModel {
  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetId;
  final String targetType;
  final String reason;
  final DateTime createdAt;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      targetId: json['target_id'] as String,
      targetType: json['target_type'] as String? ?? 'user',
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
