import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';
import '../widgets/video_feed_item.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();
  final List<VideoModel> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final videos = await ref.read(videoRepositoryProvider).getScoredVideos();
      if (mounted) {
        setState(() {
          _videos.addAll(videos);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final more = await ref.read(videoRepositoryProvider).getMoreVideos(offset: _videos.length);
      if (mounted) setState(() => _videos.addAll(more));
    } catch (_) {
      // Silently fail
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (index > _videos.length - 3) _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(child: CircularProgressIndicator(color: AppColors.blanc)),
      );
    }

    if (_videos.isEmpty) {
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
        itemCount: _videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return VideoFeedItem(
            video: _videos[index],
            isActive: index == _currentIndex,
            onLikeToggled: (liked) {
              setState(() {
                final v = _videos[index];
                _videos[index] = VideoModel(
                  id: v.id, proId: v.proId, cloudflareId: v.cloudflareId,
                  streamUrl: v.streamUrl, thumbnailUrl: v.thumbnailUrl,
                  title: v.title, description: v.description, category: v.category,
                  hashtags: v.hashtags, status: v.status, rejectionReason: v.rejectionReason,
                  likesCount: v.likesCount + (liked ? 1 : -1), commentsCount: v.commentsCount,
                  viewsCount: v.viewsCount, flagCount: v.flagCount, createdAt: v.createdAt,
                  proName: v.proName, proAvatarUrl: v.proAvatarUrl, proCity: v.proCity, isLiked: liked,
                );
              });
            },
          );
        },
      ),
    );
  }
}
