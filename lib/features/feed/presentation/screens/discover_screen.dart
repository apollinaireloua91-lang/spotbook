import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/discover_notifier.dart';
import '../../domain/video_model.dart';

const _filterCategories = [
  'All', 'Coiffure', 'Beauté', 'Fitness', 'Photo',
  'Musique', 'Cuisine', 'Massage', 'Tatouage', 'Mode', 'Coaching',
];

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(discoverProvider);
    final n = ref.read(discoverProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: n.search,
                style: const TextStyle(color: AppColors.blanc, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search professionals, services...',
                  hintStyle: const TextStyle(color: AppColors.gris),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gris, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _filterCategories[index];
                  final selected = s.selectedFilter == cat;
                  return GestureDetector(
                    onTap: () => n.setFilter(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blanc : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: selected ? null : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? AppColors.fond : AppColors.blanc,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: s.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blanc))
                  : s.results == null || s.results!.isEmpty
                      ? const Center(child: Text('No results', style: TextStyle(color: AppColors.gris, fontSize: 15)))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.65,
                          ),
                          itemCount: s.results!.length,
                          itemBuilder: (context, index) => _ProCard(video: s.results![index]),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  width: double.infinity,
                  child: video.thumbnailUrl != null
                      ? CachedNetworkImage(imageUrl: video.thumbnailUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.surfaceAlt))
                      : Container(color: AppColors.surfaceAlt, child: const Icon(Icons.videocam, color: AppColors.gris, size: 32)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.surfaceAlt,
                      backgroundImage: video.proAvatarUrl != null ? CachedNetworkImageProvider(video.proAvatarUrl!) : null,
                      child: video.proAvatarUrl == null ? const Icon(Icons.person, size: 12, color: AppColors.gris) : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(video.proName ?? 'Pro', style: const TextStyle(color: AppColors.blanc, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Text(video.title, style: const TextStyle(color: AppColors.grisClair, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
