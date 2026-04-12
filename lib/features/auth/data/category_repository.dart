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
    // Beauté
    'coiffure': Icons.content_cut,
    'barbier': Icons.face_retouching_natural,
    'esthétique': Icons.spa_outlined,
    'esthetique / soins visage': Icons.spa_outlined,
    'massage': Icons.self_improvement,
    'massage therapeutique': Icons.self_improvement,
    'maquillage': Icons.face_outlined,
    'nail art': Icons.face_retouching_natural,
    'nail art / manucure': Icons.face_retouching_natural,
    'extensions de cils': Icons.visibility_outlined,
    'epilation': Icons.content_cut,
    'tatouage': Icons.brush_outlined,
    'piercing': Icons.star_outlined,
    'soins capillaires / tresses': Icons.face_retouching_natural,
    'beauté': Icons.face_retouching_natural,
    'bien-être': Icons.spa_outlined,

    // Santé
    'fitness': Icons.fitness_center,
    'coach sportif': Icons.fitness_center,
    'yoga / meditation': Icons.self_improvement,
    'nutritionniste': Icons.restaurant_menu_outlined,
    'physiotherapeute': Icons.accessibility_new_outlined,
    'osteopathe': Icons.healing_outlined,
    'ostéopathe': Icons.healing_outlined,
    'psychologue': Icons.psychology_outlined,
    'psychologue / therapeute': Icons.psychology_outlined,
    'naturopathe': Icons.eco_outlined,
    'kinésithérapeute': Icons.accessibility_new_outlined,
    'dentiste': Icons.medical_services_outlined,
    'vétérinaire': Icons.pets_outlined,

    // Métiers manuels
    'plombier': Icons.plumbing_outlined,
    'électricien': Icons.electrical_services_outlined,
    'electricien': Icons.electrical_services_outlined,
    'peintre': Icons.format_paint_outlined,
    'peintre en batiment': Icons.format_paint_outlined,
    'menuisier / ebeniste': Icons.construction_outlined,
    'construction / renovation': Icons.construction_outlined,
    'carreleur / ceramique': Icons.grid_on_outlined,
    'couvreur / toiture': Icons.roofing_outlined,
    'soudeur': Icons.build_outlined,
    'maconnerie': Icons.domain_outlined,
    'chauffage / climatisation': Icons.ac_unit_outlined,
    'paysagiste / entretien terrain': Icons.park_outlined,
    'deneigement': Icons.ac_unit_outlined,
    'serrurier': Icons.lock_outlined,
    'homme a tout faire': Icons.handyman_outlined,
    'mécanicien': Icons.build_outlined,
    'mecanicien automobile': Icons.build_outlined,

    // Services pro
    'comptable': Icons.calculate_outlined,
    'comptable / cpa': Icons.calculate_outlined,
    'avocat': Icons.gavel_outlined,
    'avocat / notaire': Icons.gavel_outlined,
    'développeur': Icons.code_outlined,
    'developpeur / programmeur': Icons.code_outlined,
    'graphiste': Icons.brush_outlined,
    'graphiste / designer': Icons.brush_outlined,
    'design graphique': Icons.brush_outlined,
    'marketing / reseaux sociaux': Icons.campaign_outlined,
    'photographe': Icons.camera_alt_outlined,
    'photographie': Icons.camera_alt_outlined,
    'photo': Icons.camera_alt_outlined,
    'vidéaste': Icons.videocam_outlined,
    'videaste / monteur video': Icons.videocam_outlined,
    'traducteur': Icons.translate_outlined,
    'traducteur / interprete': Icons.translate_outlined,
    'consultant / coach business': Icons.business_center_outlined,
    'agent immobilier': Icons.home_outlined,
    'agent immobilier / courtier': Icons.home_outlined,
    'redacteur / copywriter': Icons.edit_outlined,
    'architecte': Icons.architecture_outlined,
    'architecte / design interieur': Icons.architecture_outlined,

    // Alimentation
    'cuisine': Icons.restaurant_outlined,
    'traiteur': Icons.restaurant_outlined,
    'traiteur / chef prive': Icons.restaurant_outlined,
    'patissier / gateaux sur mesure': Icons.cake_outlined,
    'boulanger artisanal': Icons.bakery_dining_outlined,
    'meal prep / repas sante': Icons.lunch_dining_outlined,
    'bartender / mixologue': Icons.local_bar_outlined,

    // Événementiel
    'événementiel': Icons.celebration_outlined,
    'dj / musique': Icons.headphones_outlined,
    'dj': Icons.headphones_outlined,
    'musique / dj': Icons.headphones_outlined,
    'musique': Icons.music_note_outlined,
    'animateur / mc': Icons.mic_outlined,
    'decorateur evenementiel': Icons.design_services_outlined,
    'décorateur': Icons.design_services_outlined,
    'planificateur evenements': Icons.event_outlined,
    'wedding planner': Icons.celebration_outlined,
    'fleuriste': Icons.local_florist_outlined,
    'musicien / groupe live': Icons.music_note_outlined,
    'location equipement (son, lumiere)': Icons.speaker_outlined,

    // Éducation
    'tuteur': Icons.school_outlined,
    'tuteur / professeur prive': Icons.school_outlined,
    'professeur de musique': Icons.music_note_outlined,
    'professeur de langues': Icons.translate_outlined,
    'moniteur auto-ecole': Icons.directions_car_outlined,
    'formateur professionnel': Icons.school_outlined,

    // Services à domicile
    'menage / entretien menager': Icons.cleaning_services_outlined,
    'nettoyage': Icons.cleaning_services_outlined,
    'demenagement': Icons.local_shipping_outlined,
    'déménageur': Icons.local_shipping_outlined,
    'garde enfants / nanny': Icons.child_care_outlined,
    'garde animaux / dog walker': Icons.pets_outlined,
    'lavage auto / detailing': Icons.local_car_wash_outlined,
    'livraison / coursier': Icons.delivery_dining_outlined,
    'home organizer / rangement': Icons.home_outlined,

    // Automobile
    'debosselage / carrosserie': Icons.car_repair_outlined,
    'remorquage / depannage': Icons.local_shipping_outlined,

    // Tech
    'reparation telephone': Icons.phone_android_outlined,
    'reparation ordinateur': Icons.computer_outlined,
    'installation tv / home cinema': Icons.tv_outlined,
    'camera de securite / domotique': Icons.videocam_outlined,

    // Mode
    'mode': Icons.checkroom_outlined,
    'couturier / retouches': Icons.checkroom_outlined,
    'styliste / personal shopper': Icons.checkroom_outlined,
    'bijoutier artisanal': Icons.star_outlined,

    // Coaching & Other
    'coaching': Icons.psychology_outlined,
    'autre service': Icons.storefront_outlined,

    // Legacy fallback labels
    'jardinier': Icons.park_outlined,
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
    ProCategory(label: 'Coiffure', groupName: 'Beauté & Soins', emoji: '✂️', slug: 'coiffure'),
    ProCategory(label: 'Barbier', groupName: 'Beauté & Soins', emoji: '💈', slug: 'barbier'),
    ProCategory(label: 'Esthétique', groupName: 'Beauté & Soins', emoji: '✨', slug: 'esthetique'),
    ProCategory(label: 'Massage', groupName: 'Bien-être', emoji: '💆', slug: 'massage'),
    ProCategory(label: 'Fitness', groupName: 'Bien-être', emoji: '🏋️', slug: 'fitness'),
    ProCategory(label: 'Photographie', groupName: 'Créatif', emoji: '📸', slug: 'photographe'),
    ProCategory(label: 'Tatouage', groupName: 'Créatif', emoji: '🎨', slug: 'tatouage'),
    ProCategory(label: 'Maquillage', groupName: 'Beauté & Soins', emoji: '💄', slug: 'maquillage'),
    ProCategory(label: 'Musique / DJ', groupName: 'Créatif', emoji: '🎧', slug: 'dj'),
    ProCategory(label: 'Cuisine', groupName: 'Restauration', emoji: '🍽️', slug: 'traiteur'),
    ProCategory(label: 'Coaching', groupName: 'Bien-être', emoji: '🧠', slug: 'coaching'),
    ProCategory(label: 'Événementiel', groupName: 'Services', emoji: '🎊', slug: 'evenementiel'),
    ProCategory(label: 'Plombier', groupName: 'Métiers manuels', emoji: '🔧', slug: 'plombier'),
    ProCategory(label: 'Électricien', groupName: 'Métiers manuels', emoji: '⚡', slug: 'electricien'),
    ProCategory(label: 'Comptable', groupName: 'Services pro', emoji: '📊', slug: 'comptable'),
    ProCategory(label: 'Avocat', groupName: 'Services pro', emoji: '⚖️', slug: 'avocat'),
    ProCategory(label: 'Développeur', groupName: 'Services pro', emoji: '💻', slug: 'developpeur'),
    ProCategory(label: 'Graphiste', groupName: 'Services pro', emoji: '🎨', slug: 'graphiste'),
    ProCategory(label: 'Nail Art', groupName: 'Beauté & Soins', emoji: '💅', slug: 'nail-art'),
    ProCategory(label: 'Mécanicien', groupName: 'Automobile', emoji: '🔧', slug: 'mecanicien'),
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
