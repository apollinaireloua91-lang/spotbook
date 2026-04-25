import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';

// ─── Pro Search Result ───────────────────────────────────────────────

class ProSearchResult {
  const ProSearchResult({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviews,
    required this.distKm,
    required this.priceRange,
    required this.online,
    this.avatarUrl,
    this.services = const [],
    this.hasRealCoords = false,
  });

  final String id;
  final String name;
  final String category;
  final String location;
  final double lat;
  final double lng;
  final double rating;
  final int reviews;
  final double distKm;
  final String priceRange;
  final bool online;
  final String? avatarUrl;
  final List<ProService> services;
  final bool hasRealCoords;

  ProSearchResult copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    double? lat,
    double? lng,
    double? rating,
    int? reviews,
    double? distKm,
    String? priceRange,
    bool? online,
    String? avatarUrl,
    List<ProService>? services,
    bool? hasRealCoords,
  }) {
    return ProSearchResult(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      distKm: distKm ?? this.distKm,
      priceRange: priceRange ?? this.priceRange,
      online: online ?? this.online,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      services: services ?? this.services,
      hasRealCoords: hasRealCoords ?? this.hasRealCoords,
    );
  }
}

// ─── Pro Service ─────────────────────────────────────────────────────

class ProService {
  const ProService({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    this.icon,
  });

  final String id;
  final String name;
  final String duration;
  final double price;
  final IconData? icon;
}

// ─── Event Search Result ─────────────────────────────────────────────

class EventSearchResult {
  const EventSearchResult({
    required this.id,
    required this.title,
    required this.location,
    required this.lat,
    required this.lng,
    required this.date,
    required this.time,
    required this.totalSpots,
    required this.soldSpots,
    required this.price,
    this.imageUrl,
    this.proName,
  });

  final String id;
  final String title;
  final String location;
  final double lat;
  final double lng;
  final DateTime date;
  final String time;
  final int totalSpots;
  final int soldSpots;
  final double price;
  final String? imageUrl;
  final String? proName;

  int get spotsLeft => totalSpots - soldSpots;
}

// ─── Category Helpers ────────────────────────────────────────────────

class SearchCategory {
  const SearchCategory(this.key, this.label, this.emoji);

  final String key;
  final String label;
  final String emoji;
}

/// Fallback categories used when Supabase fetch hasn't completed yet.
/// Real categories come from `proCategoriesProvider` → `toSearchCategories()`.
const kSearchCategoriesFallback = <SearchCategory>[
  SearchCategory('all', 'All', ''),
  SearchCategory('Coiffure', 'Hair', '\u2702\uFE0F'),
  SearchCategory('Barbier', 'Barber', '\uD83D\uDC88'),
  SearchCategory('Esthétique', 'Beauty', '\uD83D\uDC86'),
  SearchCategory('Massage', 'Massage', '\uD83E\uDDD6'),
  SearchCategory('Fitness', 'Fitness', '\uD83C\uDFCB\uFE0F'),
  SearchCategory('Photographie', 'Photo', '\uD83D\uDCF8'),
  SearchCategory('Tatouage', 'Tattoo', '\uD83C\uDFA8'),
  SearchCategory('Maquillage', 'Makeup', '\uD83D\uDC84'),
  SearchCategory('Musique / DJ', 'DJ', '\uD83C\uDFA7'),
  SearchCategory('Cuisine', 'Catering', '\uD83C\uDF7D\uFE0F'),
  SearchCategory('Coaching', 'Coaching', '\uD83E\uDDD1\u200D\uD83C\uDFEB'),
];

