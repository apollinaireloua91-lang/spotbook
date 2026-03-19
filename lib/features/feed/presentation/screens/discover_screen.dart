import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';

const _filterCategories = [
  'All',
  'Coiffure',
  'Beauté',
  'Fitness',
  'Photo',
  'Musique',
  'Cuisine',
  'Massage',
  'Tatouage',
  'Mode',
  'Coaching',
];

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  List<VideoModel>? _results;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDefault();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDefault() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(videoRepositoryProvider);
      final videos = _selectedFilter == 'All'
          ? await repo.searchVideos('')
          : await repo
              .getVideosByCategory(_selectedFilter.toLowerCase());
      if (mounted) setState(() => _results = videos);
    } catch (_) {
      // Silent
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadDefault();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final videos =
          await ref.read(videoRepositoryProvider).searchVideos(query.trim());
      if (mounted) setState(() => _results = videos);
    } catch (_) {
      // Silent
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: _search,
                style: const TextStyle(color: AppColors.blanc, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search professionals, services...',
                  hintStyle: const TextStyle(color: AppColors.gris),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.gris, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Category filters
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _filterCategories[index];
                  final selected = _selectedFilter == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = cat);
                      _loadDefault();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.blanc
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: selected
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color:
                              selected ? AppColors.fond : AppColors.blanc,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Results grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.blanc))
                  : _results == null || _results!.isEmpty
                      ? const Center(
                          child: Text(
                            'No results',
                            style: TextStyle(
                                color: AppColors.gris, fontSize: 15),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: _results!.length,
                          itemBuilder: (context, index) {
                            final v = _results![index];
                            return _ProCard(video: v);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.video});
  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pro/${video.proId}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  width: double.infinity,
                  child: video.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surfaceAlt),
                        )
                      : Container(
                          color: AppColors.surfaceAlt,
                          child: const Icon(Icons.videocam,
                              color: AppColors.gris, size: 32),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.surfaceAlt,
                        backgroundImage: video.proAvatarUrl != null
                            ? CachedNetworkImageProvider(video.proAvatarUrl!)
                            : null,
                        child: video.proAvatarUrl == null
                            ? const Icon(Icons.person,
                                size: 12, color: AppColors.gris)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          video.proName ?? 'Pro',
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: AppColors.grisClair,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
