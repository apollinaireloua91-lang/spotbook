class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.coverUrl,
    this.city,
    this.username,
    this.bio,
  });

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? coverUrl;
  final String? city;
  final String? username;
  final String? bio;

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      city: json['city'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
    );
  }
}

class ClientFavoriteProItem {
  const ClientFavoriteProItem({
    required this.proId,
    this.businessName,
    this.avatarUrl,
    this.category,
  });

  final String proId;
  final String? businessName;
  final String? avatarUrl;
  final String? category;

  factory ClientFavoriteProItem.fromJson(Map<String, dynamic> json) {
    final pro = json['profiles_pro'] as Map<String, dynamic>? ?? {};
    final user = pro['users'] as Map<String, dynamic>? ?? {};
    return ClientFavoriteProItem(
      proId: json['pro_id'] as String? ?? pro['id'] as String? ?? '',
      businessName: pro['business_name'] as String?,
      avatarUrl: user['avatar_url'] as String?,
      category: pro['category'] as String?,
    );
  }
}

class ClientFavoriteVideoItem {
  const ClientFavoriteVideoItem({
    required this.videoId,
    this.title,
    this.thumbnailUrl,
    this.proName,
  });

  final String videoId;
  final String? title;
  final String? thumbnailUrl;
  final String? proName;

  factory ClientFavoriteVideoItem.fromJson(Map<String, dynamic> json) {
    final video = json['videos'] as Map<String, dynamic>? ?? {};
    // Structure: videos(*, users!pro_id(..., profiles_pro(...)))
    final user = video['users'] as Map<String, dynamic>? ?? {};
    final pro = user['profiles_pro'] as Map<String, dynamic>? ?? {};
    return ClientFavoriteVideoItem(
      videoId: json['post_id'] as String? ?? video['id'] as String? ?? '',
      title: video['title'] as String?,
      thumbnailUrl: video['thumbnail_url'] as String?,
      proName: user['full_name'] as String? ?? pro['business_name'] as String?,
    );
  }
}

class SocialConnection {
  const SocialConnection({
    required this.id,
    required this.platform,
    required this.handle,
    required this.followersCount,
  });

  final String id;
  final String platform;
  final String handle;
  final int followersCount;

  factory SocialConnection.fromJson(Map<String, dynamic> json) {
    return SocialConnection(
      id: json['id'] as String,
      platform: json['platform'] as String,
      handle: json['handle'] as String,
      followersCount: json['followers_count'] as int? ?? 0,
    );
  }
}

class ProProfile {
  const ProProfile({
    required this.id,
    required this.businessName,
    required this.category,
    this.bio,
    this.city,
    this.avatarUrl,
    this.coverUrl,
    this.username,
    this.isTopPro = false,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.socialConnections = const [],
    this.isFollowedByMe = false,
  });

  final String id;
  final String businessName;
  final String category;
  final String? bio;
  final String? city;
  final String? avatarUrl;
  final String? coverUrl;
  final String? username;
  final bool isTopPro;
  final double rating;
  final int reviewsCount;
  final List<SocialConnection> socialConnections;
  final bool isFollowedByMe;

  factory ProProfile.fromJson(Map<String, dynamic> json, {bool isFollowedByMe = false}) {
    final user = json['users'] as Map<String, dynamic>? ?? {};
    final socials = (json['social_links'] as List<dynamic>?)
            ?.map((e) => SocialConnection.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ProProfile(
      id: json['id'] as String,
      businessName: json['business_name'] as String? ?? 'Pro',
      category: json['category'] as String? ?? '',
      bio: json['description'] as String?,
      city: user['city'] as String?,
      avatarUrl: user['avatar_url'] as String?,
      coverUrl: user['cover_url'] as String?,
      username: user['username'] as String?,
      isTopPro: json['is_top_pro'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      socialConnections: socials,
      isFollowedByMe: isFollowedByMe,
    );
  }
}
