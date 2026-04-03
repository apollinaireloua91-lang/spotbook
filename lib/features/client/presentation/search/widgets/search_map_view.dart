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

class _SearchMapViewState extends State<SearchMapView>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final _cardScrollController = ScrollController();
  bool _cameraFitted = false;

  /// Cached BitmapDescriptor per pro id.
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

  // ── Marker icon generation via Canvas + PictureRecorder ──

  /// Builds a 40×40 rounded-rect marker with category color + Material icon.
  Future<BitmapDescriptor> _makeProMarkerIcon({
    required String category,
    bool isSelected = false,
  }) async {
    const int px = 80; // 2× for retina
    final double size = px.toDouble();
    const double r = 24.0; // corner radius (scaled)

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final catColor = categoryColor(category);

    // Background rounded rect
    final bgPaint = Paint()..color = catColor;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(r),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = isSelected
          ? AppColors.violet
          : Colors.white.withAlpha(51) // ~0.2 opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 5.0 : 4.0;
    canvas.drawRRect(bgRect, borderPaint);

    // Selected glow shadow (bake into bitmap)
    if (isSelected) {
      final glowPaint = Paint()
        ..color = AppColors.violet.withAlpha(102) // ~0.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(bgRect, glowPaint);
    }

    // Category icon (Material Icons font)
    final iconData = categoryIcon(category);
    final paraBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: size * 0.45,
        fontFamily: 'MaterialIcons',
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: AppColors.blanc,
        fontFamily: 'MaterialIcons',
      ))
      ..addText(String.fromCharCode(iconData.codePoint));
    final para = paraBuilder.build();
    para.layout(ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(para, Offset(0, (size - para.height) / 2));

    final img = await recorder.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Builds a 16px violet dot with white border for user location.
  Future<void> _buildUserMarkerIcon() async {
    const int px = 64;
    const double half = px / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Outer pulse ring (static in bitmap — larger faded circle)
    canvas.drawCircle(
      const Offset(half, half),
      half - 2,
      Paint()..color = AppColors.violet.withAlpha(40),
    );

    // Main dot
    canvas.drawCircle(
      const Offset(half, half),
      12,
      Paint()..color = AppColors.violet,
    );

    // White border
    canvas.drawCircle(
      const Offset(half, half),
      12,
      Paint()
        ..color = AppColors.blanc
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final img = await recorder.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (mounted) {
      setState(() {
        _userMarkerIcon =
            BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
      });
    }
  }

  /// Build icons for all visible pros (async, cached).
  void _buildProMarkerIcons(List<ProSearchResult> pros, String? selectedId) {
    for (final p in pros.take(_kMaxMarkers)) {
      final key = '${p.id}_${p.id == selectedId}';
      if (_markerIcons.containsKey(key)) continue;
      _makeProMarkerIcon(
        category: p.category,
        isSelected: p.id == selectedId,
      ).then((icon) {
        if (mounted) setState(() => _markerIcons[key] = icon);
      });
    }
  }

  // ── Camera ──

  void _fitCameraToPros(List<ProSearchResult> pros, double? uLat, double? uLng) {
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

  void _animateToMarker(ProSearchResult pro) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pro.lat, pro.lng), 14),
    );
  }

  void _scrollToCard(int index) {
    final offset = index * 230.0; // card width 220 + gap 10
    _cardScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientSearchCubit, ClientSearchState>(
      listenWhen: (prev, curr) => prev.selectedProId != curr.selectedProId,
      listener: (context, state) {
        if (state.selectedPro != null) {
          _animateToMarker(state.selectedPro!);
          final idx = state.pros.indexWhere((p) => p.id == state.selectedPro!.id);
          if (idx >= 0) _scrollToCard(idx);
        }
      },
      builder: (context, state) {
        // Build marker icons async
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _buildProMarkerIcons(state.pros, state.selectedProId);
          }
        });

        // Assemble Google Maps markers
        final markers = <Marker>{};

        // User location marker
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

        // Pro markers (max 20)
        for (final pro in state.pros.take(_kMaxMarkers)) {
          final key = '${pro.id}_${pro.id == state.selectedProId}';
          markers.add(Marker(
            markerId: MarkerId(pro.id),
            position: LatLng(pro.lat, pro.lng),
            icon: _markerIcons[key] ?? BitmapDescriptor.defaultMarker,
            zIndexInt: pro.id == state.selectedProId ? 100 : 1,
            anchor: const Offset(0.5, 0.5),
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<ClientSearchCubit>().selectPro(pro.id);
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
              onTap: (_) {
                context.read<ClientSearchCubit>().selectPro(null);
              },
            ),

            // ── My location FAB ──
            Positioned(
              right: 14,
              bottom: 190,
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
                  width: 40,
                  height: 40,
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
                  child: const Icon(
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
                  height: 170,
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
                        isSelected: state.selectedProId == pro.id,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<ClientSearchCubit>()
                              .selectPro(pro.id);
                        },
                        onViewProfile: () =>
                            context.push('/pro/${pro.id}'),
                        onBook: () => context.push(
                          '/client/booking-flow/${pro.id}',
                        ),
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
