import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/service_category_icons.dart';
import '../../../auth/data/category_repository.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/discover_notifier.dart';
import '../../data/discover_search_repository.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../domain/provider_search_result.dart';

/// Fallback categories for map filter when Supabase hasn't loaded yet.
const _kMapCategoriesFallback = [
  'All', 'Coiffure', 'Barbier', 'Esthétique', 'Massage',
  'Fitness', 'Photographie', 'Musique / DJ', 'Tatouage',
  'Mode', 'Cuisine', 'Coaching',
];

const _kDarkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]''';

const _kLightMapStyle = '''[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]''';

/// Position carte : GPS réel du pro, sinon décal déterministe autour de [anchor] (ville / pas de GPS).
LatLng _proMapLatLng(ProviderSearchResult pro, LatLng anchor) {
  if (pro.latitude != null && pro.longitude != null) {
    return LatLng(pro.latitude!, pro.longitude!);
  }
  final h = pro.id.hashCode;
  final dx = ((h % 200) - 100) / 3200.0;
  final dy = (((h >> 8) % 200) - 100) / 3200.0;
  return LatLng(anchor.latitude + dx, anchor.longitude + dy);
}

/// Category → marker color (local to avoid cross-feature import).
Color _categoryColor(String? category) {
  if (category == null || category.isEmpty) return AppColors.violet;
  final key = category.toLowerCase();
  if (key.contains('barb') || key.contains('coiff')) return const Color(0xFFFF6B35);
  if (key.contains('nail') || key.contains('manu')) return const Color(0xFFE91E90);
  if (key.contains('mass')) return const Color(0xFFEC4899);
  if (key.contains('esth') || key.contains('beaut')) return AppColors.rose;
  if (key.contains('coach') || key.contains('fit')) return AppColors.success;
  if (key.contains('photo')) return AppColors.violet;
  if (key.contains('traiteur') || key.contains('cuisine')) return AppColors.catering;
  if (key.contains('tattoo') || key.contains('tatou')) return AppColors.error;
  if (key.contains('dj') || key.contains('musiq')) return const Color(0xFF8B5CF6);
  if (key.contains('mode')) return AppColors.roseClair;
  return AppColors.violet;
}

class DiscoverSearchMapScreen extends ConsumerStatefulWidget {
  const DiscoverSearchMapScreen({super.key});

  @override
  ConsumerState<DiscoverSearchMapScreen> createState() =>
      _DiscoverSearchMapScreenState();
}

class _DiscoverSearchMapScreenState
    extends ConsumerState<DiscoverSearchMapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _controller;
  bool _cameraSet = false;

  ProviderSearchResult? _selectedPro;
  late final AnimationController _cardAnim;
  late final Animation<Offset> _cardSlide;

  final Map<String, BitmapDescriptor> _markerIcons = {};
  List<ProviderSearchResult>? _lastProviders;
  LatLng _mapAnchor = const LatLng(45.5017, -73.5673);

  static const CameraPosition _fallback = CameraPosition(
    target: LatLng(45.5017, -73.5673),
    zoom: 12,
  );

  Future<LatLng> _computeMapAnchor(List<ProviderSearchResult> providers) async {
    final coords = await ref
        .read(discoverSearchRepositoryProvider)
        .getCurrentUserCoordinates();
    if (coords.lat != null && coords.lng != null) {
      return LatLng(coords.lat!, coords.lng!);
    }
    for (final p in providers) {
      if (p.latitude != null && p.longitude != null) {
        return LatLng(p.latitude!, p.longitude!);
      }
    }
    return _fallback.target;
  }

  Future<void> _refreshMapAnchor(List<ProviderSearchResult> providers) async {
    final anchor = await _computeMapAnchor(providers);
    if (mounted) setState(() => _mapAnchor = anchor);
  }

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ── Custom marker icons (category-based) ────────────────────────────

  void _buildMarkersAsync(List<ProviderSearchResult> providers) {
    for (final p in providers) {
      if (_markerIcons.containsKey(p.id)) continue;
      _makeMarkerIcon(
        category: p.category,
        displayName: p.displayName,
        isOnline: p.isOnline ?? false,
      ).then((icon) {
        if (mounted) setState(() => _markerIcons[p.id] = icon);
      });
    }
  }

  Future<BitmapDescriptor> _makeMarkerIcon({
    String? category,
    String? displayName,
    bool isOnline = false,
  }) async {
    const int px = 96;
    const double half = px / 2;
    const double r = half - 6;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final catColor = _categoryColor(category);

    // Drop shadow for depth
    canvas.drawCircle(
      const ui.Offset(half, half + 2),
      r + 1,
      ui.Paint()
        ..color = Colors.black.withAlpha(50)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
    );

    // Main circle — category color
    canvas.drawCircle(
      const ui.Offset(half, half),
      r,
      ui.Paint()..color = catColor,
    );

    // White border ring
    canvas.drawCircle(
      const ui.Offset(half, half),
      r,
      ui.Paint()
        ..color = Colors.white
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Pro initial (default system font — always available, unlike MaterialIcons)
    final letter = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : '?';
    final paraBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
        fontSize: px * 0.34,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: Colors.white,
        fontWeight: ui.FontWeight.w700,
      ))
      ..addText(letter);
    final para = paraBuilder.build();
    para.layout(ui.ParagraphConstraints(width: px.toDouble()));
    canvas.drawParagraph(para, ui.Offset(0, (px - para.height) / 2));

    // Online indicator dot
    if (isOnline) {
      canvas.drawCircle(
        ui.Offset(px * 0.76, px * 0.24),
        px * 0.1,
        ui.Paint()..color = const Color(0xFF22C55E),
      );
      canvas.drawCircle(
        ui.Offset(px * 0.76, px * 0.24),
        px * 0.1,
        ui.Paint()
          ..color = Colors.white
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final img = await recorder.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Camera ──────────────────────────────────────────────────────────

  Future<void> _fitCamera(List<ProviderSearchResult> providers) async {
    final ctrl = _controller;
    if (ctrl == null) return;

    final coords = await ref
        .read(discoverSearchRepositoryProvider)
        .getCurrentUserCoordinates();
    final anchor = await _computeMapAnchor(providers);
    if (mounted) setState(() => _mapAnchor = anchor);
    final mapped = providers.map((p) => _proMapLatLng(p, anchor)).toList();

    if (mapped.isEmpty) {
      if (coords.lat != null && coords.lng != null) {
        await ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(
              LatLng(coords.lat!, coords.lng!), 12),
        );
      }
      return;
    }

    if (mapped.length == 1) {
      await ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(mapped.first, 13),
      );
      return;
    }

    var minLat = mapped.first.latitude;
    var maxLat = mapped.first.latitude;
    var minLng = mapped.first.longitude;
    var maxLng = mapped.first.longitude;
    for (final ll in mapped) {
      minLat = math.min(minLat, ll.latitude);
      maxLat = math.max(maxLat, ll.latitude);
      minLng = math.min(minLng, ll.longitude);
      maxLng = math.max(maxLng, ll.longitude);
    }
    if (coords.lat != null && coords.lng != null) {
      minLat = math.min(minLat, coords.lat!);
      maxLat = math.max(maxLat, coords.lat!);
      minLng = math.min(minLng, coords.lng!);
      maxLng = math.max(maxLng, coords.lng!);
    }

    await ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  // ── Pro selection ────────────────────────────────────────────────────

  void _selectPro(ProviderSearchResult pro) {
    HapticFeedback.lightImpact();
    setState(() => _selectedPro = pro);
    _cardAnim.forward();
  }

  void _deselectPro() {
    _cardAnim.reverse().then((_) {
      if (mounted) setState(() => _selectedPro = null);
    });
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final s = ref.watch(discoverProvider);
    final n = ref.read(discoverProvider.notifier);

    // Rebuild custom marker icons when provider list changes.
    if (!identical(_lastProviders, s.nearbyProviders)) {
      _lastProviders = s.nearbyProviders;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshMapAnchor(s.nearbyProviders);
          _buildMarkersAsync(s.nearbyProviders);
        }
      });
    }

    // Re-fit camera when providers are refreshed.
    ref.listen(discoverProvider, (prev, next) {
      if (!identical(prev?.nearbyProviders, next.nearbyProviders) &&
          _controller != null) {
        _fitCamera(next.nearbyProviders);
      }
    });

    final anyWithoutGps =
        s.nearbyProviders.any((p) => !p.hasCoordinates);

    final markers = <Marker>{
      for (final p in s.nearbyProviders)
        Marker(
          markerId: MarkerId(p.id),
          position: _proMapLatLng(p, _mapAnchor),
          icon: _markerIcons[p.id] ?? BitmapDescriptor.defaultMarker,
          onTap: () => _selectPro(p),
        ),
    };

    final basePath =
        GoRouterState.of(context).uri.path.startsWith('/pro/search')
            ? '/pro/search'
            : '/client/discover';

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Stack(
        children: [
          // ── Google Map ──
          GoogleMap(
            initialCameraPosition: _fallback,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: markers,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            style: AppColors.isDark ? _kDarkMapStyle : _kLightMapStyle,
            onMapCreated: (c) {
              _controller = c;
              if (!_cameraSet) {
                _cameraSet = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitCamera(s.nearbyProviders);
                });
              }
            },
            onTap: (_) {
              if (_selectedPro != null) _deselectPro();
            },
          ),

          // ── Top overlay : back button + chips + list button ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      _MapCircleBtn(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.pop();
                        },
                      ),
                      const Spacer(),
                      _MapCircleBtn(
                        icon: Icons.view_list,
                        tooltip: 'List',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('$basePath/results');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (_) {
                    final asyncCats = ref.watch(proCategoriesProvider);
                    final mapCategories = asyncCats.when(
                      data: (cats) => ['All', ...cats.map((c) => c.label)],
                      loading: () => _kMapCategoriesFallback,
                      error: (_, __) => _kMapCategoriesFallback,
                    );
                    return SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mapCategories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = mapCategories[i];
                      final selected = s.selectedCategory == cat;
                      final isAll = cat == 'All';
                      return GestureDetector(
                        onTap: () => n.setCategory(cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.blanc
                                : AppColors.surface.withAlpha(230),
                            borderRadius: BorderRadius.circular(18),
                            border: selected
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAll ? Icons.apps : ServiceCategoryIcons.icon(cat),
                                size: 14,
                                color: selected
                                    ? AppColors.fond
                                    : AppColors.blanc,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cat,
                                style: GoogleFonts.dmSans(
                                  color: selected
                                      ? AppColors.fond
                                      : AppColors.blanc,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
                  },
                ),
              ],
            ),
          ),

          // ── Loading indicator ──
          if (s.isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      color: AppColors.blanc, strokeWidth: 2),
                ),
              ),
            ),

          // ── Pros sans GPS : positions approximatives sur la carte ──
          if (!s.isLoading && anyWithoutGps && s.nearbyProviders.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 120,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Some pros don\'t have GPS: their pin is placed approximately near your area (or Montreal). The list shows the actual city.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: AppColors.gris, fontSize: 12, height: 1.35),
                  ),
                ),
              ),
            ),

          // ── Animated pro card ──
          if (_selectedPro != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _cardSlide,
                child: _ProBottomCard(
                  pro: _selectedPro!,
                  onClose: _deselectPro,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.small(
          backgroundColor: AppColors.blanc,
          foregroundColor: AppColors.fond,
          heroTag: 'map_location',
          onPressed: () => _fitCamera(s.nearbyProviders),
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Map circle button
// ─────────────────────────────────────────────
class _MapCircleBtn extends StatelessWidget {
  const _MapCircleBtn({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.blanc, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pro bottom card
// ─────────────────────────────────────────────
class _ProBottomCard extends StatelessWidget {
  const _ProBottomCard({required this.pro, required this.onClose});

  final ProviderSearchResult pro;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
          onClose();
        } else if (d.primaryVelocity != null &&
            d.primaryVelocity! < -200) {
          context.push('/client/provider/${pro.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayLight,
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Avatar + name + meta
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpotbookAvatar(
                    imageUrl: pro.avatarUrl,
                    name: pro.displayName,
                    radius: 30,
                    isOnline: pro.isOnline ?? false,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pro.displayName,
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (pro.category != null &&
                            pro.category!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                ServiceCategoryIcons.icon(pro.category),
                                color: AppColors.gris,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pro.category!,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.gris, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        if (pro.city != null &&
                            pro.city!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  color: AppColors.gris, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                pro.distanceKm != null
                                    ? '${pro.city} • ${pro.distanceKm!.toStringAsFixed(1)} km'
                                    : pro.city!,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.gris,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (pro.averageRating != null &&
                      pro.averageRating! > 0)
                    Column(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.blanc, size: 20),
                        Text(
                          pro.averageRating!.toStringAsFixed(1),
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Description
              if (pro.description != null &&
                  pro.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  pro.description!.trim(),
                  style: GoogleFonts.dmSans(
                    color: AppColors.grisClair,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SpotbookButton.secondary(
                      label: 'View profile',
                      onPressed: () =>
                          context.push('/client/provider/${pro.id}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SpotbookButton.primary(
                      label: 'Book',
                      onPressed: () =>
                          context.push('/client/booking-flow/${pro.id}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
