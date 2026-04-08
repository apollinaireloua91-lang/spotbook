import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';

/// Post-capture video editing: full-screen preview, trim timeline,
/// text overlay, filters. Navigation: camera → here → publish.
class ProviderVideoEditScreen extends StatefulWidget {
  const ProviderVideoEditScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<ProviderVideoEditScreen> createState() =>
      _ProviderVideoEditScreenState();
}

class _ProviderVideoEditScreenState extends State<ProviderVideoEditScreen> {
  BetterPlayerController? _controller;
  bool _isPlaying = true;
  double _trimStart = 0;
  double _trimEnd = 1;
  int _selectedFilter = 0;
  String? _overlayText;
  final _textCtrl = TextEditingController();
  Duration _totalDuration = Duration.zero;

  static const _filterNames = [
    'Original',
    'N&B',
    'Chaud',
    'Froid',
    'Vif',
  ];

  static const _filterMatrices = <ColorFilter?>[
    null,
    ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    ColorFilter.matrix(<double>[
      1.2, 0, 0, 0, 10,
      0, 1.0, 0, 0, 0,
      0, 0, 0.8, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    ColorFilter.matrix(<double>[
      0.8, 0, 0, 0, 0,
      0, 1.0, 0, 0, 0,
      0, 0, 1.2, 0, 10,
      0, 0, 0, 1, 0,
    ]),
    ColorFilter.matrix(<double>[
      1.3, 0, 0, 0, 0,
      0, 1.3, 0, 0, 0,
      0, 0, 1.3, 0, 0,
      0, 0, 0, 1, 0,
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        widget.videoPath,
      ),
    );
    _controller!.addEventsListener(_onPlayerEvent);
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      final d = _controller?.videoPlayerController?.value.duration;
      if (d != null) {
        setState(() => _totalDuration = d);
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeEventsListener(_onPlayerEvent);
    _controller?.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      _controller?.pause();
    } else {
      _controller?.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _showTextOverlayDialog() {
    _textCtrl.text = _overlayText ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Add text',
            style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: _textCtrl,
          style: GoogleFonts.dmSans(color: AppColors.blanc),
          maxLength: 50,
          decoration: InputDecoration(
            hintText: 'Your text...',
            hintStyle: GoogleFonts.dmSans(color: AppColors.gris.withAlpha(128)),
            counterStyle: GoogleFonts.dmSans(color: AppColors.gris),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _overlayText = null);
              Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: GoogleFonts.dmSans(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () {
              final text = _textCtrl.text.trim();
              setState(() => _overlayText = text.isEmpty ? null : text);
              Navigator.pop(ctx);
            },
            child: Text('OK',
                style: GoogleFonts.dmSans(color: AppColors.blanc, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    HapticFeedback.mediumImpact();
    final trimStartMs =
        (_totalDuration.inMilliseconds * _trimStart).round();
    final trimEndMs =
        (_totalDuration.inMilliseconds * _trimEnd).round();
    context.push('/pro/video/publish', extra: {
      'videoPath': widget.videoPath,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'filterIndex': _selectedFilter,
      'overlayText': _overlayText,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: SpotbookAppBar(
        title: 'Edit video',
        actions: [
          TextButton(
            onPressed: _onNext,
            child: Text('Next',
                style: GoogleFonts.dmSans(
                    color: AppColors.violet,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video preview
          Expanded(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_controller != null)
                    ColorFiltered(
                      colorFilter: _filterMatrices[_selectedFilter] ??
                          const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst),
                      child: BetterPlayer(controller: _controller!),
                    ),
                  // Overlay text
                  if (_overlayText != null)
                    Positioned(
                      bottom: 80,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.fond.withAlpha(180),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _overlayText!,
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Play / Pause indicator
                  if (!_isPlaying)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.fond.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow,
                          color: AppColors.blanc, size: 36),
                    ),
                ],
              ),
            ),
          ),

          // Trim timeline
          if (_totalDuration.inMilliseconds > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(Duration(
                            milliseconds:
                                (_totalDuration.inMilliseconds *
                                        _trimStart)
                                    .round())),
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 12),
                      ),
                      Text('Trim',
                          style: GoogleFonts.dmSans(
                              color: AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(
                        _formatDuration(Duration(
                            milliseconds:
                                (_totalDuration.inMilliseconds *
                                        _trimEnd)
                                    .round())),
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RangeSlider(
                    values: RangeValues(_trimStart, _trimEnd),
                    onChanged: (values) {
                      setState(() {
                        _trimStart = values.start;
                        _trimEnd = values.end;
                      });
                    },
                    activeColor: AppColors.violet,
                    inactiveColor: AppColors.border,
                  ),
                ],
              ),
            ),
          ],

          // Action toolbar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.surfaceAlt,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.text_fields,
                  label: 'Text',
                  isActive: _overlayText != null,
                  onTap: _showTextOverlayDialog,
                ),
                _ToolButton(
                  icon: Icons.tune,
                  label: 'Filters',
                  isActive: _selectedFilter > 0,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedFilter = _selectedFilter > 0 ? 0 : 1);
                  },
                ),
              ],
            ),
          ),

          // Filter selector
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: _filterNames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final selected = index == _selectedFilter;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedFilter = index);
                  },
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.violet
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.violet
                            : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filterNames[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: selected
                            ? AppColors.blanc
                            : AppColors.gris,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isActive ? AppColors.violet : AppColors.blanc,
              size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                color: isActive ? AppColors.violet : AppColors.gris,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}
