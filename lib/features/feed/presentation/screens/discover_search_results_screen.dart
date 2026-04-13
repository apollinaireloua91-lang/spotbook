import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/discover_notifier.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../domain/provider_search_result.dart';

/// Fallback categories when Supabase data hasn't loaded yet.
const _kResultsCategoriesFallback = [
  'All', 'Coiffure', 'Barbier', 'Esthétique', 'Massage',
  'Fitness', 'Photographie', 'Musique / DJ', 'Tatouage',
  'Mode', 'Cuisine', 'Coaching',
];

class DiscoverSearchResultsScreen extends ConsumerStatefulWidget {
  const DiscoverSearchResultsScreen({super.key});

  @override
  ConsumerState<DiscoverSearchResultsScreen> createState() =>
      _DiscoverSearchResultsScreenState();
}

class _DiscoverSearchResultsScreenState
    extends ConsumerState<DiscoverSearchResultsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(discoverProvider.notifier).search(value);
    });
  }

  String get _basePath {
    final path = GoRouterState.of(context).uri.path;
    return path.startsWith('/pro/search') ? '/pro/search' : '/client/discover';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(discoverProvider);
    final n = ref.read(discoverProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header : back + search + map ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 8),
              child: Row(
                children: [
                  Semantics(
                    label: l.a11yBack,
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.dmSans(
                          color: AppColors.blanc, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l.searchProfessionalHint,
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.gris, size: 20),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchCtrl,
                          builder: (_, v, __) => v.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: AppColors.gris, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    n.search('');
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconBtn(
                    icon: Icons.map_outlined,
                    tooltip: 'Map',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('$_basePath/map');
                    },
                  ),
                ],
              ),
            ),

            // ── Category chips ──
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _kResultsCategoriesFallback.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _kResultsCategoriesFallback[i];
                  final selected = s.selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => n.setCategory(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
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
                        style: GoogleFonts.dmSans(
                          color: selected
                              ? AppColors.fond
                              : AppColors.blanc,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // ── Provider count ──
            if (!s.isLoading && s.nearbyProviders.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(left: 20, right: 20, bottom: 6),
                child: Text(
                  '${s.nearbyProviders.length} '
                  'professional${s.nearbyProviders.length > 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(
                      color: AppColors.gris, fontSize: 13),
                ),
              ),

            // ── Content ──
            Expanded(
              child: s.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.blanc,
                        strokeWidth: 2,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.blanc,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        if (s.activeQuery != null &&
                            s.activeQuery!.isNotEmpty) {
                          await n.search(s.activeQuery!);
                        } else {
                          await n.reloadWithFilters();
                        }
                      },
                      child: s.nearbyProviders.isEmpty
                          ? _EmptyState(
                              query: s.activeQuery,
                              hasError: s.hasError,
                              onRetry: () => n.reloadWithFilters(),
                            )
                          : ListView.separated(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 32),
                              itemCount: s.nearbyProviders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) =>
                                  _ProviderCard(pro: s.nearbyProviders[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header icon button
// ─────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.blanc, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty / error state
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.query,
    this.hasError = false,
    required this.onRetry,
  });

  final String? query;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasError
                    ? Icons.wifi_off_rounded
                    : Icons.search_off_rounded,
                color: AppColors.gris,
                size: 52,
              ),
              const SizedBox(height: 16),
              Text(
                hasError
                    ? 'Connection error.\nPull to retry.'
                    : (query != null && query!.isNotEmpty
                        ? l.noResultsFor(query!)
                        : l.noProfessionalsAvailable),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 24),
                SpotbookButton.secondary(
                  label: l.retry,
                  onPressed: onRetry,
                  width: 140,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Provider card
// ─────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.pro});

  final ProviderSearchResult pro;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.fond,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/client/provider/${pro.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              SpotbookAvatar(
                imageUrl: pro.avatarUrl,
                name: pro.displayName,
                radius: 25,
                isOnline: pro.isOnline ?? false,
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            pro.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              color: AppColors.blanc,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (pro.averageRating != null &&
                            pro.averageRating! > 0) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded,
                              color: AppColors.blanc, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            pro.averageRating!.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                              color: AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (pro.category != null &&
                        pro.category!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        pro.category!,
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 13),
                      ),
                    ],
                    if (pro.city != null && pro.city!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: AppColors.gris, size: 13),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              pro.distanceKm != null
                                  ? '${pro.city} • ${pro.distanceKm!.toStringAsFixed(1)} km'
                                  : pro.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                  color: AppColors.gris, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (pro.minPrice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'From ${pro.minPrice!.toStringAsFixed(0)}\$',
                        style: GoogleFonts.dmSans(
                          color: AppColors.grisClair,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Book button
              SpotbookButton.outlined(
                label: l.book,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/client/provider/${pro.id}');
                },
                width: 92,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
