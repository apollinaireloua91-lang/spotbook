// ═════════════════════════════════════════════════════════════════════════════
// CATERING DOMAIN MODELS — maps to catering_* Supabase tables
// ═════════════════════════════════════════════════════════════════════════════

/// Row from `catering_menu_items` (12 columns).
class CateringMenuItem {
  const CateringMenuItem({
    required this.id,
    required this.proId,
    required this.name,
    this.description,
    this.pricePerPerson,
    this.emoji,
    this.photoUrl,
    this.category,
    this.isBestseller = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String proId;
  final String name;
  final String? description;
  final double? pricePerPerson;
  final String? emoji;
  final String? photoUrl;
  final String? category;
  final bool isBestseller;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;

  factory CateringMenuItem.fromJson(Map<String, dynamic> json) {
    return CateringMenuItem(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble(),
      emoji: json['emoji'] as String?,
      photoUrl: json['photo_url'] as String?,
      category: json['category'] as String?,
      isBestseller: json['is_bestseller'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Auto-detect emoji from dish name if none set.
  String get displayEmoji {
    if (emoji != null && emoji!.isNotEmpty) return emoji!;
    final lower = name.toLowerCase();
    if (lower.contains('poulet') || lower.contains('chicken')) return '🍗';
    if (lower.contains('mafe') || lower.contains('curry')) return '🍛';
    if (lower.contains('thiebou') || lower.contains('rice') || lower.contains('riz')) return '🥘';
    if (lower.contains('suya') || lower.contains('beef') || lower.contains('viande')) return '🥩';
    if (lower.contains('fish') || lower.contains('poisson')) return '🐟';
    if (lower.contains('salad') || lower.contains('veg')) return '🥬';
    if (lower.contains('dessert') || lower.contains('cake')) return '🍰';
    if (lower.contains('drink') || lower.contains('juice')) return '🥤';
    return '🍽️';
  }
}

/// Row from `catering_forfaits` (13 columns).
class CateringForfait {
  const CateringForfait({
    required this.id,
    required this.proId,
    required this.name,
    this.description,
    required this.pricePerPerson,
    this.inclusions = const [],
    this.minGuests,
    this.maxGuests,
    this.isPopular = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String proId;
  final String name;
  final String? description;
  final double pricePerPerson;
  final List<String> inclusions;
  final int? minGuests;
  final int? maxGuests;
  final bool isPopular;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CateringForfait.fromJson(Map<String, dynamic> json) {
    final rawInclusions = json['inclusions'];
    final inclusionsList = <String>[];
    if (rawInclusions is List) {
      for (final item in rawInclusions) {
        if (item is String) inclusionsList.add(item);
      }
    }

    return CateringForfait(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble() ?? 0,
      inclusions: inclusionsList,
      minGuests: json['min_guests'] as int?,
      maxGuests: json['max_guests'] as int?,
      isPopular: json['is_popular'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  String get guestRange {
    if (minGuests != null && maxGuests != null) {
      return '$minGuests — $maxGuests guests';
    }
    if (minGuests != null) return 'Min $minGuests guests';
    if (maxGuests != null) return 'Up to $maxGuests guests';
    return '';
  }
}

/// Row from `catering_gallery` (6 columns).
class CateringGalleryItem {
  const CateringGalleryItem({
    required this.id,
    required this.proId,
    required this.imageUrl,
    this.caption,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String proId;
  final String imageUrl;
  final String? caption;
  final int sortOrder;
  final DateTime? createdAt;

  factory CateringGalleryItem.fromJson(Map<String, dynamic> json) {
    return CateringGalleryItem(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      caption: json['caption'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

/// Helper to check if a Pro category qualifies for catering.
bool isCateringCategory(String? category) {
  if (category == null) return false;
  final lower = category.toLowerCase();
  return lower.contains('cuisine') ||
      lower.contains('traiteur') ||
      lower.contains('chef');
}
