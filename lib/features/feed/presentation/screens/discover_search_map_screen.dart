import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/discover_notifier.dart';
import '../../data/discover_search_repository.dart';
import '../../domain/provider_search_result.dart';

const _kMapCategories = [
  'All', 'Coiffure', 'Beauté', 'Fitness', 'Photo',
  'Musique', 'Cuisine', 'Massage', 'Tatouage', 'Mode', 'Coaching',
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

  static const CameraPosition _fallback = CameraPosition(
    target: LatLng(45.5017, -73.5673),
    zoom: 12,
  );

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

  // ── Custom marker icons ──────────────────────────────────────────────

  void _buildMarkersAsync(List<ProviderSearchResult> providers) {
    for (final p in providers.where((p) => p.hasCoordinates)) {
      if (_markerIcons.containsKey(p.id)) continue;
      _makeMarkerIcon(p.displayName, isOnline: p.isOnline ?? false)
          .then((icon) {
        if (mounted) setState(() => _markerIcons[p.id] = icon);
      });
    }
  }

  Future<BitmapDescriptor> _makeMarkerIcon(
    String name, {
    bool isOnline = false,
  }) async {
    const int px = 80;
    const double half = px / 2;
    const double r = half - 4;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Background fill
    canvas.drawCircle(
      const ui.Offset(half, half),
      r,
      ui.Paint()
        ..color = isOnline
            ? const ui.Color(0xFF00C851)
            : const ui.Color(0xFF1A1A1A),
    );

    // White border
    canvas.drawCircle(
      const ui.Offset(half, half),
      r,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Initials text
    final initials = _initials(name);
    final paraBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
        fontWeight: ui.FontWeight.bold,
        fontSize: px * 0.28,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
      ..addText(initials);
    final para = paraBuilder.build();
    para.layout(ui.ParagraphConstraints(width: px.toDouble()));
    canvas.drawParagraph(para, ui.Offset(0, (px - para.height) / 2));

    final img = await recorder.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  // ── Camera ──────────────────────────────────────────────────────────

  Future<void> _fitCamera(List<ProviderSearchResult> providers) async {
    final ctrl = _controller;
    if (ctrl == null) return;

    final coords = await ref
        .read(discoverSearchRepositoryProvider)
        .getCurrentUserCoordinates();
    final mapped = providers.where((p) => p.hasCoordinates).toList();

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
        CameraUpdate.newLatLngZoom(
          LatLng(mapped.first.latitude!, mapped.first.longitude!),
          13,
        ),
      );
      return;
    }

    var minLat = mapped.first.latitude!;
    var maxLat = mapped.first.latitude!;
    var minLng = mapped.first.longitude!;
    var maxLng = mapped.first.longitude!;
    for (final p in mapped) {
      minLat = math.min(minLat, p.latitude!);
      maxLat = math.max(maxLat, p.latitude!);
      minLng = math.min(minLng, p.longitude!);
      maxLng = math.max(maxLng, p.longitude!);
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
    final s = ref.watch(discoverProvider);
    final n = ref.read(discoverProvider.notifier);

    // Rebuild custom marker icons when provider list changes.
    if (!identical(_lastProviders, s.nearbyProviders)) {
      _lastProviders = s.nearbyProviders;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buildMarkersAsync(s.nearbyProviders);
      });
    }

    // Re-fit camera when providers are refreshed.
    ref.listen(discoverProvider, (prev, next) {
      if (!identical(prev?.nearbyProviders, next.nearbyProviders) &&
          _controller != null) {
        _fitCamera(next.nearbyProviders);
      }
    });

    final withCoords =
        s.nearbyProviders.where((p) => p.hasCoordinates).toList();

    final markers = <Marker>{
      for (final p in withCoords)
        Marker(
          markerId: MarkerId(p.id),
          position: LatLng(p.latitude!, p.longitude!),
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
            style: _kDarkMapStyle,
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
                        tooltip: 'Liste',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('$basePath/results');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _kMapCategories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _kMapCategories[i];
                      final selected = s.selectedCategory == cat;
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
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.fond
                                  : AppColors.blanc,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Loading indicator ──
          if (s.isLoading)
            const Positioned(
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

          // ── No GPS warning ──
          if (!s.isLoading &&
              withCoords.isEmpty &&
              s.nearbyProviders.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 120,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Les pros trouvés n\'ont pas de position GPS.\nUtilise la vue Liste pour les consulter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.gris, fontSize: 13, height: 1.4),
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Color(0x55000000),
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
                          style: const TextStyle(
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
                          Text(
                            pro.category!,
                            style: const TextStyle(
                                color: AppColors.gris, fontSize: 14),
                          ),
                        ],
                        if (pro.city != null &&
                            pro.city!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.gris, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                pro.distanceKm != null
                                    ? '${pro.city} • ${pro.distanceKm!.toStringAsFixed(1)} km'
                                    : pro.city!,
                                style: const TextStyle(
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
                        const Icon(Icons.star_rounded,
                            color: AppColors.blanc, size: 20),
                        Text(
                          pro.averageRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SpotbookButton.secondary(
                      label: 'Voir le profil',
                      onPressed: () =>
                          context.push('/client/provider/${pro.id}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SpotbookButton.primary(
                      label: 'Réserver',
                      onPressed: () =>
                          context.push('/client/provider/${pro.id}'),
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
