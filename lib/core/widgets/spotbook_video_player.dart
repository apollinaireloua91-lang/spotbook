import 'dart:async';
import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/theme/app_colors.dart';

/// Global mute state shared across all video players in the feed.
///
/// When a user taps to unmute, ALL subsequent videos play with audio.
/// Persisted via Hive for cross-session consistency.
class _FeedAudioState {
  _FeedAudioState._();
  static final instance = _FeedAudioState._();

  static const _boxName = 'spotbook_prefs';
  static const _key = 'feed_audio_muted';

  bool _muted = true;
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get stream => _controller.stream;
  bool get isMuted => _muted;

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    _muted = box.get(_key, defaultValue: true) as bool;
  }

  Future<void> toggle() async {
    _muted = !_muted;
    _controller.add(_muted);
    final box = await Hive.openBox(_boxName);
    await box.put(_key, _muted);
  }
}

/// Reusable video player for the entire Spotbook app.
///
/// Uses `better_player_plus` for HLS playback (Cloudflare Stream .m3u8).
///
/// **Feed mode** (`showControls: false`): muted by default, tap to toggle.
/// **Preview mode** (`showControls: true`): audio on, full controls.
class SpotbookVideoPlayer extends StatefulWidget {
  const SpotbookVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.loop = true,
    this.showControls = false,
    this.initiallyMuted = true,
    this.isActive = true,
    this.fit = BoxFit.cover,
    this.localFile,
  });

  /// HLS URL from Cloudflare Stream (.m3u8) — ignored if [localFile] is set.
  final String videoUrl;

  /// Local file for preview (before upload).
  final File? localFile;

  final bool autoPlay;
  final bool loop;

  /// Show play/pause + progress bar (preview mode).
  final bool showControls;

  /// Muted on start — true in feed, false in preview.
  final bool initiallyMuted;

  /// Whether this player is the currently visible one (feed paging).
  final bool isActive;

  final BoxFit fit;

  /// Initialize the global audio state. Call once in main().
  static Future<void> initAudioState() => _FeedAudioState.instance.init();

  @override
  State<SpotbookVideoPlayer> createState() => _SpotbookVideoPlayerState();
}

class _SpotbookVideoPlayerState extends State<SpotbookVideoPlayer>
    with WidgetsBindingObserver {
  BetterPlayerController? _controller;
  late bool _isMuted;
  bool _showMuteIndicator = false;
  Timer? _muteIndicatorTimer;
  StreamSubscription<bool>? _audioSub;
  bool _showFirstLaunchHint = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initiallyMuted) {
      // Feed mode — use global mute state
      _isMuted = _FeedAudioState.instance.isMuted;
      _audioSub = _FeedAudioState.instance.stream.listen((muted) {
        if (mounted) {
          setState(() => _isMuted = muted);
          _controller?.setVolume(muted ? 0.0 : 1.0);
        }
      });

      // Show "Tap for sound" hint briefly on first video
      if (_isMuted) {
        _showFirstLaunchHint = true;
        _hintTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showFirstLaunchHint = false);
        });
      }
    } else {
      // Preview mode — audio on
      _isMuted = false;
    }

    _initPlayer();
  }

  void _initPlayer() {
    final BetterPlayerDataSource dataSource;

    if (widget.localFile != null) {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        widget.localFile!.path,
      );
    } else {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.videoUrl,
        videoFormat: BetterPlayerVideoFormat.hls,
      );
    }

    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: widget.autoPlay && widget.isActive,
        looping: widget.loop,
        fit: widget.fit,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: widget.showControls,
          enableProgressBar: widget.showControls,
          enablePlayPause: widget.showControls,
          enableSkips: false,
          enableFullscreen: false,
          enableMute: false,
          enableOverflowMenu: false,
          playerTheme: BetterPlayerTheme.custom,
          customControlsBuilder: widget.showControls ? null : (_, __, ___) => const SizedBox.shrink(),
        ),
        aspectRatio: 9 / 16,
      ),
      betterPlayerDataSource: dataSource,
    );

    _controller!.setVolume(_isMuted ? 0.0 : 1.0);
  }

  @override
  void didUpdateWidget(covariant SpotbookVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _controller?.play();
    }
  }

  void _toggleMute() {
    if (widget.initiallyMuted) {
      // Feed mode — toggle global state
      _FeedAudioState.instance.toggle();
    } else {
      // Preview mode — toggle local
      setState(() => _isMuted = !_isMuted);
      _controller?.setVolume(_isMuted ? 0.0 : 1.0);
    }

    // Show mute indicator briefly
    setState(() {
      _showMuteIndicator = true;
      _showFirstLaunchHint = false;
    });
    _muteIndicatorTimer?.cancel();
    _muteIndicatorTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showMuteIndicator = false);
    });
  }

  @override
  void dispose() {
    _muteIndicatorTimer?.cancel();
    _hintTimer?.cancel();
    _audioSub?.cancel();
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container(color: AppColors.fond);
    }

    return GestureDetector(
      onTap: widget.showControls ? null : _toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video ──
          BetterPlayer(controller: _controller!),

          // ── Center mute/unmute indicator (flash) ──
          if (_showMuteIndicator)
            Center(
              child: AnimatedOpacity(
                opacity: _showMuteIndicator ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.overlayMedium,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: AppColors.blanc,
                    size: 32,
                  ),
                ),
              ),
            ),

          // ── "Tap for sound" hint ──
          if (_showFirstLaunchHint)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.overlayMedium,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_off, color: AppColors.blanc, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Tap for sound',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Persistent mute icon (bottom-right, feed only) ──
          if (!widget.showControls && _isMuted && !_showMuteIndicator)
            Positioned(
              bottom: 16,
              right: 16,
              child: Icon(
                Icons.volume_off,
                color: AppColors.blanc,
                size: 16,
              ),
            ),

          // ── Preview mode: volume toggle button ──
          if (widget.showControls)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.overlayMedium,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: AppColors.blanc,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
