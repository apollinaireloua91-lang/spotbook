import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../feed/domain/video_model.dart';
import 'booking_strip.dart';
import 'catering_strip.dart';
import 'client_bottom_info.dart';
import 'client_right_column.dart';
import 'comment_bottom_sheet.dart';
import 'double_tap_heart.dart';
import 'event_strip.dart';
import 'music_ticker.dart';
import 'post_media_background.dart';
import 'share_bottom_sheet.dart';

class ClientPostPage extends StatefulWidget {
  const ClientPostPage({
    super.key,
    required this.video,
    required this.isActive,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onToggleFollow,
    required this.onViewCounted,
  });

  final VideoModel video;
  final bool isActive;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onToggleFollow;
  final VoidCallback onViewCounted;

  @override
  State<ClientPostPage> createState() => _ClientPostPageState();
}

class _ClientPostPageState extends State<ClientPostPage> {
  bool _showHeart = false;
  bool _viewCounted = false;
  bool _isPaused = false;
  bool _showPlayPauseIcon = false;

  final _mediaKey = GlobalKey<PostMediaBackgroundState>();

  @override
  void didUpdateWidget(covariant ClientPostPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && !_viewCounted) {
      _viewCounted = true;
      widget.onViewCounted();
    }
    // Reset pause state when becoming active
    if (widget.isActive && !oldWidget.isActive) {
      setState(() => _isPaused = false);
    }
  }

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    if (!widget.video.isLiked) {
      widget.onToggleLike();
    }
    setState(() => _showHeart = true);
  }

  void _onSingleTap() {
    HapticFeedback.lightImpact();
    final mediaState = _mediaKey.currentState;
    if (mediaState == null) return;

    final nowPlaying = mediaState.togglePlayPause();
    setState(() {
      _isPaused = !nowPlaying;
      _showPlayPauseIcon = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPlayPauseIcon = false);
    });
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentBottomSheet(videoId: widget.video.id),
    );
  }

  void _openShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientShareBottomSheet(videoId: widget.video.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final hasMusic = v.spotifyTrackTitle != null;
    final hasService = v.serviceId != null;
    final hasEvent = v.eventId != null;
    final isCatering =
        (v.proCategory?.toLowerCase() == 'traiteur' ||
            v.proCategory?.toLowerCase() == 'catering') &&
            !hasService && !hasEvent;

    return GestureDetector(
      onTap: _onSingleTap,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Video / Photo background ───
          PostMediaBackground(
            key: _mediaKey,
            streamUrl: v.streamUrl,
            thumbnailUrl: v.thumbnailUrl,
            isActive: widget.isActive,
          ),

          // ─── Play/Pause overlay icon ───
          if (_showPlayPauseIcon || _isPaused)
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayPauseIcon ? 1.0 : (_isPaused ? 0.6 : 0.0),
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(115),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),

          // ─── Right column (actions) ───
          Positioned(
            right: 10,
            bottom: _ctaBottomOffset(hasService, hasEvent, isCatering, hasMusic),
            child: ClientRightColumn(
              video: v,
              onToggleLike: widget.onToggleLike,
              onToggleSave: widget.onToggleSave,
              onToggleFollow: widget.onToggleFollow,
              onCommentTap: _openComments,
              onShareTap: _openShare,
            ),
          ),

          // ─── Bottom info (pro name, category, caption, Book button) ───
          Positioned(
            bottom: _infoBottomOffset(hasService, hasEvent, isCatering, hasMusic),
            left: 12,
            right: 65,
            child: ClientBottomInfo(video: v),
          ),

          // ─── Music ticker (conditional) ───
          if (hasMusic)
            Positioned(
              bottom: _stripBottomBase(hasService, hasEvent, isCatering) + 56,
              left: 14,
              right: 60,
              child: MusicTicker(
                trackTitle: v.spotifyTrackTitle!,
                trackArtist: v.spotifyTrackArtist,
              ),
            ),

          // ─── CTA Strip ───
          if (hasService)
            Positioned(
              bottom: 95,
              left: 12,
              right: 12,
              child: BookingStrip(
                serviceName: v.serviceName,
                servicePrice: v.servicePrice,
                serviceId: v.serviceId!,
                proId: v.proId,
              ),
            ),
          if (hasEvent && !hasService)
            Positioned(
              bottom: 95,
              left: 12,
              right: 12,
              child: EventStrip(
                eventName: v.eventName,
                eventDate: v.eventDate,
                eventId: v.eventId!,
              ),
            ),
          if (isCatering)
            Positioned(
              bottom: 95,
              left: 12,
              right: 12,
              child: CateringStrip(proId: v.proId),
            ),

          // ─── Double tap heart animation ───
          if (_showHeart)
            Center(
              child: DoubleTapHeart(
                onDismissed: () => setState(() => _showHeart = false),
              ),
            ),
        ],
      ),
    );
  }

  // Layout helpers — push content up when CTA strip is present
  double _stripBottomBase(bool hasService, bool hasEvent, bool isCatering) {
    if (hasService || hasEvent || isCatering) return 95;
    return 45;
  }

  double _ctaBottomOffset(
      bool hasService, bool hasEvent, bool isCatering, bool hasMusic) {
    var base = 145.0; // Above nav bar safe area
    if (hasService || hasEvent || isCatering) base += 50;
    if (hasMusic) base += 30;
    return base;
  }

  double _infoBottomOffset(
      bool hasService, bool hasEvent, bool isCatering, bool hasMusic) {
    var base = 145.0; // Aligned with right column (share button level)
    if (hasService || hasEvent || isCatering) base += 50;
    if (hasMusic) base += 30;
    return base;
  }
}
