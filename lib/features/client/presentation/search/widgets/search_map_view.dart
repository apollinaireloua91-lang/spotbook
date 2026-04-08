import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../cubit/client_search_cubit.dart';
import '../models/search_models.dart';
import 'pro_map_card.dart';

// ─── Dark map style (Aubergine / Spotbook aligned) ───────────────────

const _kDarkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6a6a8a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2a2a3a"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#505070"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#32324a"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d0d14"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3a3a5a"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#16161f"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#2a2a3a"}]},
  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#16161f"}]}
]''';

/// Max markers visible on map for performance.
const _kMaxMarkers = 20;

class SearchMapView extends StatefulWidget {
  const SearchMapView({super.key});

  @override
  State<SearchMapView> createState() => _SearchMapViewState();
}

class _SearchMapViewState extends State<SearchMapView> {
  GoogleMapController? _mapController;
  final _cardScrollController = ScrollController();
  bool _cameraFitted = false;

  /// Cached BitmapDescriptor per category name.
  final Map<String, BitmapDescriptor> _markerIcons = {};

  /// User location marker icon.
  BitmapDescriptor? _userMarkerIcon;

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _buildUserMarkerIcon();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _cardScrollController.dispose();
    super.dispose();
  }

  // ── Tiny dot marker (Uber style) ───────────────────────────────────

  Future<BitmapDescriptor> _createSmallDotMarker(Color color) async {
    const double size = 36.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White outer ring
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = Colors.white,
    );

    // Colored inner dot
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()..color = color,
    );

    // Tiny white center highlight for depth
    canvas.drawCircle(
      const Offset(size / 2, size / 2 - 2),
      4,
      Paint()..color = Colors.white.withAlpha(77),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── User location — tiny blue dot ──────────────────────────────────

  Future<void> _buildUserMarkerIcon() async {
    const double size = 28.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Blue glow ring
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = AppColors.locationBlue.withAlpha(51),
    );

    // White ring
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      8,
      Paint()..color = AppColors.blanc,
    );

    // Blue center
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      6,
      Paint()..color = AppColors.locationBlue,
    );

    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (mounted) {
      setState(() {
        _userMarkerIcon = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
      });
    }
  }

  // ── Build marker icons (cached by category) ────────────────────────

  void _buildProMarkerIcons(List<ProSearchResult> pros) {
    final categories = pros.take(_kMaxMarkers).map((p) => p.category).toSet();
    for (final cat in categories) {
      if (_markerIcons.containsKey(cat)) continue;
      _createSmallDotMarker(categoryColor(cat)).then((icon) {
        if (mounted) setState(() => _markerIcons[cat] = icon);
      });
    }
  }

  // ── Camera ──

  void _fitCameraToPros(
      List<ProSearchResult> pros, double? uLat, double? uLng) {
    final ctrl = _mapController;
    if (ctrl == null || pros.isEmpty) return;

    if (pros.length == 1) {
      ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pros.first.lat, pros.first.lng),
          14,
        ),
      );
      return;
    }

    var minLat = pros.first.lat;
    var maxLat = pros.first.lat;
    var minLng = pros.first.lng;
    var maxLng = pros.first.lng;
    for (final p in pros.take(_kMaxMarkers)) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    if (uLat != null && uLng != null) {
      minLat = math.min(minLat, uLat);
      maxLat = math.max(maxLat, uLat);
      minLng = math.min(minLng, uLng);
      maxLng = math.max(maxLng, uLng);
    }

    ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientSearchCubit, ClientSearchState>(
      builder: (context, state) {
        // Build marker icons async (cached by category)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _buildProMarkerIcons(state.pros);
        });

        // Assemble Google Maps markers
        final markers = <Marker>{};

        // User location — premium blue dot
        if (state.userLat != null &&
            state.userLng != null &&
            _userMarkerIcon != null) {
          markers.add(Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(state.userLat!, state.userLng!),
            icon: _userMarkerIcon!,
            zIndexInt: 999,
            anchor: const Offset(0.5, 0.5),
          ));
        }

        // Pro markers — tiny colored dots
        for (final pro in state.pros.take(_kMaxMarkers)) {
          markers.add(Marker(
            markerId: MarkerId(pro.id),
            position: LatLng(pro.lat, pro.lng),
            icon: _markerIcons[pro.category] ?? BitmapDescriptor.defaultMarker,
            zIndexInt: 1,
            anchor: const Offset(0.5, 0.5),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/pro/${pro.id}');
            },
          ));
        }

        final initialTarget = LatLng(
          state.userLat ?? 45.5100,
          state.userLng ?? -73.5700,
        );

        return Stack(
          children: [
            // ── Google Map ──
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 12,
              ),
              markers: markers,
              style: _kDarkMapStyle,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                if (!_cameraFitted && state.pros.isNotEmpty) {
                  _cameraFitted = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fitCameraToPros(
                      state.pros,
                      state.userLat,
                      state.userLng,
                    );
                  });
                }
              },
            ),

            // ── My location FAB ──
            Positioned(
              right: 14,
              bottom: 160,
              child: GestureDetector(
                onTap: () {
                  if (state.userLat != null && state.userLng != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(state.userLat!, state.userLng!),
                        14,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: AppColors.blanc,
                    size: 18,
                  ),
                ),
              ),
            ),

            // ── Bottom card carousel ──
            if (state.pros.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: SizedBox(
                  height: 130,
                  child: ListView.separated(
                    controller: _cardScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: state.pros.take(_kMaxMarkers).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final pro = state.pros[index];
                      return ProMapCard(
                        pro: pro,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/pro/${pro.id}');
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
