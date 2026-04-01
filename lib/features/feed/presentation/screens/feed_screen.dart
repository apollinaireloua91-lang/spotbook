import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
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

    if (s.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(child: CircularProgressIndicator(color: AppColors.blanc)),
      );
    }

    if (s.videos.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.play_circle_outline, size: 64, color: AppColors.gris.withAlpha(128)),
          const SizedBox(height: 16),
          const Text('No videos yet', style: TextStyle(color: AppColors.blanc, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Videos from professionals will appear here', style: TextStyle(color: AppColors.gris, fontSize: 14)),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: s.videos.length,
        onPageChanged: n.setCurrentIndex,
        itemBuilder: (context, index) {
          return VideoFeedItem(
            video: s.videos[index],
            isActive: index == s.currentIndex,
            onLikeToggled: (liked) => n.toggleLike(index, liked),
          );
        },
      ),
    );
  }
}
