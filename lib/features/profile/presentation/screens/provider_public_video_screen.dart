import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/provider_profile_data.dart';

/// Lecture plein écran d’une vidéo du profil pro (vue client).
class ProviderPublicVideoScreen extends StatefulWidget {
  const ProviderPublicVideoScreen({super.key, required this.video});

  final VideoEntity video;

  @override
  State<ProviderPublicVideoScreen> createState() =>
      _ProviderPublicVideoScreenState();
}

class _ProviderPublicVideoScreenState extends State<ProviderPublicVideoScreen> {
  BetterPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final url = widget.video.streamUrl;
    if (url != null && url.isNotEmpty) {
      _controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: true,
          looping: true,
          fit: BoxFit.contain,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            enableProgressText: true,
          ),
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          url,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose(forceDispose: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.close, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          widget.video.title ?? 'Vidéo',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: _controller == null
            ? Text(
                'Lecture indisponible',
                style: GoogleFonts.dmSans(color: AppColors.gris),
              )
            : AspectRatio(
                aspectRatio: 9 / 16,
                child: BetterPlayer(controller: _controller!),
              ),
      ),
    );
  }
}
