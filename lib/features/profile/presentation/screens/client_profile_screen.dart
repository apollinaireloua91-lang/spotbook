import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/become_pro_sheet.dart';
import '../widgets/profile_hero.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/settings_list.dart';

// ─── Providers ──────────────────────────────────────────────────────────────

class ClientProfileNotifier extends AsyncNotifier<ClientProfile?> {
  @override
  Future<ClientProfile?> build() async {
    final uid = ref.read(profileRepositoryProvider).currentUserId;
    if (uid == null) return null;
    return ref.read(profileRepositoryProvider).getClientProfile(uid);
  }
}

final clientProfileProvider =
    AsyncNotifierProvider<ClientProfileNotifier, ClientProfile?>(
  ClientProfileNotifier.new,
);

/// Stats: {rdv, following, events, reviews}
final clientStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  final results = await Future.wait([
    repo.countClientBookings(),
    repo.countFollowing(),
    repo.countClientTickets(),
    repo.countReviewsLeftByClient(),
  ]);
  return {
    'rdv': results[0],
    'following': results[1],
    'events': results[2],
    'reviews': results[3],
  };
});

/// Favorite pros list for horizontal scroll
final clientFavProsProvider =
    FutureProvider.autoDispose<List<ClientFavoriteProItem>>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  final data = await repo.getClientFavoritePros();
  return data.map((e) => ClientFavoriteProItem.fromJson(e)).toList();
});

/// Recent booking history
final clientHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getRecentClientHistory();
});

// ─── Screen ─────────────────────────────────────────────────────────────────

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode so the entire subtree rebuilds when dark mode toggles.
    ref.watch(themeModeProvider);

    final profileAsync = ref.watch(clientProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const _UnauthenticatedState();
          return _ProfileBody(profile: profile);
        },
        loading: () => const SpotbookLoadingShimmer.profile(),
        error: (err, _) => _ErrorState(
          onRetry: () => ref.invalidate(clientProfileProvider),
        ),
      ),
    );
  }
}

// ─── Main body ──────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(clientStatsProvider);
    final favProsAsync = ref.watch(clientFavProsProvider);
    final historyAsync = ref.watch(clientHistoryProvider);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'My Profile',
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/settings');
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.blanc.withAlpha(13),
                          ),
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: AppColors.gris,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Hero Section ───
            ProfileHero(profile: profile),

            // ─── Stats Row ───
            statsAsync.when(
              data: (stats) => ProfileStatsRow(
                totalRdv: stats['rdv'] ?? 0,
                totalFollowing: stats['following'] ?? 0,
                totalEvents: stats['events'] ?? 0,
                totalReviews: stats['reviews'] ?? 0,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SpotbookLoadingShimmer.card(itemCount: 1),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Unable to load stats',
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Edit Profile Button ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/edit-profile');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Favorite Pros (horizontal scroll) ───
            favProsAsync.when(
              data: (favPros) {
                if (favPros.isEmpty) return const _EmptyFavorites();
                return _FavoriteProsList(favPros: favPros);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ─── Recent History ───
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) return const _EmptyHistory();
                return _RecentHistory(items: history);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ─── Settings ───
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              child: Text(
                'Settings',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const _SettingsSection(),

            const SizedBox(height: 16),

            // ─── Become Pro + Logout ───
            const _SpecialActionsSection(),
          ],
        ),
      ),
    );
  }
}

// ─── Favorite Pros horizontal scroll ────────────────────────────────────────

class _FavoriteProsList extends StatelessWidget {
  const _FavoriteProsList({required this.favPros});

  final List<ClientFavoriteProItem> favPros;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'My favorite Pros',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/favorites'),
                child: Text(
                  'See all',
                  style: GoogleFonts.dmSans(
                    color: AppColors.violetClair,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: favPros.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, index) =>
                _FavProAvatar(pro: favPros[index]),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FavProAvatar extends StatelessWidget {
  const _FavProAvatar({required this.pro});

  final ClientFavoriteProItem pro;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/pro/${pro.proId}');
      },
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.violet, width: 2),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: pro.avatarUrl != null
                    ? CachedNetworkImageProvider(pro.avatarUrl!)
                    : null,
                child: pro.avatarUrl == null
                    ? Icon(Icons.person, size: 24, color: AppColors.gris)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pro.businessName ?? 'Pro',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent history ─────────────────────────────────────────────────────────

class _RecentHistory extends StatelessWidget {
  const _RecentHistory({required this.items});

