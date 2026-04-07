import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';


class PostMediaBackground extends StatefulWidget {
  const PostMediaBackground({
    super.key,
    required this.streamUrl,
    required this.thumbnailUrl,
    required this.isActive,
  });

  final String? streamUrl;
  final String? thumbnailUrl;
  final bool isActive;

  @override
  State<PostMediaBackground> createState() => PostMediaBackgroundState();
}

class PostMediaBackgroundState extends State<PostMediaBackground> {
  BetterPlayerController? _controller;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    // Auto-play if this page is already active on first build
    if (widget.isActive && _controller != null) {
      _controller!.play();
      _isPlaying = true;
    }
  }

  void _initPlayer() {
    final url = widget.streamUrl;
    if (url == null) return;

    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: false,
        looping: true,
        fit: BoxFit.cover,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        aspectRatio: 9 / 16,
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        videoFormat: BetterPlayerVideoFormat.hls,
      ),
    );
  }

  /// Toggle play/pause and return whether video is now playing.
  bool togglePlayPause() {
    if (_controller == null) return false;
    if (_isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
      return false;
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
      return true;
    }
  }

  @override
  void didUpdateWidget(covariant PostMediaBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      setState(() => _isPlaying = true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
      setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_controller != null)
          BetterPlayer(controller: _controller!)
        else if (widget.thumbnailUrl != null)
          CachedNetworkImage(
            imageUrl: widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
          )
        else
          const ColoredBox(color: Colors.black),

        // Bottom gradient — tall enough to cover right column icons
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withAlpha(60),
                  Colors.black.withAlpha(160),
                  Colors.black.withAlpha(220),
                ],
                stops: const [0.0, 0.30, 0.50, 0.72, 1.0],
              ),
            ),
          ),
        ),
        // Right-side gradient — ensures icon readability
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(90),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