Color categoryColor(String category) {
  final key = category.toLowerCase();
  if (key.contains('barb') || key.contains('coiff')) return const Color(0xFFFF6B35);
  if (key.contains('nail') || key.contains('manu')) return const Color(0xFFE91E90);
  if (key.contains('mass')) return const Color(0xFFEC4899);
  if (key.contains('esth') || key.contains('beauté') || key.contains('bien')) return AppColors.rose;
  if (key.contains('coach') || key.contains('fit')) return AppColors.success;
  if (key.contains('photo') || key.contains('vidéa')) return AppColors.violet;
  if (key.contains('traiteur') || key.contains('cuisine') || key.contains('chef')) return AppColors.catering;
  if (key.contains('tattoo') || key.contains('tatou')) return AppColors.error;
  if (key.contains('dj') || key.contains('musiq')) return const Color(0xFF8B5CF6);
  if (key.contains('plomb')) return const Color(0xFF3B82F6);
  if (key.contains('electr')) return const Color(0xFFEAB308);
  if (key.contains('mode') || key.contains('design')) return AppColors.roseClair;
  if (key.contains('évén') || key.contains('wedding')) return AppColors.rose;
  return AppColors.gris;
}

String categoryEmoji(String category) {
  for (final c in kSearchCategoriesFallback) {
    if (c.key == category) return c.emoji;
  }
  return '';
}

/// Emoji for circular map markers (Apple Maps / Waze style).
String categoryMarkerEmoji(String category) {
  final key = category.toLowerCase();
  if (key.contains('barb') || key.contains('coiff')) return '\u2702\uFE0F';
  if (key.contains('nail') || key.contains('maquill')) return '\uD83D\uDC85';
  if (key.contains('massage') || key.contains('bien')) return '\uD83D\uDC86';
  if (key.contains('esth') || key.contains('beaut')) return '\u2728';
  if (key.contains('coach') || key.contains('fitness')) return '\uD83C\uDFCB\uFE0F';
  if (key.contains('photo') || key.contains('vid')) return '\uD83D\uDCF8';
  if (key.contains('traiteur') || key.contains('cuisine')) return '\uD83C\uDF7D\uFE0F';
  if (key.contains('tattoo') || key.contains('tatou')) return '\uD83C\uDFA8';
  if (key.contains('dj') || key.contains('musiq')) return '\uD83C\uDFA7';
  if (key.contains('mode') || key.contains('design')) return '\uD83D\uDC57';
  if (key.contains('\u00e9v\u00e9n') || key.contains('wedding')) return '\uD83C\uDF89';
  return '\uD83D\uDCCC';
}

/// Material icon for marker generation via Canvas + PictureRecorder.
IconData categoryIcon(String category) {
  final key = category.toLowerCase();
  if (key.contains('coiff')) return Icons.content_cut;
  if (key.contains('barb')) return Icons.face_retouching_natural;
  if (key.contains('fitness')) return Icons.fitness_center;
  if (key.contains('photo')) return Icons.camera_alt_outlined;
  if (key.contains('tatou') || key.contains('tattoo')) return Icons.brush_outlined;
  if (key.contains('esth') || key.contains('beauté')) return Icons.spa_outlined;
  if (key.contains('traiteur') || key.contains('cuisine')) return Icons.restaurant_outlined;
  if (key.contains('dj') || key.contains('musiq')) return Icons.music_note_outlined;
  if (key.contains('massage') || key.contains('bien')) return Icons.self_improvement;
  if (key.contains('maquill')) return Icons.face_outlined;
  if (key.contains('coach')) return Icons.psychology_outlined;
  if (key.contains('nail')) return Icons.face_retouching_natural;
  if (key.contains('mode')) return Icons.checkroom_outlined;
  return Icons.storefront_outlined;
}

// Mock data removed — all data comes from Supabase via ClientSearchNotifier.
// Kept as comment for reference during development.

