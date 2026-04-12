import 'package:flutter/material.dart';

/// Maps service categories to Material icons.
///
/// Used in discover chips, map markers, and pro cards.
abstract final class ServiceCategoryIcons {
  static const Map<String, IconData> _map = {
    'coiffure': Icons.content_cut,
    'beauté': Icons.face_retouching_natural,
    'fitness': Icons.fitness_center,
    'photo': Icons.camera_alt_outlined,
    'musique': Icons.music_note_outlined,
    'cuisine': Icons.restaurant_outlined,
    'massage': Icons.spa_outlined,
    'tatouage': Icons.brush_outlined,
    'mode': Icons.checkroom_outlined,
    'coaching': Icons.psychology_outlined,
  };

  /// Returns the icon for the given [category], case-insensitive.
  /// Falls back to [Icons.storefront_outlined] for unknown categories.
  static IconData icon(String? category) {
    if (category == null || category.isEmpty) return Icons.storefront_outlined;
    return _map[category.toLowerCase()] ?? Icons.storefront_outlined;
  }

  /// All supported categories with their icons (for UI display).
  static const List<({String name, IconData icon})> all = [
    (name: 'Coiffure', icon: Icons.content_cut),
    (name: 'Beauté', icon: Icons.face_retouching_natural),
    (name: 'Fitness', icon: Icons.fitness_center),
    (name: 'Photo', icon: Icons.camera_alt_outlined),
    (name: 'Musique', icon: Icons.music_note_outlined),
    (name: 'Cuisine', icon: Icons.restaurant_outlined),
    (name: 'Massage', icon: Icons.spa_outlined),
    (name: 'Tatouage', icon: Icons.brush_outlined),
    (name: 'Mode', icon: Icons.checkroom_outlined),
    (name: 'Coaching', icon: Icons.psychology_outlined),
  ];
}
