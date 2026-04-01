List<Map<String, dynamic>> _mapListOfMaps(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

DateTime? _parseEventDate(Map<String, dynamic>? event) {
  if (event == null) return null;
  for (final key in ['start_date', 'event_date']) {
    final v = event[key];
    if (v is String && v.trim().isNotEmpty) {
      final d = DateTime.tryParse(v);
      if (d != null) return d;
    }
  }
  return null;
}

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
    this.socialConnections = const [],
    this.durationSeconds,
    this.savesCount = 0,
    this.proCategory,
    this.serviceId,
    this.serviceName,
    this.servicePrice,
    this.serviceNextSlot,
    this.eventId,
    this.eventName,
    this.eventPrice,
    this.eventDate,
    this.eventLocation,
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
  final int savesCount;
  final DateTime createdAt;
  final String? proName;
  final String? proAvatarUrl;
  final String? proCity;
  final String? proCategory;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowed;
  final List<Map<String, dynamic>> socialConnections;
  final double? durationSeconds;
  final String? serviceId;
  final String? serviceName;
  final double? servicePrice;
  final String? serviceNextSlot;
  final String? eventId;
  final String? eventName;
  final double? eventPrice;
  final DateTime? eventDate;
  final String? eventLocation;
  final String? spotifyTrackTitle;
  final String? spotifyTrackArtist;

  VideoModel copyWith({
    int? likesCount,
    int? commentsCount,
    int? savesCount,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowed,
  }) {
    return VideoModel(
      id: id,
      proId: proId,
      cloudflareId: cloudflareId,
      streamUrl: streamUrl,
      thumbnailUrl: thumbnailUrl,
      title: title,
      description: description,
      category: category,
      hashtags: hashtags,
      status: status,
      rejectionReason: rejectionReason,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount,
      flagCount: flagCount,
      savesCount: savesCount ?? this.savesCount,
      createdAt: createdAt,
      proName: proName,
      proAvatarUrl: proAvatarUrl,
      proCity: proCity,
      proCategory: proCategory,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowed: isFollowed ?? this.isFollowed,
      socialConnections: socialConnections,
      durationSeconds: durationSeconds,
      serviceId: serviceId,
      serviceName: serviceName,
      servicePrice: servicePrice,
      serviceNextSlot: serviceNextSlot,
      eventId: eventId,
      eventName: eventName,
      eventPrice: eventPrice,
      eventDate: eventDate,
      eventLocation: eventLocation,
      spotifyTrackTitle: spotifyTrackTitle,
      spotifyTrackArtist: spotifyTrackArtist,
    );
  }

  factory VideoModel.fromJson(Map<String, dynamic> json, {
    bool isLiked = false,
    bool isSaved = false,
    bool isFollowed = false,
  }) {
    final usersMap = json['users'] as Map<String, dynamic>?;
    final nestedRaw = usersMap?['profiles_pro'];
    Map<String, dynamic>? nestedPro;
    if (nestedRaw is Map<String, dynamic>) {
      nestedPro = nestedRaw;
    } else if (nestedRaw is List && nestedRaw.isNotEmpty) {
      final first = nestedRaw.first;
      if (first is Map<String, dynamic>) nestedPro = first;
    }
    final pro = json['profiles_pro'] as Map<String, dynamic>? ?? nestedPro;
    final user = pro?['users'] as Map<String, dynamic>? ?? usersMap;
    final service = json['services'] as Map<String, dynamic>?;
    final event = json['events'] as Map<String, dynamic>?;

    final cfId = json['cloudflare_id'] as String? ??
        json['cloudflare_uid'] as String?;

    return VideoModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      cloudflareId: cfId,
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
      savesCount: json['saves_count'] as int? ??
          json['share_count'] as int? ??
          0,
      createdAt: DateTime.parse(json['created_at'] as String),
      proName:
          user?['full_name'] as String? ?? pro?['business_name'] as String?,
      proAvatarUrl: user?['avatar_url'] as String?,
      proCity: user?['city'] as String?,
      proCategory: pro?['category'] as String?,
      isLiked: isLiked,
      isSaved: isSaved,
      isFollowed: isFollowed,
      socialConnections: _mapListOfMaps(pro?['social_connections']),
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ??
          (json['duration'] as num?)?.toDouble(),
      serviceId: json['service_id'] as String?,
      serviceName: service?['name'] as String? ?? service?['title'] as String?,
      servicePrice: (service?['price'] as num?)?.toDouble(),
      serviceNextSlot: json['service_next_slot'] as String?,
      eventId: json['event_id'] as String?,
      eventName: event?['title'] as String?,
      eventPrice: (event?['price'] as num?)?.toDouble(),
      eventDate: _parseEventDate(event),
      eventLocation: event?['location'] as String?,
      spotifyTrackTitle: json['spotify_track_title'] as String?,
      spotifyTrackArtist: json['spotify_track_artist'] as String?,
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
