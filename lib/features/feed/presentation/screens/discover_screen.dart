import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../../shared/utils/service_category_icons.dart';
import '../../../profile/presentation/widgets/social_badge_widget.dart';
import '../../data/discover_notifier.dart';
import '../../domain/provider_search_result.dart';
import '../../domain/video_model.dart';

const _filterCategories = [
  'Tous', 'Coiffure', 'Beauté', 'Fitness', 'Photo',
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

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    ref.read(discoverProvider.notifier).setShowHistory(_focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
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
                        AnalyticsService.instance.capture('search_performed', properties: {
                          'query_length': v.length,
                          'source': 'submit',
                        });
                      },
                      style: const TextStyle(color: AppColors.blanc, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher des pros, services...',
                        hintStyle: const TextStyle(color: AppColors.gris),
                        prefixIcon: const Icon(Icons.search, color: AppColors.gris, size: 20),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchCtrl,
                          builder: (context, value, _) => value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.gris, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    n.search('');
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final path = GoRouterState.of(context).uri.path;
                      final base = path.startsWith('/pro/search')
                          ? '/pro/search'
                          : '/client/discover';
                      context.push('$base/results');
                    },
                    icon: const Icon(Icons.view_list_outlined, color: AppColors.blanc),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () {
                      final path = GoRouterState.of(context).uri.path;
                      final base = path.startsWith('/pro/search')
                          ? '/pro/search'
                          : '/client/discover';
                      context.push('$base/map');
                    },
                    icon: const Icon(Icons.map_outlined, color: AppColors.blanc),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 6),
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
            if (s.showHistory && s.searchHistory.isNotEmpty)
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
                          const Text('Recherches récentes', style: TextStyle(color: AppColors.gris, fontSize: 12)),
                          GestureDetector(
                            onTap: n.clearHistory,
                            child: const Text('Effacer', style: TextStyle(color: AppColors.gris, fontSize: 12)),
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
                            AnalyticsService.instance.capture('search_performed', properties: {
                              'query_length': query.length,
                              'source': 'history',
                            });
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
                  final isAll = cat == 'Tous';
                  return GestureDetector(
                    onTap: () => n.setCategory(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.violet : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: selected ? null : Border.all(color: AppColors.blanc.withAlpha(26)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAll ? Icons.apps : ServiceCategoryIcons.icon(cat),
                            size: 14,
                            color: selected ? AppColors.blanc : AppColors.gris,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat,
                            style: TextStyle(
                              color: selected ? AppColors.blanc : AppColors.gris,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: s.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.violet))
                  : s.hasError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off_outlined,
                                    color: AppColors.gris, size: 48),
                                const SizedBox(height: 16),
                                const Text(
                                  'Impossible de charger les professionnels.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.blanc,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Vérifie ta connexion puis réessaie.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.gris, fontSize: 14),
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: () => n.reloadWithFilters(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.violet,
                                  ),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : CustomScrollView(
                      slivers: [
                        if (s.nearbyProviders.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Text(
                                    'Professionnels proches',
                                    style: TextStyle(
                                      color: AppColors.blanc,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 148,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: s.nearbyProviders.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemBuilder: (context, i) =>
                                        _NearbyProCard(pro: s.nearbyProviders[i]),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                        if (s.results != null && s.results!.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.65,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _ProCard(video: s.results![index]),
                                childCount: s.results!.length,
                              ),
                            ),
                          ),
                        if (!s.isLoading &&
                            s.nearbyProviders.isEmpty &&
                            (s.results == null || s.results!.isEmpty))
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'Aucun résultat',
                                style: TextStyle(color: AppColors.gris, fontSize: 15),
                              ),
                            ),
                          ),
                        if (!s.isLoading &&
                            s.nearbyProviders.isNotEmpty &&
                            (s.results == null || s.results!.isEmpty))
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: Text(
                                'Aucune vidéo pour ces critères.',
                                style: TextStyle(color: AppColors.gris, fontSize: 14),
                              ),
                            ),
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

class _FiltersSheet extends ConsumerWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(discoverProvider);
    final n = ref.read(discoverProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtres', style: TextStyle(color: AppColors.blanc, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Distance max', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
              Text('${s.maxDistance.toInt()} km', style: const TextStyle(color: AppColors.blanc, fontSize: 16)),
            ],
          ),
          Slider(
            value: s.maxDistance,
            min: 1,
            max: 100,
            activeColor: AppColors.violet,
            inactiveColor: AppColors.surfaceAlt,
            onChanged: n.setDistance,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Note minimum', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
              Text(s.minRating.toStringAsFixed(1), style: const TextStyle(color: AppColors.blanc, fontSize: 16)),
            ],
          ),
          Slider(
            value: s.minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.violet,
            inactiveColor: AppColors.surfaceAlt,
            onChanged: n.setRating,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prix max', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
              Text('\$${s.maxPrice.toInt()}', style: const TextStyle(color: AppColors.blanc, fontSize: 16)),
            ],
          ),
          Slider(
            value: s.maxPrice,
            min: 10,
            max: 500,
            activeColor: AppColors.violet,
            inactiveColor: AppColors.surfaceAlt,
            onChanged: n.setPrice,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Disponible aujourd\'hui', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
            value: s.availableToday,
            activeTrackColor: AppColors.violet.withAlpha(128),
            contentPadding: EdgeInsets.zero,
            onChanged: n.setAvailableToday,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                n.reloadWithFilters();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: AppColors.blanc,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Appliquer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _NearbyProCard extends StatelessWidget {
  const _NearbyProCard({required this.pro});
  final ProviderSearchResult pro;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/provider/${pro.id}'),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surfaceAlt,
                    backgroundImage:
                        pro.avatarUrl != null ? CachedNetworkImageProvider(pro.avatarUrl!) : null,
                    child: pro.avatarUrl == null
                        ? Icon(ServiceCategoryIcons.icon(pro.category), color: AppColors.gris, size: 28)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ServiceCategoryIcons.icon(pro.category),
                        size: 12,
                        color: AppColors.blanc,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pro.displayName,
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (pro.city != null && pro.city!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  pro.city!,
                  style: const TextStyle(color: AppColors.gris, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (pro.distanceKm != null) ...[
                const Spacer(),
                Text(
                  '${pro.distanceKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(color: AppColors.grisClair, fontSize: 10),
                ),
              ],
            ],
          ),
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
      onTap: () => context.push('/client/provider/${video.proId}'),
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
