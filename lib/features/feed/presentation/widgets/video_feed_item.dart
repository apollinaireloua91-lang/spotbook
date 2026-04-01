import 'dart:ui';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../../shared/utils/cloudflare_stream_urls.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../data/feed_notifier.dart';
import '../../domain/video_model.dart';
import 'comments_sheet.dart';
import 'like_animation.dart';
import 'music_ticker.dart';
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
    required this.index,
    this.onToggleLike,
    this.onToggleSave,
    this.onToggleFollow,
    this.useLocalHeartAnimation = false,
  });

  final VideoModel video;
  final bool isActive;
  final int index;

  /// Callbacks optionnels : feed piloté par Bloc (shell client) sans dépendance inverse.
  final void Function(int index, bool liked)? onToggleLike;
  final void Function(int index, bool saved)? onToggleSave;
  final void Function(int index, bool followed)? onToggleFollow;

  /// Double-tap cœur : animation locale (Bloc) au lieu du provider Riverpod.
  final bool useLocalHeartAnimation;

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem> {
  BetterPlayerController? _controller;
  bool _viewCounted = false;
  bool _captionExpanded = false;
  bool _localShowHeart = false;
  bool _playbackFailed = false;
  bool _playerLoading = false;
  bool _manuallyPaused = false;

  /// Mute global partagé entre toutes les instances — false = son activé.
  static final ValueNotifier<bool> _muteNotifier = ValueNotifier<bool>(false);

  String? _playbackUrl(VideoModel v) {
    final u = v.streamUrl;
    if (u != null && u.isNotEmpty) return u;
    return cloudflareManifestUrl(v.cloudflareId);
  }

  @override
  void initState() {
    super.initState();
    _muteNotifier.addListener(_onMuteChanged);
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _activateClip();
      });
    }
  }

  void _onMuteChanged() {
    final c = _controller;
    if (c == null || !mounted) return;
    c.setVolume(_muteNotifier.value ? 0 : 1);
  }

  void _onBetterPlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;
    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      _disposePlayer();
      setState(() {
        _playbackFailed = true;
        _playerLoading = false;
      });
    }
  }

  void _disposePlayer() {
    final c = _controller;
    if (c != null) {
      c.dispose(forceDispose: true);
      _controller = null;
    }
    _playerLoading = false;
  }

  Future<void> _activateClip() async {
    if (!mounted || !widget.isActive) return;
    final url = _playbackUrl(widget.video);
    if (url == null || url.isEmpty) {
      return;
    }
    if (_playbackFailed) return;

    if (_controller != null) {
      await _controller!.setVolume(_muteNotifier.value ? 0 : 1);
      await _controller!.play();
      _countView();
      return;
    }

    setState(() => _playerLoading = true);

    BetterPlayerController? ctrl;
    try {
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        videoFormat: BetterPlayerVideoFormat.hls,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 2000,
          maxBufferMs: 10000,
          bufferForPlaybackMs: 1500,
          bufferForPlaybackAfterRebufferMs: 3000,
        ),
      );

      ctrl = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          looping: true,
          fit: BoxFit.cover,
          autoDispose: false,
          handleLifecycle: true,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            showControls: false,
          ),
          aspectRatio: 9 / 16,
          eventListener: _onBetterPlayerEvent,
          placeholder: _thumbnailLayer(widget.video),
          showPlaceholderUntilPlay: true,
        ),
        betterPlayerDataSource: dataSource,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _playerLoading = false;
          _playbackFailed = true;
        });
      }
      return;
    }

    if (!mounted) {
      ctrl.dispose(forceDispose: true);
      return;
    }

    setState(() {
      _controller = ctrl;
      _playerLoading = false;
    });

    await ctrl.setVolume(_muteNotifier.value ? 0 : 1);
    await ctrl.play();
    _countView();
  }

  void _deactivateClip() {
    _disposePlayer();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _disposePlayer();
      setState(() {
        _playbackFailed = false;
        _viewCounted = false;
      });
      if (widget.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _activateClip();
        });
      }
      return;
    }
    if (widget.isActive && !oldWidget.isActive) {
      _activateClip();
    } else if (!widget.isActive && oldWidget.isActive) {
      _deactivateClip();
    }
  }

  Widget _thumbnailLayer(VideoModel v) {
    return SizedBox.expand(
      child: _thumbnailImage(v),
    );
  }

  Widget _thumbnailImage(VideoModel v) {
    final t = v.thumbnailUrl;
    if (t != null && t.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: t,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _cfThumbnailFallback(v),
      );
    }
    return _cfThumbnailFallback(v);
  }

  Widget _cfThumbnailFallback(VideoModel v) {
    final cf = cloudflareThumbnailUrl(v.cloudflareId);
    if (cf != null) {
      return CachedNetworkImage(
        imageUrl: cf,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _videoPlaceholderBg(v),
      );
    }
    return _videoPlaceholderBg(v);
  }

  Widget _videoPlaceholderBg(VideoModel v) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceAlt, AppColors.fond],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 72,
              color: AppColors.blanc.withAlpha(50),
            ),
            if (v.proName != null) ...[
              const SizedBox(height: 14),
              Text(
                v.proName!,
                style: TextStyle(
                  color: AppColors.blanc.withAlpha(90),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mediaBackground(VideoModel v) {
    final url = _playbackUrl(v);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_controller != null)
          BetterPlayer(controller: _controller!)
        else
          _thumbnailImage(v),
        if (_playbackFailed)
          Positioned.fill(
            child: Material(
              color: AppColors.overlayDark,
              child: InkWell(
                onTap: _retryPlayback,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 56,
                        color: AppColors.blanc,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lecture impossible',
                        style: TextStyle(
                          color: AppColors.grisClair,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Appuyer pour réessayer',
                        style: TextStyle(
                          color: AppColors.gris,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (widget.isActive &&
            url != null &&
            _controller == null &&
            !_playbackFailed &&
            _playerLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.violet),
          ),
      ],
    );
  }

  void _countView() {
    if (_viewCounted) return;
    _viewCounted = true;
    try {
      Supabase.instance.client
          .rpc('increment_video_views', params: {'vid': widget.video.id});
    } catch (_) {}
  }

  void _retryPlayback() {
    setState(() {
      _playbackFailed = false;
      _viewCounted = false;
      _manuallyPaused = false;
    });
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _activateClip();
      });
    }
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) {
      // No controller yet — try to start
      if (!_playbackFailed) _activateClip();
      return;
    }
    if (_manuallyPaused) {
      c.play();
      setState(() => _manuallyPaused = false);
    } else {
      c.pause();
      setState(() => _manuallyPaused = true);
    }
  }

  @override
  void dispose() {
    _muteNotifier.removeListener(_onMuteChanged);
    _disposePlayer();
    super.dispose();
  }

  FeedNotifier get _notifier => ref.read(feedProvider.notifier);

  void _triggerHeartAnimation() {
    if (widget.useLocalHeartAnimation) {
      setState(() => _localShowHeart = true);
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _localShowHeart = false);
      });
    } else {
      ref.read(_showLikeAnimProvider.notifier).trigger();
    }
  }

  void _toggleLike() {
    HapticFeedback.mediumImpact();
    final liked = !widget.video.isLiked;
    final cb = widget.onToggleLike;
    if (cb != null) {
      cb(widget.index, liked);
    } else {
      _notifier.toggleLike(widget.index, liked);
    }
    if (liked) {
      AnalyticsService.instance.capture('video_liked', properties: {
        'video_id': widget.video.id,
        'pro_id': widget.video.proId,
      });
    }
  }

  void _toggleSave() {
    HapticFeedback.mediumImpact();
    final saved = !widget.video.isSaved;
    final cb = widget.onToggleSave;
    if (cb != null) {
      cb(widget.index, saved);
    } else {
      _notifier.toggleSave(widget.index, saved);
    }
  }

  void _toggleFollow() {
    HapticFeedback.mediumImpact();
    final followed = !widget.video.isFollowed;
    final cb = widget.onToggleFollow;
    if (cb != null) {
      cb(widget.index, followed);
    } else {
      _notifier.toggleFollow(widget.index, followed);
    }
  }

  void _onDoubleTap() {
    if (!widget.video.isLiked) {
      _toggleLike();
    }
    _triggerHeartAnimation();
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(videoId: widget.video.id),
    );
  }

  void _openShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareBottomSheet(videoId: widget.video.id),
    );
  }

  void _openModerationMenu() {
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.flag_outlined, color: AppColors.blanc),
                title: const Text('Signaler',
                    style: TextStyle(color: AppColors.blanc)),
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
                title: const Text('Bloquer ce pro',
                    style: TextStyle(color: AppColors.error)),
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
    final showLikeAnim = widget.useLocalHeartAnimation
        ? _localShowHeart
        : ref.watch(_showLikeAnimProvider);
    final v = widget.video;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _onDoubleTap,
      onLongPress: _openModerationMenu,
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -300) {
          context.push('/client/provider/${v.proId}');
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Media background (HLS Cloudflare, une seule instance active) ──
          _mediaBackground(v),

          // ── Bottom gradient ──
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.42, 1.0],
                  colors: [
                    Colors.black,
                    Colors.black54,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Play/pause indicator ──
          if (_manuallyPaused)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 80,
                color: AppColors.blanc,
              ),
            ),

          // ── Mute toggle button (top right) ──
          Positioned(
            top: 56,
            right: 14,
            child: ValueListenableBuilder<bool>(
              valueListenable: _muteNotifier,
              builder: (_, muted, __) => GestureDetector(
                onTap: () => _muteNotifier.value = !_muteNotifier.value,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.overlayDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.blanc.withAlpha(40),
                    ),
                  ),
                  child: Icon(
                    muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: AppColors.blanc,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // ── Right column (actions) ──
          Positioned(
            bottom: 200,
            right: 12,
            child: Column(
              children: [
                // Pro avatar + follow
                _ProAvatar(
                  avatarUrl: v.proAvatarUrl,
                  isFollowed: v.isFollowed,
                  onTapAvatar: () =>
                      context.push('/client/provider/${v.proId}'),
                  onTapFollow: _toggleFollow,
                ),
                const SizedBox(height: 20),
                // Like
                _ActionButton(
                  icon: v.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: _formatCount(v.likesCount),
                  color: v.isLiked ? AppColors.error : AppColors.blanc,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),
                // Save/Bookmark
                _ActionButton(
                  icon: v.isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  label: _formatCount(v.savesCount),
                  color: v.isSaved ? AppColors.blanc : AppColors.blanc,
                  onTap: _toggleSave,
                ),
                const SizedBox(height: 20),
                // Share
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  onTap: _openShare,
                ),
                const SizedBox(height: 20),
                // Comments
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(v.commentsCount),
                  onTap: _openComments,
                ),
              ],
            ),
          ),

          // ── Music ticker (if spotify track linked) ──
          if (v.spotifyTrackTitle != null)
            Positioned(
              bottom: 218,
              left: 14,
              right: 60,
              child: MusicTicker(
                trackTitle: v.spotifyTrackTitle!,
                trackArtist: v.spotifyTrackArtist ?? '',
              ),
            ),

          // ── Bottom info (pro name + badge + caption) ──
          Positioned(
            bottom: 156,
            left: 0,
            right: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pro name + category badge
                  GestureDetector(
                    onTap: () =>
                        context.push('/client/provider/${v.proId}'),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            v.proName ?? 'Pro',
                            style: const TextStyle(
                              color: AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (v.proCategory != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blanc.withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              v.proCategory!,
                              style: const TextStyle(
                                color: AppColors.grisClair,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Caption
                  GestureDetector(
                    onTap: () => setState(
                        () => _captionExpanded = !_captionExpanded),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: v.description ?? v.title,
                            style: const TextStyle(
                              color: AppColors.grisClair,
                              fontSize: 12,
                            ),
                          ),
                          if (v.hashtags.isNotEmpty) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: v.hashtags
                                  .map((h) => '#$h')
                                  .join(' '),
                              style: const TextStyle(
                                color: AppColors.violet,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: _captionExpanded ? 10 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CTA strip: réservation (prestation) — toujours hors événement ──
          if (_showServiceBookingStrip(v))
            Positioned(
              bottom: 88,
              left: 10,
              right: 10,
              child: _BookingStrip(
                serviceName: v.serviceName ??
                    _categoryDisplayLabel(v.category) ??
                    'Prestation',
                servicePrice: v.servicePrice,
                nextSlot: v.serviceNextSlot,
                onTap: () {
                  final sid = v.serviceId;
                  if (sid != null && sid.isNotEmpty) {
                    context.push('/client/booking/$sid/${v.proId}');
                  } else {
                    context.push('/client/booking-flow/${v.proId}');
                  }
                },
              ),
            ),

          // ── CTA strip: event ticket ──
          if (v.eventId != null && v.eventId!.isNotEmpty)
            Positioned(
              bottom: 88,
              left: 10,
              right: 10,
              child: _EventStrip(
                eventName: v.eventName ?? 'Événement',
                eventPrice: v.eventPrice,
                eventDate: v.eventDate,
                eventLocation: v.eventLocation,
                onTap: () => context.push(
                    '/client/event/${v.eventId}'),
              ),
            ),

          // ── Double-tap like animation ──
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

// ── Pro avatar with follow badge ──
class _ProAvatar extends StatefulWidget {
  const _ProAvatar({
    required this.avatarUrl,
    required this.isFollowed,
    required this.onTapAvatar,
    required this.onTapFollow,
  });

  final String? avatarUrl;
  final bool isFollowed;
  final VoidCallback onTapAvatar;
  final VoidCallback onTapFollow;

  @override
  State<_ProAvatar> createState() => _ProAvatarState();
}

class _ProAvatarState extends State<_ProAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 1.0,
      upperBound: 1.3,
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onFollowTap() {
    _anim.forward().then((_) => _anim.reverse());
    widget.onTapFollow();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          GestureDetector(
            onTap: widget.onTapAvatar,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blanc, width: 2),
              ),
              child: ClipOval(
                child: widget.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceAlt,
                          child: const Icon(Icons.person,
                              size: 22, color: AppColors.gris),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.person,
                            size: 22, color: AppColors.gris),
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _onFollowTap,
              child: ScaleTransition(
                scale: _anim,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.isFollowed
                        ? AppColors.success
                        : AppColors.blanc,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isFollowed ? Icons.check : Icons.add,
                    size: 14,
                    color: widget.isFollowed
                        ? AppColors.blanc
                        : AppColors.fond,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button (right column) ──
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.blanc,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.08,
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.overlayMedium,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.blanc.withAlpha(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.overlayMedium,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: widget.color, size: 30,
                      shadows: const [
                        Shadow(color: AppColors.shadowDark, blurRadius: 8),
                      ]),
                  const SizedBox(height: 3),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: AppColors.shadowDark, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Booking CTA strip ──
class _BookingStrip extends StatelessWidget {
  const _BookingStrip({
    required this.serviceName,
    this.servicePrice,
    this.nextSlot,
    required this.onTap,
  });

  final String serviceName;
  final double? servicePrice;
  final String? nextSlot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt.withAlpha(230),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withAlpha(77)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (servicePrice != null)
                          Text(
                            '${servicePrice!.toStringAsFixed(0)} \$',
                            style: const TextStyle(
                              color: AppColors.grisClair,
                              fontSize: 11,
                            ),
                          ),
                        if (nextSlot != null) ...[
                          const Text(' · ',
                              style: TextStyle(color: AppColors.gris)),
                          Flexible(
                            child: Text(
                              nextSlot!,
                              style: const TextStyle(
                                color: AppColors.gris,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blanc,
                  foregroundColor: AppColors.fond,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Réserver',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Event CTA strip ──
class _EventStrip extends StatelessWidget {
  const _EventStrip({
    required this.eventName,
    this.eventPrice,
    this.eventDate,
    this.eventLocation,
    required this.onTap,
  });

  final String eventName;
  final double? eventPrice;
  final DateTime? eventDate;
  final String? eventLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt.withAlpha(230),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withAlpha(77)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (eventPrice != null)
                          Text(
                            '${eventPrice!.toStringAsFixed(0)} \$',
                            style: const TextStyle(
                              color: AppColors.grisClair,
                              fontSize: 11,
                            ),
                          ),
                        if (eventLocation != null) ...[
                          const Text(' · ',
                              style: TextStyle(color: AppColors.gris)),
                          Flexible(
                            child: Text(
                              eventLocation!,
                              style: const TextStyle(
                                color: AppColors.gris,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blanc,
                  foregroundColor: AppColors.fond,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Acheter',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _hasLinkedEvent(VideoModel v) {
  final e = v.eventId;
  return e != null && e.trim().isNotEmpty;
}

bool _showServiceBookingStrip(VideoModel v) => !_hasLinkedEvent(v);

String? _categoryDisplayLabel(String? key) {
  if (key == null || key.trim().isEmpty) return null;
  const labels = <String, String>{
    'coiffure': 'Coiffure',
    'beaute': 'Beauté',
    'fitness': 'Fitness',
    'photo': 'Photographie',
    'musique': 'Musique',
    'cuisine': 'Cuisine',
    'massage': 'Massage',
    'tatouage': 'Tatouage',
    'maquillage': 'Maquillage',
    'mode': 'Mode',
    'danse': 'Danse',
    'art': 'Art',
    'coaching': 'Coaching',
    'autre_service': 'Autre service',
  };
  return labels[key] ?? key;
}
