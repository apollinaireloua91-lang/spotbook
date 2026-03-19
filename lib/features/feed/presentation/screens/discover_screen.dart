import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../profile/presentation/widgets/social_badge_widget.dart';
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
  final _focusNode = FocusNode();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _showHistory = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _FiltersSheet(),
    );
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      onChanged: n.onSearchChanged,
                      onSubmitted: (v) {
                        _focusNode.unfocus();
                        n.search(v);
                      },
                      style: const TextStyle(color: AppColors.blanc, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search professionals, services...',
                        hintStyle: const TextStyle(color: AppColors.gris),
                        prefixIcon: const Icon(Icons.search, color: AppColors.gris, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.gris, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  n.search('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _openFilters,
                    icon: const Icon(Icons.tune, color: AppColors.blanc),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            if (_showHistory && s.searchHistory.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Searches', style: TextStyle(color: AppColors.gris, fontSize: 12)),
                          GestureDetector(
                            onTap: n.clearHistory,
                            child: const Text('Clear', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    ...s.searchHistory.map((query) => ListTile(
                          leading: const Icon(Icons.history, color: AppColors.gris, size: 20),
                          title: Text(query, style: const TextStyle(color: AppColors.blanc, fontSize: 14)),
                          dense: true,
                          onTap: () {
                            _searchCtrl.text = query;
                            _focusNode.unfocus();
                            n.search(query);
                          },
                        )),
                  ],
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
                  final selected = s.selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => n.setCategory(cat),
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

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet();

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late double _distance;
  late double _rating;
  late bool _availableToday;
  late double _price;

  @override
  void initState() {
    super.initState();
    final s = ref.read(discoverProvider);
    _distance = s.maxDistance;
    _rating = s.minRating;
    _availableToday = s.availableToday;
    _price = s.maxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(color: AppColors.blanc, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Max Distance', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
              Text('${_distance.toInt()} km', style: const TextStyle(color: AppColors.accent, fontSize: 16)),
            ],
          ),
          Slider(
            value: _distance,
            min: 1,
            max: 100,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.surfaceAlt,
            onChanged: (v) => setState(() => _distance = v),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Min Rating', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
              Text(_rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.accent, fontSize: 16)),
            ],
          ),
          Slider(
            value: _rating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.surfaceAlt,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Max Price', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
              Text('\$${_price.toInt()}', style: const TextStyle(color: AppColors.accent, fontSize: 16)),
            ],
          ),
          Slider(
            value: _price,
            min: 10,
            max: 500,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.surfaceAlt,
            onChanged: (v) => setState(() => _price = v),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Available Today', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
            value: _availableToday,
            activeTrackColor: AppColors.accent.withAlpha(128),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _availableToday = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ref.read(discoverProvider.notifier).setFilters(
                      maxDistance: _distance,
                      minRating: _rating,
                      availableToday: _availableToday,
                      maxPrice: _price,
                    );
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.fondDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
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
                  if (video.socialConnections.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: video.socialConnections
                          .map((c) => SocialBadgeWidget(
                                platform: c['platform'] as String,
                                followersCount: c['followers_count'] as int,
                              ))
                          .toList(),
                    ),
                  ],
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