  final List<Map<String, dynamic>> items;

  String _categoryEmoji(String? category) {
    switch (category?.toLowerCase()) {
      case 'barbier':
      case 'coiffure':
        return '💇';
      case 'nails':
      case 'esthétique':
        return '💅';
      case 'massage':
      case 'bien-être':
        return '💆';
      case 'traiteur':
      case 'cuisine':
        return '🍽️';
      case 'photographie':
        return '📸';
      case 'fitness':
        return '🏋️';
      default:
        return '📋';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Recent history',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => ctx.push('/client/bookings'),
                  child: Text(
                    'See all',
                    style: GoogleFonts.dmSans(
                      color: AppColors.violetClair,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            final service = item['services'] as Map<String, dynamic>?;
            final pro = item['profiles_pro'] as Map<String, dynamic>?;
            final category = pro?['category'] as String?;
            final price = (service?['price'] as num?)?.toDouble() ?? 0;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.violet.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _categoryEmoji(category),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service?['name'] as String? ?? 'Service',
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(item['created_at'] as String?),
                          style: GoogleFonts.dmSans(
                            color: AppColors.gris,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${price.toStringAsFixed(0)} \$',
                    style: GoogleFonts.dmSans(
                      color: AppColors.violetClair,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Settings section ───────────────────────────────────────────────────────

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Column(
      children: [
        SettingsList(
          items: [
            SettingsItemData(
              icon: 'notifications_outlined',
              label: 'Notifications',
              onTap: () => context.push('/notification-settings'),
            ),
            SettingsItemData(
              icon: 'language',
              label: 'Language',
              onTap: () => context.push('/language-settings'),
            ),
            SettingsItemData(
              icon: 'star_outline',
              label: 'My reviews',
              onTap: () => context.push('/favorites'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.blanc.withAlpha(13)),
          ),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 18,
                color: AppColors.grisClair,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: GoogleFonts.dmSans(
                    color: AppColors.grisClair,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Switch.adaptive(
                  value: isDark,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                  activeTrackColor: AppColors.violet,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Become Pro + Logout ────────────────────────────────────────────────────

class _SpecialActionsSection extends ConsumerWidget {
  const _SpecialActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Become Pro
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              BecomeProSheet.show(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.gradientAccent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.primaryButtonShadow,
              ),
              child: Center(
                child: Text(
                  'Become Pro',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textOnPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Log out
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.logout.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.logout.withAlpha(60),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.logout,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Log out',
                      style: GoogleFonts.dmSans(
                        color: AppColors.logout,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    // Capture the router before any async gap
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Log out',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppColors.gris),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Clear local Hive caches
              for (final name in ['settings', 'app_settings', 'search_history']) {
                if (Hive.isBoxOpen(name)) {
                  await Hive.box(name).clear();
                }
              }
              await Supabase.instance.client.auth.signOut();
              router.go('/login');
            },
            child: Text(
              'Log out',
              style: GoogleFonts.dmSans(
                color: AppColors.logout,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unauthenticated state ──────────────────────────────────────────────────

class _UnauthenticatedState extends StatelessWidget {
  const _UnauthenticatedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined,
              color: AppColors.gris, size: 48),
          const SizedBox(height: 12),
          Text(
            'Not signed in',
            style: GoogleFonts.sora(color: AppColors.gris, fontSize: 16),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Sign in',
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty favorites ────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My favorite Pros',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.blanc.withAlpha(10)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.gris.withAlpha(120),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'Like Pros to find them here',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris.withAlpha(160),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty history ──────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent history',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.blanc.withAlpha(10)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: AppColors.gris.withAlpha(120),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your bookings will appear here',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris.withAlpha(160),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withAlpha(25),
              ),
              child: Icon(
                Icons.error_outline,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading error',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your profile',
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
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
