import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/presentation/widgets/video_feed_item.dart';
import '../../../notifications/data/notification_repository.dart';
import 'cubit/pro_feed_cubit.dart';
import 'widgets/post_left_column_pro.dart';
import 'widgets/post_right_column_pro.dart';
import 'widgets/pro_top_bar.dart';

/// Pro feed screen — TikTok-style vertical video feed.
///
/// Key differences from ClientFeedScreen:
/// - No tabs (Découvrir / Abonnements) — shows all approved videos
/// - ProTopBar with 4 notification buttons (bell, calendar, tickets, messages)
/// - Right column: Like + Save + Share + Spotify (NO Comment button)
class ProFeedScreen extends ConsumerStatefulWidget {
  const ProFeedScreen({super.key});

  @override
  ConsumerState<ProFeedScreen> createState() => _ProFeedScreenState();
}

class _ProFeedScreenState extends ConsumerState<ProFeedScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProFeedCubit(
        videoRepository: ref.read(videoRepositoryProvider),
        notificationRepository: ref.read(notificationRepositoryProvider),
      ),
      child: _ProFeedBody(pageController: _pageController),
    );
  }
}

class _ProFeedBody extends StatelessWidget {
  const _ProFeedBody({required this.pageController});

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProFeedCubit, ProFeedState>(
      listenWhen: (p, c) => c.error != null && c.error != p.error,
      listener: (context, state) {
        final msg = state.error;
        if (msg == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg == 'like_failed'
                  ? 'Failed to update like'
                  : msg == 'save_failed'
                      ? 'Failed to update save'
                      : msg,
            ),
          ),
        );
        context.read<ProFeedCubit>().clearTransientError();
      },
      child: BlocBuilder<ProFeedCubit, ProFeedState>(
        builder: (context, state) {
          final cubit = context.read<ProFeedCubit>();
          return Scaffold(
            backgroundColor: AppColors.fond,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // ── Content ──
                if (state.isLoading)
                  const SpotbookLoadingShimmer.feed()
                else if (state.videos.isEmpty)
                  _ProFeedEmptyState(onRetry: cubit.refresh)
                else
                  RefreshIndicator(
                    onRefresh: cubit.refresh,
                    color: AppColors.violet,
                    backgroundColor: AppColors.surface,
                    child: PageView.builder(
                      controller: pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: state.videos.length,
                      onPageChanged: cubit.setCurrentIndex,
                      itemBuilder: (context, index) {
                        final video = state.videos[index];
                        return VideoFeedItem(
                          video: video,
                          isActive: index == state.currentIndex,
                          onLikeToggled: (liked) =>
                              cubit.toggleLike(index, liked),
                          index: index,
                          useLocalHeartAnimation: true,
                          onToggleLike: cubit.toggleLike,
                          onToggleSave: cubit.toggleSave,
                          onToggleFollow: cubit.toggleFollow,
                          // Pro feed: full left column (name + badge + caption + CTA + music)
                          bottomOverlayOverride:
                              PostLeftColumnPro(video: video),
                          // Pro feed: custom right column without Comment button
                          rightColumnOverride: PostRightColumnPro(
                            video: video,
                            onToggleLike: () =>
                                cubit.toggleLike(index, !video.isLiked),
                            onToggleSave: () =>
                                cubit.toggleSave(index, !video.isSaved),
                            onToggleFollow: () =>
                                cubit.toggleFollow(
                                    index, !video.isFollowed),
                          ),
                        );
                      },
                    ),
                  ),

                // ── Top bar (always on top) ──
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ProTopBar(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProFeedEmptyState extends StatelessWidget {
  const _ProFeedEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet.withAlpha(25),
              ),
              child: const Icon(
                Icons.play_circle_rounded,
                size: 48,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No videos yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Videos from professionals\nwill appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              height: 46,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: AppColors.blanc,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Refresh',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
