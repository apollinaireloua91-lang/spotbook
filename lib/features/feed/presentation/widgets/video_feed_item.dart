import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../../shared/widgets/bookmark_bounce.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../data/feed_play_state.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';
import 'comments_sheet.dart';
import 'like_animation.dart';
import 'share_bottom_sheet.dart';

class _ShowLikeAnimNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() {
    state = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      state = false;
    });
  }
}

final _showLikeAnimProvider = NotifierProvider<_ShowLikeAnimNotifier, bool>(
  _ShowLikeAnimNotifier.new,
  isAutoDispose: true,
);

class VideoFeedItem extends ConsumerStatefulWidget {
  const VideoFeedItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.onLikeToggled,
    this.index,
    this.onToggleLike,
    this.onToggleSave,
    this.onToggleFollow,
    this.useLocalHeartAnimation = false,
    this.rightColumnOverride,
    this.bottomOverlayOverride,
  });

  final VideoModel video;
  final bool isActive;
  final ValueChanged<bool> onLikeToggled;
  final int? index;
  final void Function(int index, bool liked)? onToggleLike;
  final void Function(int index, bool saved)? onToggleSave;
  final void Function(int index, bool followed)? onToggleFollow;
  final bool useLocalHeartAnimation;

  /// When provided, replaces the default right action column.
  final Widget? rightColumnOverride;

  /// When provided, replaces the default bottom-left overlay.
  final Widget? bottomOverlayOverride;

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem> {
  BetterPlayerController? _controller;
  bool _viewCounted = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.video.streamUrl == null) return;

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.video.streamUrl!,
      videoFormat: BetterPlayerVideoFormat.hls,
    );

    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: widget.isActive,
        looping: true,
        fit: BoxFit.cover,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        aspectRatio: 9 / 16,
      ),
      betterPlayerDataSource: dataSource,
    );

    if (widget.isActive) {
      _isPlaying = true;
      _countView();
    }
  }

  @override
  void didUpdateWidget(covariant VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      _isPlaying = true;
      _countView();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
      _isPlaying = false;
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
    // Keep the persistent play/pause button in sync.
    ref.read(feedPlayStateProvider.notifier).set(_isPlaying);
  }

  void _countView() {
    if (_viewCounted) return;
    _viewCounted = true;
    ref.read(videoRepositoryProvider).incrementViewCount(widget.video.id);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleLike() {
    HapticFeedback.mediumImpact();
    final newLiked = !widget.video.isLiked;
    widget.onLikeToggled(newLiked);
    if (widget.onToggleLike != null && widget.index != null) {
      widget.onToggleLike!(widget.index!, newLiked);
    }
    if (newLiked) {
      AnalyticsService.instance.capture('video_liked', properties: {
        'video_id': widget.video.id,
        'pro_id': widget.video.proId,
      });
    }
  }

  void _toggleSave() {
    HapticFeedback.lightImpact();
    if (widget.onToggleSave != null && widget.index != null) {
      widget.onToggleSave!(widget.index!, !widget.video.isSaved);
    }
  }

  void _onDoubleTap() {
    if (!widget.video.isLiked) {
      _toggleLike();
    }
    ref.read(_showLikeAnimProvider.notifier).trigger();
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(videoId: widget.video.id),
    );
  }

  void _openModerationMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.flag_outlined, color: AppColors.blanc),
                title:
                    Text('Report', style: TextStyle(color: AppColors.blanc)),
                onTap: () {
                  ctx.pop();
                  showReportSheet(
                    context,
                    targetId: widget.video.id,
                    targetType: 'video',
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.block, color: AppColors.error),
                title: Text('Block this pro',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  ctx.pop();
                  showBlockConfirmDialog(
                    context,
                    ref: ref,
                    userId: widget.video.proId,
                    userName: widget.video.proName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLikeAnim = ref.watch(_showLikeAnimProvider);

    // Sync with the persistent play/pause button from FeedScreen.
    ref.listen<bool>(feedPlayStateProvider, (prev, next) {
      if (!widget.isActive || _controller == null) return;
      if (next && !_isPlaying) {
        _controller!.play();
        setState(() => _isPlaying = true);
      } else if (!next && _isPlaying) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      }
    });

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Video / Thumbnail ───
          if (_controller != null)
            IgnorePointer(child: BetterPlayer(controller: _controller!))
          else if (widget.video.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.black),
            )
          else
            Container(color: Colors.black),

          // ─── Bottom gradient — deeper, cinematic ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 350,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(230),
                    Colors.black.withAlpha(100),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // ─── Bottom overlay: Book Now + Pro info + caption ───
          if (widget.bottomOverlayOverride != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 72,
              child: widget.bottomOverlayOverride!,
            )
          else
            Positioned(
              bottom: 100,
              left: 16,
              right: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium Book Now CTA with gradient + glow
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/pro/${widget.video.proId}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientAccent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withAlpha(100),
                            blurRadius: 20,
                            spreadRadius: -2,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: AppColors.violet.withAlpha(40),
                            blurRadius: 40,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'Book Now',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // @username + verified badge
                  GestureDetector(
                    onTap: () =>
                        context.push('/pro/${widget.video.proId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '@${widget.video.proName ?? 'Pro'}',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textOnVideo,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              shadows: const [
                                Shadow(
                                  color: AppColors.overlayHeavy,
                                  blurRadius: 10,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.violet.withAlpha(60),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 10),
                        ),
                      ],
                    ),
                  ),
                  // Caption
                  if (widget.video.title.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.video.title,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        shadows: const [
                          Shadow(
                              color: AppColors.overlayMedium, blurRadius: 8),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

          // ─── Right side action buttons — Premium glass column ───
          Positioned(
            bottom: 100,
            right: 12,
            child: widget.rightColumnOverride ??
                Column(
                  children: [
                    // Pro avatar with gradient ring
                    GestureDetector(
                      onTap: () =>
                          context.push('/pro/${widget.video.proId}'),
                      child: SizedBox(
                        width: 50,
                        height: 58,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.gradientAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.violet.withAlpha(50),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                  ),
                                  const BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: CircleAvatar(
                                radius: 21,
                                backgroundColor: Colors.black,
                                backgroundImage:
                                    widget.video.proAvatarUrl != null
                                        ? CachedNetworkImageProvider(
                                            widget.video.proAvatarUrl!)
                                        : null,
                                child: widget.video.proAvatarUrl == null
                                    ? Text(
                                        (widget.video.proName ?? 'P')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: GoogleFonts.sora(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (!widget.video.isFollowed)
                              Positioned(
                                bottom: 0,
                                right: -1,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (widget.onToggleFollow != null &&
                                        widget.index != null) {
                                      widget.onToggleFollow!(
                                          widget.index!, true);
                                    }
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.gradientAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              AppColors.violet.withAlpha(80),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.add,
                                        color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Like — with glow when active
                    _PremiumActionButton(
                      icon: widget.video.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      label: _formatCount(widget.video.likesCount),
                      color: widget.video.isLiked
                          ? AppColors.rose
                          : Colors.white,
                      isActive: widget.video.isLiked,
                      glowColor: AppColors.rose,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(height: 16),
                    // Comments
                    _PremiumActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: _formatCount(widget.video.commentsCount),
                      onTap: _openComments,
                    ),
                    const SizedBox(height: 16),
                    // Bookmark
                    BookmarkBounce(
                      isSaved: widget.video.isSaved,
                      child: _PremiumActionButton(
                        icon: widget.video.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        label: '',
                        color: widget.video.isSaved
                            ? AppColors.violet
                            : Colors.white,
                        isActive: widget.video.isSaved,
                        glowColor: AppColors.violet,
                        onTap: _toggleSave,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Share
                    _PremiumActionButton(
                      icon: Icons.share_outlined,
                      label: '',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              ShareBottomSheet(videoId: widget.video.id),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // More
                    _PremiumActionButton(
                      icon: Icons.more_horiz_rounded,
                      label: '',
                      onTap: _openModerationMenu,
                    ),
                  ],
                ),
          ),

          // ─── Double-tap like animation ───
          if (showLikeAnim) const Center(child: LikeAnimation()),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ─── Premium Action Button — Glass circle background + glow on active ───────

class _PremiumActionButton extends StatelessWidget {
  const _PremiumActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.isActive = false,
    this.glowColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isActive;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? (glowColor ?? color).withAlpha(25)
                  : Colors.black.withAlpha(50),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? (glowColor ?? color).withAlpha(60)
                    : Colors.white.withAlpha(15),
                width: isActive ? 1.0 : 0.5,
              ),
              boxShadow: isActive && glowColor != null
                  ? [
                      BoxShadow(
                        color: glowColor!.withAlpha(40),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
              shadows: const [
                Shadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 2)),
              ],
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 1)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
