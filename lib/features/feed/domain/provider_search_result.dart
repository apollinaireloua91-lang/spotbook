class ProviderSearchResult {
  const ProviderSearchResult({
    required this.id,
    this.businessName,
    this.category,
    this.description,
    this.averageRating,
    this.reviewCount,
    this.fullName,
    this.avatarUrl,
    this.city,
    this.username,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.minPrice,
    this.isOnline,
  });

  final String id;
  final String? businessName;
  final String? category;
  final String? description;
  final double? averageRating;
  final int? reviewCount;
  final String? fullName;
  final String? avatarUrl;
  final String? city;
  final String? username;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final double? minPrice;
  final bool? isOnline;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Mise à jour légère (ex. distance calculée côté client).
  ProviderSearchResult copyWith({
    double? distanceKm,
  }) {
    return ProviderSearchResult(
      id: id,
      businessName: businessName,
      category: category,
      description: description,
      averageRating: averageRating,
      reviewCount: reviewCount,
      fullName: fullName,
      avatarUrl: avatarUrl,
      city: city,
      username: username,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude,
      longitude: longitude,
      minPrice: minPrice,
      isOnline: isOnline,
    );
  }

  String get displayName =>
      (businessName != null && businessName!.trim().isNotEmpty)
          ? businessName!.trim()
          : (fullName ?? username ?? 'Pro');

  factory ProviderSearchResult.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is String
        ? rawId
        : rawId != null
            ? rawId.toString()
            : '';
    if (id.isEmpty) {
      throw FormatException('ProviderSearchResult.fromJson: missing id', json);
    }
    return ProviderSearchResult(
      id: id,
      businessName: json['business_name'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      username: json['username'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      minPrice: (json['min_price'] as num?)?.toDouble(),
      isOnline: json['is_online'] as bool?,
    );
  }
}