/*
final mockPros = <ProSearchResult>[
  ProSearchResult(
    id: '1',
    name: 'Kevin Barber',
    category: 'barbier',
    location: 'Mile-End',
    lat: 45.5245,
    lng: -73.5985,
    rating: 4.9,
    reviews: 127,
    distKm: 0.8,
    priceRange: '35-55',
    online: true,
    services: const [
      ProService(id: 's1', name: 'Coupe classique', duration: '30 min', price: 35),
      ProService(id: 's2', name: 'Coupe + Barbe', duration: '45 min', price: 50),
      ProService(id: 's3', name: 'Fade Premium', duration: '40 min', price: 55),
    ],
  ),
  ProSearchResult(
    id: '2',
    name: 'Fade Masters',
    category: 'barbier',
    location: 'Villeray',
    lat: 45.5450,
    lng: -73.6150,
    rating: 4.7,
    reviews: 89,
    distKm: 2.3,
    priceRange: '30-50',
    online: false,
    services: const [
      ProService(id: 's4', name: 'Fade Express', duration: '25 min', price: 30),
      ProService(id: 's5', name: 'Coupe Compl\u00e8te', duration: '40 min', price: 45),
    ],
  ),
  ProSearchResult(
    id: '3',
    name: 'Studio Nails MTL',
    category: 'nails',
    location: 'Plateau',
    lat: 45.5225,
    lng: -73.5770,
    rating: 4.8,
    reviews: 156,
    distKm: 1.2,
    priceRange: '45-95',
    online: true,
    services: const [
      ProService(id: 's6', name: 'Manucure Gel', duration: '45 min', price: 45),
      ProService(id: 's7', name: 'Nail Art Complet', duration: '1h15', price: 95),
    ],
  ),
  ProSearchResult(
    id: '4',
    name: 'Nails by Sonia',
    category: 'nails',
    location: 'Hochelaga',
    lat: 45.5370,
    lng: -73.5460,
    rating: 4.6,
    reviews: 72,
    distKm: 3.1,
    priceRange: '40-80',
    online: true,
    services: const [
      ProService(id: 's8', name: 'Pose Compl\u00e8te', duration: '1h', price: 65),
    ],
  ),
  ProSearchResult(
    id: '5',
    name: 'Coach Elias',
    category: 'coach',
    location: 'Verdun',
    lat: 45.4580,
    lng: -73.5670,
    rating: 4.7,
    reviews: 64,
    distKm: 2.1,
    priceRange: '60-90',
    online: false,
    services: const [
      ProService(id: 's9', name: 'Session 1h', duration: '1h', price: 60),
      ProService(id: 's10', name: 'Programme 4 sem.', duration: '4 sem.', price: 240),
    ],
  ),
  ProSearchResult(
    id: '6',
    name: 'FitPro Karine',
    category: 'coach',
    location: 'Griffintown',
    lat: 45.4900,
    lng: -73.5620,
    rating: 4.9,
    reviews: 98,
    distKm: 1.5,
    priceRange: '70-100',
    online: true,
    services: const [
      ProService(id: 's11', name: 'Coaching Priv\u00e9', duration: '1h', price: 70),
      ProService(id: 's12', name: 'Plan Nutrition', duration: '1h30', price: 100),
    ],
  ),
  const ProSearchResult(
    id: '7',
    name: 'Ayla Photo',
    category: 'photo',
    location: 'Rosemont',
    lat: 45.5400,
    lng: -73.5870,
    rating: 5.0,
    reviews: 42,
    distKm: 3.0,
    priceRange: '150-400',
    online: false,
    services: [
      ProService(id: 's13', name: 'Portrait Studio', duration: '1h', price: 150),
      ProService(id: 's14', name: 'Shooting Ext\u00e9rieur', duration: '2h', price: 300),
    ],
  ),
  const ProSearchResult(
    id: '8',
    name: 'Lens Studio',
    category: 'photo',
    location: 'Vieux-Port',
    lat: 45.5035,
    lng: -73.5540,
    rating: 4.8,
    reviews: 56,
    distKm: 1.8,
    priceRange: '200-500',
    online: true,
    services: [
      ProService(id: 's15', name: 'Book Photo', duration: '2h', price: 250),
    ],
  ),
  const ProSearchResult(
    id: '9',
    name: 'Ink MTL',
    category: 'tattoo',
    location: 'St-Henri',
    lat: 45.4770,
    lng: -73.5880,
    rating: 4.9,
    reviews: 201,
    distKm: 2.5,
    priceRange: '80-300',
    online: true,
    services: [
      ProService(id: 's16', name: 'Petit Tattoo', duration: '1h', price: 80),
      ProService(id: 's17', name: 'Pi\u00e8ce Moyenne', duration: '3h', price: 250),
    ],
  ),
  const ProSearchResult(
    id: '10',
    name: 'Tattoo Lab',
    category: 'tattoo',
    location: 'Mile-End',
    lat: 45.5280,
    lng: -73.6010,
    rating: 4.6,
    reviews: 88,
    distKm: 1.0,
    priceRange: '100-350',
    online: false,
    services: [
      ProService(id: 's18', name: 'Consultation', duration: '30 min', price: 0),
      ProService(id: 's19', name: 'Session Custom', duration: '2h', price: 200),
    ],
  ),
  const ProSearchResult(
    id: '11',
    name: 'Francis Esth\u00e9tique',
    category: 'esth',
    location: 'Longueuil',
    lat: 45.5310,
    lng: -73.5180,
    rating: 4.8,
    reviews: 94,
    distKm: 4.2,
    priceRange: '65-120',
    online: true,
    services: [
      ProService(id: 's20', name: 'Soin Visage', duration: '1h', price: 65),
      ProService(id: 's21', name: 'Soin Complet', duration: '1h30', price: 120),
    ],
  ),
  const ProSearchResult(
    id: '12',
    name: 'Chef Aminata',
    category: 'traiteur',
    location: 'MTL-Nord',
    lat: 45.5800,
    lng: -73.6400,
    rating: 4.9,
    reviews: 73,
    distKm: 3.5,
    priceRange: '25-45/pers',
    online: true,
    services: [
      ProService(id: 's22', name: 'Menu D\u00e9couverte', duration: '10 pers', price: 25),
      ProService(id: 's23', name: 'Buffet Premium', duration: '20 pers', price: 45),
    ],
  ),
];

// ─── Mock Events ─────────────────────────────────────────────────────

final mockEvents = <EventSearchResult>[
  EventSearchResult(
    id: 'e1',
    title: 'BARBER BATTLE MTL',
    location: 'Th\u00e9\u00e2tre Fairmount',
    lat: 45.5260,
    lng: -73.5950,
    date: DateTime(2026, 4, 12),
    time: '19h00',
    totalSpots: 200,
    soldSpots: 156,
    price: 25,
    proName: 'Kevin Barber',
  ),
  EventSearchResult(
    id: 'e2',
    title: 'NAIL ART FESTIVAL',
    location: 'Centre PHI',
    lat: 45.5030,
    lng: -73.5550,
    date: DateTime(2026, 4, 18),
    time: '14h00',
    totalSpots: 150,
    soldSpots: 89,
    price: 35,
    proName: 'Studio Nails MTL',
  ),
  EventSearchResult(
    id: 'e3',
    title: 'FITNESS BOOTCAMP',
    location: 'Parc La Fontaine',
    lat: 45.5250,
    lng: -73.5680,
    date: DateTime(2026, 4, 20),
    time: '08h00',
    totalSpots: 50,
    soldSpots: 42,
    price: 15,
    proName: 'FitPro Karine',
  ),
  EventSearchResult(
    id: 'e4',
    title: 'FOOD & SOUL BRUNCH',
    location: 'Espace Abiyo',
    lat: 45.5420,
    lng: -73.6100,
    date: DateTime(2026, 4, 25),
    time: '11h00',
    totalSpots: 80,
    soldSpots: 64,
    price: 45,
    proName: 'Chef Aminata',
  ),
];
*/
