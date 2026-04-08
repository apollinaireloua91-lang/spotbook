import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(supabase: Supabase.instance.client);
});

/// Fetches categories from the `pro_categories` table.
/// Falls back to a static list if the table is empty or unavailable.
final proCategoriesProvider =
    FutureProvider<List<ProCategory>>((ref) async {
  return ref.read(categoryRepositoryProvider).fetchCategories();
});

class ProCategory {
  const ProCategory({
    required this.label,
    required this.groupName,
    this.slug,
    this.emoji,
    this.gradientStart,
    this.gradientEnd,
    this.iconName,
  });

  final String label;
  final String groupName;
  final String? slug;
  final String? emoji;
  final String? gradientStart;
  final String? gradientEnd;
  final String? iconName;

  IconData get icon => _labelIconMap[label.toLowerCase()] ??
      _labelIconMap[slug?.toLowerCase() ?? ''] ??
      Icons.storefront_outlined;

  /// Parse gradient colors from hex strings (#RRGGBB)
  Color get startColor {
    if (gradientStart == null) return const Color(0xFF8039C5);
    return _parseHex(gradientStart!);
  }

  Color get endColor {
    if (gradientEnd == null) return const Color(0xFFA78BFA);
    return _parseHex(gradientEnd!);
  }

  static Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return const Color(0xFF8039C5);
  }

  static const _labelIconMap = <String, IconData>{
    'coiffure': Icons.content_cut,
    'barbier': Icons.face_retouching_natural,
    'esthétique': Icons.spa_outlined,
    'massage': Icons.self_improvement,
    'fitness': Icons.fitness_center,
    'photographie': Icons.camera_alt_outlined,
    'tatouage': Icons.brush_outlined,
    'maquillage': Icons.face_outlined,
    'musique / dj': Icons.headphones_outlined,
    'musique': Icons.music_note_outlined,
    'cuisine': Icons.restaurant_outlined,
    'coaching': Icons.psychology_outlined,
    'événementiel': Icons.celebration_outlined,
    'mode': Icons.checkroom_outlined,
    'beauté': Icons.face_retouching_natural,
    'photo': Icons.camera_alt_outlined,
    'design graphique': Icons.brush_outlined,
    'nail art': Icons.face_retouching_natural,
    'bien-être': Icons.spa_outlined,
    'plombier': Icons.plumbing_outlined,
    'électricien': Icons.electrical_services_outlined,
    'peintre': Icons.format_paint_outlined,
    'comptable': Icons.calculate_outlined,
    'avocat': Icons.gavel_outlined,
    'développeur': Icons.code_outlined,
    'traiteur': Icons.restaurant_outlined,
    'dj': Icons.headphones_outlined,
    'graphiste': Icons.brush_outlined,
    'vidéaste': Icons.videocam_outlined,
    'wedding planner': Icons.celebration_outlined,
    'décorateur': Icons.design_services_outlined,
    'mécanicien': Icons.build_outlined,
    'serrurier': Icons.lock_outlined,
    'jardinier': Icons.park_outlined,
    'déménageur': Icons.local_shipping_outlined,
    'nettoyage': Icons.cleaning_services_outlined,
    'tuteur': Icons.school_outlined,
    'traducteur': Icons.translate_outlined,
    'nutritionniste': Icons.restaurant_menu_outlined,
    'ostéopathe': Icons.healing_outlined,
    'kinésithérapeute': Icons.accessibility_new_outlined,
    'psychologue': Icons.psychology_outlined,
    'dentiste': Icons.medical_services_outlined,
    'vétérinaire': Icons.pets_outlined,
    'architecte': Icons.architecture_outlined,
    'agent immobilier': Icons.home_outlined,
  };
}

/// Converts a list of ProCategory into a flat list suitable for filter pills.
/// Prepends an "All" entry at index 0.
List<({String key, String label, String emoji})> toFilterPills(List<ProCategory> cats) {
  return [
    (key: 'all', label: 'All', emoji: ''),
    ...cats.map((c) => (
          key: c.label,
          label: c.label,
          emoji: c.emoji ?? '',
        )),
  ];
}

class CategoryRepository {
  CategoryRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  static const _fallback = [
    ProCategory(label: 'Coiffure', groupName: 'Beauté & Soins'),
    ProCategory(label: 'Barbier', groupName: 'Beauté & Soins'),
    ProCategory(label: 'Esthétique', groupName: 'Beauté & Soins'),
    ProCategory(label: 'Massage', groupName: 'Bien-être'),
    ProCategory(label: 'Fitness', groupName: 'Bien-être'),
    ProCategory(label: 'Photographie', groupName: 'Créatif'),
    ProCategory(label: 'Tatouage', groupName: 'Créatif'),
    ProCategory(label: 'Maquillage', groupName: 'Beauté & Soins'),
    ProCategory(label: 'Musique / DJ', groupName: 'Créatif'),
    ProCategory(label: 'Cuisine', groupName: 'Restauration'),
    ProCategory(label: 'Coaching', groupName: 'Bien-être'),
    ProCategory(label: 'Événementiel', groupName: 'Services'),
  ];

  Future<List<ProCategory>> fetchCategories() async {
    try {
      final data = await _supabase
          .from('pro_categories')
          .select('slug, name_fr, emoji, group_name, gradient_start, gradient_end')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (data.isEmpty) return _fallback;

      return data
          .map((row) => ProCategory(
                label: row['name_fr'] as String? ?? '',
                groupName: row['group_name'] as String? ?? '',
                slug: row['slug'] as String?,
                emoji: row['emoji'] as String?,
                gradientStart: row['gradient_start'] as String?,
                gradientEnd: row['gradient_end'] as String?,
              ))
          .where((c) => c.label.isNotEmpty)
          .toList();
    } catch (_) {
      return _fallback;
    }
  }
}
