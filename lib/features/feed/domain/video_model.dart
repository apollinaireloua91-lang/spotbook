class VideoModel {
  const VideoModel({
    required this.id,
    required this.proId,
    this.cloudflareId,
    this.streamUrl,
    this.thumbnailUrl,
    required this.title,
    this.description,
    this.category,
    this.hashtags = const [],
    required this.status,
    this.rejectionReason,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.flagCount = 0,
    required this.createdAt,
    this.proName,
    this.proAvatarUrl,
    this.proCity,
    this.isLiked = false,
    this.socialConnections = const [],
    this.durationSeconds,
  });

  final String id;
  final String proId;
  final String? cloudflareId;
  final String? streamUrl;
  final String? thumbnailUrl;
  final String title;
  final String? description;
  final String? category;
  final List<String> hashtags;
  final String status;
  final String? rejectionReason;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final int flagCount;
  final DateTime createdAt;
  final String? proName;
  final String? proAvatarUrl;
  final String? proCity;
  final bool isLiked;
  final List<Map<String, dynamic>> socialConnections;
  final double? durationSeconds;

  factory VideoModel.fromJson(Map<String, dynamic> json,
      {bool isLiked = false}) {
    final pro = json['profiles_pro'] as Map<String, dynamic>?;
    final user = pro?['users'] as Map<String, dynamic>? ??
        json['users'] as Map<String, dynamic>?;

    return VideoModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      cloudflareId: json['cloudflare_id'] as String?,
      streamUrl: json['stream_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      hashtags: (json['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending_review',
      rejectionReason: json['rejection_reason'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      flagCount: json['flag_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      proName:
          user?['full_name'] as String? ?? pro?['business_name'] as String?,
      proAvatarUrl: user?['avatar_url'] as String?,
      proCity: user?['city'] as String?,
      isLiked: isLiked,
      socialConnections: (pro?['social_connections'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      durationSeconds: (json['duration'] as num?)?.toDouble(),
    );
  }
}

class CommentModel {
  const CommentModel({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });

  final String id;
  final String videoId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return CommentModel(
      id: json['id'] as String,
      videoId: json['video_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: user?['full_name'] as String?,
      userAvatarUrl: user?['avatar_url'] as String?,
    );
  }
}
