import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _initPlayer();
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

  @override
  void didUpdateWidget(covariant PostMediaBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
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
        // Video or thumbnail fallback
        if (_controller != null)
          BetterPlayer(controller: _controller!)
        else if (widget.thumbnailUrl != null)
          CachedNetworkImage(
            imageUrl: widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.fond),
          )
        else
          const ColoredBox(color: AppColors.fond),

        // Bottom gradient overlay
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 350,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.fond],
                stops: [0.42, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
