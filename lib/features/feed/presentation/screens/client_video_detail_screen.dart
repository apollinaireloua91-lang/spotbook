import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/cloudflare_stream_urls.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';

// ─── Providers ───────────────────────────────────────────

final _videoDetailProvider =
    FutureProvider.family<VideoModel?, String>((ref, videoId) async {
  final repo = ref.read(videoRepositoryProvider);
  // Fetch the discover feed and find our video in it.
  // This is a pragmatic approach since there's no single-video endpoint.
  final videos = await repo.getDiscoverFeed(offset: 0, limit: 100);
  for (final v in videos) {
    if (v.id == videoId) return v;
  }
  return null;
});

final _commentsProvider =
    FutureProvider.family<List<CommentModel>, String>((ref, videoId) async {
  return ref.read(videoRepositoryProvider).getComments(videoId);
});

// ─── Screen ──────────────────────────────────────────────

/// Deep-linkable full-screen video with comments sheet and booking overlay.
/// Route: /client/video/:videoId
class ClientVideoDetailScreen extends ConsumerStatefulWidget {
  const ClientVideoDetailScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<ClientVideoDetailScreen> createState() =>
      _ClientVideoDetailScreenState();
}

class _ClientVideoDetailScreenState
    extends ConsumerState<ClientVideoDetailScreen> {
  BetterPlayerController? _playerCtrl;

  @override
  void dispose() {
    _playerCtrl?.dispose();
    super.dispose();
  }

  void _initPlayer(VideoModel video) {
    if (_playerCtrl != null) return;
    final url = cloudflareManifestUrl(video.cloudflareId) ??
        video.streamUrl ??
        '';
    if (url.isEmpty) return;
    _playerCtrl = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        videoFormat: BetterPlayerVideoFormat.hls,
      ),
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(videoId: widget.videoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(_videoDetailProvider(widget.videoId));

    return videoAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (e, _) => Scaffold(
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
                child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        body: Center(
          child: Text('Error: $e',
              style: GoogleFonts.dmSans(color: AppColors.gris)),
        ),
      ),
      data: (video) {
        if (video == null) {
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
                    child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            body: Center(
              child: Text('Video not found',
                  style: GoogleFonts.dmSans(color: AppColors.gris)),
            ),
          );
        }

        _initPlayer(video);

        return Scaffold(
          backgroundColor: AppColors.fond,
          body: Stack(
            children: [
              // Full-screen video
              if (_playerCtrl != null)
                Positioned.fill(
                  child: BetterPlayer(controller: _playerCtrl!),
                ),
              // Gradient overlay bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.fond.withAlpha(220),
                      ],
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: Semantics(
                  label: 'Back',
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              // Right action bar
              Positioned(
                right: 12,
                bottom: 160,
                child: Column(
                  children: [
                    _ActionButton(
                      icon: video.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: video.isLiked
                          ? AppColors.rose
                          : AppColors.blanc,
                      count: video.likesCount,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final repo = ref.read(videoRepositoryProvider);
                        if (video.isLiked) {
                          repo.unlikeVideo(video.id);
                        } else {
                          repo.likeVideo(video.id);
                        }
                        ref.invalidate(
                            _videoDetailProvider(widget.videoId));
                      },
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.blanc,
                      count: video.commentsCount,
                      onTap: _showComments,
                    ),
                  ],
                ),
              ),
              // Bottom info
              Positioned(
                left: 16,
                right: 72,
                bottom: 40 + MediaQuery.of(context).padding.bottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context
                          .push('/client/provider/${video.proId}'),
                      child: Row(
                        children: [
                          SpotbookAvatar(
                            imageUrl: video.proAvatarUrl,
                            radius: 18,
                            name: video.proName,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              video.proName ?? 'Pro',
                              style: GoogleFonts.dmSans(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      video.title,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.description != null &&
                        video.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.description!,
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (video.serviceId != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push(
                              '/client/booking-flow/${video.proId}?serviceId=${video.serviceId}');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientAccent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Book',
                            style: GoogleFonts.dmSans(
                              color: AppColors.blanc,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            count > 0 ? '$count' : '',
            style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Comments Sheet ──────────────────────────────────────

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.videoId});
  final String videoId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(videoRepositoryProvider)
          .addComment(widget.videoId, text);
      _ctrl.clear();
      ref.invalidate(_commentsProvider(widget.videoId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Unable to send comment'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(_commentsProvider(widget.videoId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grisInactif,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Comments',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Divider(color: AppColors.border, height: 1),
          Expanded(
            child: commentsAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(
                      color: AppColors.violet)),
              error: (e, _) => Center(
                child: Text('$e',
                    style: GoogleFonts.dmSans(color: AppColors.gris)),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Text('Aucun commentaire',
                        style: GoogleFonts.dmSans(color: AppColors.gris)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SpotbookAvatar(
                          imageUrl: c.userAvatarUrl,
                          radius: 16,
                          name: c.userName,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.userName ?? 'User',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.blanc,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.content,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.gris,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Input
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border:
                    Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: GoogleFonts.dmSans(
                          color: AppColors.blanc, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.gris.withAlpha(128)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.violet,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.send,
                            color: AppColors.violet, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
