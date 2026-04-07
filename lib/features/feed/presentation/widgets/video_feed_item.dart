import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../../shared/widgets/bookmark_bounce.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
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
  /// Used by ProFeedScreen to show Pro-specific buttons (no Comment, enhanced Spotify).
  final Widget? rightColumnOverride;

  /// When provided, replaces the default bottom-left overlay (pro name + Book).
  /// Used by ProFeedScreen to show PostLeftColumnPro (name + badge + caption + CTA).
  final Widget? bottomOverlayOverride;

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem> {
  BetterPlayerController? _controller;
  bool _viewCounted = false;

  bool _isPlaying = false;
  bool _showPlayPauseIcon = false;

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
      _showPlayPauseIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPlayPauseIcon = false);
    });
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, color: AppColors.blanc),
                title: const Text('Report', style: TextStyle(color: AppColors.blanc)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showReportSheet(
                    context,
                    targetId: widget.video.id,
                    targetType: 'video',
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block, color: AppColors.error),
                title: const Text('Block this pro', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
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

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Video / Thumbnail ───
          // IgnorePointer prevents BetterPlayer's internal GestureDetector
          // from stealing taps meant for play/pause and double-tap like.
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

          // ─── Bottom gradient ───
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.overlayHeavy, Colors.transparent],
                ),
              ),
            ),
          ),

          // ─── Bottom overlay: Pro name + Book (or custom override) ───
          if (widget.bottomOverlayOverride != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 72,
              child: widget.bottomOverlayOverride!,
            )
          else
            Positioned(
              bottom: 90,
              left: 16,
              right: 76,
              child: GestureDetector(
                onTap: () => context.push('/pro/${widget.video.proId}'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.video.proName ?? 'Pro',
                        style: const TextStyle(
                          color: AppColors.textOnVideo,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: AppColors.overlayHeavy,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.white.withAlpha(40)),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Right side action buttons ───
          Positioned(
            bottom: 100,
            right: 12,
            child: widget.rightColumnOverride ??
                Column(
                  children: [
                    // Pro avatar + follow badge
                    GestureDetector(
                      onTap: () => context.push('/pro/${widget.video.proId}'),
                      child: SizedBox(
                        width: 48,
                        height: 56,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 8),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.surfaceAlt,
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (!widget.video.isFollowed)
                              Positioned(
                                bottom: -2,
                                right: -2,
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
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF043603),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.add,
                                        color: Colors.white, size: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ActionButton(
                      icon: widget.video.isLiked
                          ? Icons.favorite
                          : Icons.favorite_outline,
                      label: _formatCount(widget.video.likesCount),
                      color: widget.video.isLiked
                          ? Colors.red
                          : Colors.white,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: _formatCount(widget.video.commentsCount),
                      onTap: _openComments,
                    ),
                    const SizedBox(height: 18),
                    BookmarkBounce(
                      isSaved: widget.video.isSaved,
                      child: _ActionButton(
                        icon: widget.video.isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        label: '',
                        color: widget.video.isSaved
                            ? const Color(0xFF043603)
                            : Colors.white,
                        onTap: _toggleSave,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
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
                    const SizedBox(height: 18),
                    _ActionButton(
                      icon: Icons.more_horiz,
                      label: '',
                      onTap: _openModerationMenu,
                    ),
                  ],
                ),
          ),

          // ─── Play/Pause overlay icon ───
          if (_showPlayPauseIcon)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: AppColors.textOnVideo,
                  size: 36,
                ),
              ),
            ),
          // Permanent pause icon when paused
          if (!_isPlaying && !_showPlayPauseIcon && widget.isActive)
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.textOnVideo,
                  size: 32,
                ),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
            shadows: const [
              Shadow(color: Colors.black38, blurRadius: 6),
            ],
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
