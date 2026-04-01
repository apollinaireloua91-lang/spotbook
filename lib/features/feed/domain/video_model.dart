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
    this.isSaved = false,
    this.isFollowed = false,
    this.savesCount = 0,
    this.socialConnections = const [],
    this.durationSeconds,
    this.serviceId,
    this.serviceName,
    this.servicePrice,
    this.serviceNextSlot,
    this.eventId,
    this.eventName,
    this.eventDate,
    this.proCategory,
    this.spotifyTrackTitle,
    this.spotifyTrackArtist,
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
  final bool isSaved;
  final bool isFollowed;
  final int savesCount;
  final List<Map<String, dynamic>> socialConnections;
  final double? durationSeconds;
  final String? serviceId;
  final String? serviceName;
  final double? servicePrice;
  final String? serviceNextSlot;
  final String? eventId;
  final String? eventName;
  final String? eventDate;
  final String? proCategory;
  final String? spotifyTrackTitle;
  final String? spotifyTrackArtist;

  factory VideoModel.fromJson(Map<String, dynamic> json, {bool isLiked = false, bool isSaved = false}) {
    final pro = json['profiles_pro'] as Map<String, dynamic>?;
    final user = pro?['users'] as Map<String, dynamic>? ??
        json['users'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;
    final event = json['events'] as Map<String, dynamic>?;

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
      proName: user?['full_name'] as String? ??
          pro?['business_name'] as String?,
      proAvatarUrl: user?['avatar_url'] as String?,
      proCity: user?['city'] as String?,
      isLiked: isLiked,
      isSaved: isSaved,
      savesCount: json['saves_count'] as int? ?? 0,
      socialConnections: (pro?['social_connections'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ??
          (json['duration'] as num?)?.toDouble(),
      serviceId: json['service_id'] as String?,
      serviceName: service?['name'] as String? ??
          json['service_name'] as String?,
      servicePrice: (service?['price'] as num?)?.toDouble() ??
          (json['service_price'] as num?)?.toDouble(),
      serviceNextSlot: json['service_next_slot'] as String?,
      eventId: json['event_id'] as String?,
      eventName: event?['name'] as String? ??
          json['event_name'] as String?,
      eventDate: event?['date'] as String? ??
          json['event_date'] as String?,
      proCategory: pro?['category'] as String?,
      spotifyTrackTitle: json['spotify_track_title'] as String?,
      spotifyTrackArtist: json['spotify_track_artist'] as String?,
    );
  }

  VideoModel copyWith({
    String? id,
    String? proId,
    String? cloudflareId,
    String? streamUrl,
    String? thumbnailUrl,
    String? title,
    String? description,
    String? category,
    List<String>? hashtags,
    String? status,
    String? rejectionReason,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    int? flagCount,
    DateTime? createdAt,
    String? proName,
    String? proAvatarUrl,
    String? proCity,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowed,
    int? savesCount,
    List<Map<String, dynamic>>? socialConnections,
    double? durationSeconds,
    String? serviceId,
    String? serviceName,
    double? servicePrice,
    String? serviceNextSlot,
    String? eventId,
    String? eventName,
    String? eventDate,
    String? proCategory,
    String? spotifyTrackTitle,
    String? spotifyTrackArtist,
  }) {
    return VideoModel(
      id: id ?? this.id,
      proId: proId ?? this.proId,
      cloudflareId: cloudflareId ?? this.cloudflareId,
      streamUrl: streamUrl ?? this.streamUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      hashtags: hashtags ?? this.hashtags,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      flagCount: flagCount ?? this.flagCount,
      createdAt: createdAt ?? this.createdAt,
      proName: proName ?? this.proName,
      proAvatarUrl: proAvatarUrl ?? this.proAvatarUrl,
      proCity: proCity ?? this.proCity,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowed: isFollowed ?? this.isFollowed,
      savesCount: savesCount ?? this.savesCount,
      socialConnections: socialConnections ?? this.socialConnections,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      serviceNextSlot: serviceNextSlot ?? this.serviceNextSlot,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      proCategory: proCategory ?? this.proCategory,
      spotifyTrackTitle: spotifyTrackTitle ?? this.spotifyTrackTitle,
      spotifyTrackArtist: spotifyTrackArtist ?? this.spotifyTrackArtist,
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
