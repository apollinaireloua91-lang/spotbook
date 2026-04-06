import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../feed/data/feed_notifier.dart';
import 'cubit/client_feed_cubit.dart';
import 'widgets/client_post_page.dart';
import 'widgets/client_top_bar.dart';

class ClientFeedScreen extends StatefulWidget {
  const ClientFeedScreen({super.key});

  @override
  State<ClientFeedScreen> createState() => _ClientFeedScreenState();
}

class _ClientFeedScreenState extends State<ClientFeedScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientFeedCubit, ClientFeedState>(
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
            backgroundColor: AppColors.surface,
          ),
        );
        context.read<ClientFeedCubit>().clearTransientError();
      },
      child: BlocConsumer<ClientFeedCubit, ClientFeedState>(
        listenWhen: (p, c) =>
            p.activeTab != c.activeTab ||
            (p.videos.isNotEmpty && c.videos.isEmpty && c.isLoading),
        listener: (context, state) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        },
        builder: (context, state) {
          final cubit = context.read<ClientFeedCubit>();
          return Scaffold(
            backgroundColor: AppColors.fond,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // ─── Content ───
                if (state.isLoading)
                  const SpotbookLoadingShimmer.feed()
                else if (state.videos.isEmpty)
                  _FeedEmptyState(
                    isFollowingTab: state.activeTab == FeedTab.following,
                    hasError: state.error != null,
                    onDiscoverTap: () => cubit.switchTab(FeedTab.discover),
                    onRetry: () => cubit.switchTab(state.activeTab),
                  )
                else
                  RefreshIndicator(
                    onRefresh: () async => cubit.switchTab(state.activeTab),
                    color: AppColors.violet,
                    backgroundColor: AppColors.surface,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: state.videos.length,
                      onPageChanged: cubit.setCurrentIndex,
                      itemBuilder: (context, index) {
                        final video = state.videos[index];
                        return ClientPostPage(
                          video: video,
                          isActive: index == state.currentIndex,
                          onToggleLike: () =>
                              cubit.toggleLike(index, !video.isLiked),
                          onToggleSave: () =>
                              cubit.toggleSave(index, !video.isSaved),
                          onToggleFollow: () =>
                              cubit.toggleFollow(index, !video.isFollowed),
                          onViewCounted: () => cubit.countView(video.id),
                        );
                      },
                    ),
                  ),

                // ─── Top bar (always on top) ───
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClientTopBar(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeedEmptyState extends StatefulWidget {
  const _FeedEmptyState({
    required this.isFollowingTab,
    required this.hasError,
    required this.onDiscoverTap,
    required this.onRetry,
  });

  final bool isFollowingTab;
  final bool hasError;
  final VoidCallback onDiscoverTap;
  final VoidCallback onRetry;

  @override
  State<_FeedEmptyState> createState() => _FeedEmptyStateState();
}

class _FeedEmptyStateState extends State<_FeedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathScale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated pulsing icon
            AnimatedBuilder(
              animation: _breathCtrl,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathScale.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.violet.withAlpha(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet
                              .withAlpha((_glowOpacity.value * 40).toInt()),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isFollowingTab
                          ? Icons.person_add_rounded
                          : Icons.play_circle_rounded,
                      size: 48,
                      color: AppColors.violet,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              widget.isFollowingTab
                  ? 'Discover the best Pros'
                  : 'Discover the best Pros',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isFollowingTab
                  ? 'Follow professionals to see\ntheir videos here'
                  : 'Pro videos will appear here\nas they publish their work',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Primary CTA
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.isFollowingTab) {
                  widget.onDiscoverTap();
                } else {
                  // Navigate to search
                  context.go('/client/search');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, color: AppColors.blanc, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Discover Pros',
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.hasError) ...[
              const SizedBox(height: 20),
              Text(
                'An error occurred',
                style: TextStyle(
                  color: AppColors.error.withAlpha(180),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: widget.onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: AppColors.violet,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.violet,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
