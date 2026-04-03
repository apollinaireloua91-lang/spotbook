import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/feed_notifier.dart';
import '../widgets/video_feed_item.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(feedProvider);
    final n = ref.read(feedProvider.notifier);
    final topPad = MediaQuery.of(context).padding.top;

    if (s.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.blanc)),
      );
    }

    if (s.videos.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline,
                  size: 64, color: AppColors.gris.withAlpha(128)),
              const SizedBox(height: 16),
              const Text('No videos yet',
                  style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Videos from professionals will appear here',
                  style: TextStyle(color: AppColors.gris, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── Video PageView ───
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: s.videos.length,
            onPageChanged: n.setCurrentIndex,
            itemBuilder: (context, index) {
              return VideoFeedItem(
                video: s.videos[index],
                isActive: index == s.currentIndex,
                index: index,
                onLikeToggled: (liked) => n.toggleLike(index, liked),
                onToggleLike: n.toggleLike,
                onToggleSave: n.toggleSave,
                onToggleFollow: n.toggleFollow,
              );
            },
          ),

          // ─── Top Bar Overlay ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: topPad + 8, left: 16, right: 16, bottom: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.overlayMedium,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Spotbook logo — white, DM Sans bold 20
                  Text('Spotbook',
                      style: AppTypography.spotbookLogo(
                          onVideoBackground: true)),

                  const Spacer(),

                  // Discover / Following pill tabs
                  _FeedTabPill(
                    activeTab: s.activeTab,
                    onTap: (tab) {
                      HapticFeedback.lightImpact();
                      n.switchTab(tab);
                    },
                  ),

                  const Spacer(),

                  // Bell notification icon
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.blanc.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.blanc,
                        size: 20,
                      ),
                    ),
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

// ─── Discover / Following tab pill ───────────────────────────────────────────

class _FeedTabPill extends StatelessWidget {
  const _FeedTabPill({required this.activeTab, required this.onTap});

  final FeedTab activeTab;
  final ValueChanged<FeedTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.blanc.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabItem(
            label: 'Discover',
            isActive: activeTab == FeedTab.discover,
            onTap: () => onTap(FeedTab.discover),
          ),
          _TabItem(
            label: 'Following',
            isActive: activeTab == FeedTab.following,
            onTap: () => onTap(FeedTab.following),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blanc.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: AppTypography.feedTab(active: isActive),
        ),
      ),
    );
  }
}
