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

  @override
  void didUpdateWidget(covariant ClientPostPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && !_viewCounted) {
      _viewCounted = true;
      widget.onViewCounted();
    }
  }

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    if (!widget.video.isLiked) {
      widget.onToggleLike();
    }
    setState(() => _showHeart = true);
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
        v.proCategory?.toLowerCase() == 'traiteur' && !hasService && !hasEvent;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Video / Photo background ───
          PostMediaBackground(
            streamUrl: v.streamUrl,
            thumbnailUrl: v.thumbnailUrl,
            isActive: widget.isActive,
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

          // ─── Bottom info (pro name, category, caption) ───
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
              bottom: 90,
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
              bottom: 90,
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
              bottom: 90,
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
    if (hasService || hasEvent || isCatering) return 90;
    return 40;
  }

  double _ctaBottomOffset(
      bool hasService, bool hasEvent, bool isCatering, bool hasMusic) {
    var base = 140.0;
    if (hasService || hasEvent || isCatering) base += 50;
    if (hasMusic) base += 30;
    return base;
  }

  double _infoBottomOffset(
      bool hasService, bool hasEvent, bool isCatering, bool hasMusic) {
    var base = 95.0;
    if (hasService || hasEvent || isCatering) base += 56;
    if (hasMusic) base += 30;
    return base;
  }
}
