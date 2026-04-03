import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
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
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Mon Profil" centered + settings gear right
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Mon Profil',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.blanc,
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
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Impossible de charger les statistiques',
                  style: TextStyle(color: AppColors.gris, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Edit Profile Button ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/edit-profile');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '✏️',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Modifier mon profil',
                          style: TextStyle(
                            color: AppColors.blanc,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                'Paramètres',
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _SettingsSection(context: context),

            const SizedBox(height: 16),

            // ─── Become Pro + Logout ───
            _SpecialActionsSection(context: context),
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
                'Mes Pros favoris',
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/favorites'),
                child: Text(
                  'Voir tout',
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
                    ? const Icon(Icons.person, size: 24, color: AppColors.gris)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pro.businessName ?? 'Pro',
              style: const TextStyle(
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
        'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
        'juil', 'août', 'sep', 'oct', 'nov', 'déc',
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
                'Historique récent',
                style: GoogleFonts.dmSans(
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
                    'Voir tout',
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
        ...items.map((item) {
          final service = item['services'] as Map<String, dynamic>?;
          final pro = item['profiles_pro'] as Map<String, dynamic>?;
          final category = pro?['category'] as String?;
          final price = (service?['price'] as num?)?.toDouble() ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(item['created_at'] as String?),
                        style: const TextStyle(
                          color: AppColors.gris,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${price.toStringAsFixed(0)} \$',
                  style: const TextStyle(
                    color: AppColors.violetClair,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Settings section ───────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return SettingsList(
      items: [
        SettingsItemData(
          icon: '🔔',
          label: 'Notifications',
          onTap: () => context.push('/notification-settings'),
        ),
        SettingsItemData(
          icon: '💳',
          label: 'Paiement',
          onTap: () => context.push('/settings'),
        ),
        SettingsItemData(
          icon: '🔒',
          label: 'Confidentialité',
          onTap: () => context.push('/settings'),
        ),
        SettingsItemData(
          icon: '🌍',
          label: 'Langue',
          onTap: () => context.push('/language-settings'),
        ),
        SettingsItemData(
          icon: '⭐',
          label: 'Mes avis',
          onTap: () => context.push('/favorites'),
        ),
      ],
    );
  }
}

// ─── Become Pro + Logout ────────────────────────────────────────────────────

class _SpecialActionsSection extends ConsumerWidget {
  const _SpecialActionsSection({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _, WidgetRef ref) {
    return SettingsList(
      items: [
        SettingsItemData(
          icon: '🚀',
          label: 'Devenir Pro',
          textColor: AppColors.violetClair,
          isSpecial: true,
          onTap: () => BecomeProSheet.show(context),
        ),
        SettingsItemData(
          icon: '🚪',
          label: 'Se déconnecter',
          textColor: AppColors.roseClair,
          isSpecial: true,
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Se déconnecter',
          style: TextStyle(
            color: AppColors.blanc,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: AppColors.gris, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.gris),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(
                color: AppColors.roseClair,
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
          const Icon(Icons.person_off_outlined,
              color: AppColors.gris, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Non authentifié',
            style: TextStyle(color: AppColors.gris, fontSize: 16),
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
              child: const Text(
                'Se connecter',
                style: TextStyle(
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
            style: GoogleFonts.dmSans(
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
                  style: TextStyle(
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
            style: GoogleFonts.dmSans(
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
                  style: TextStyle(
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
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Impossible de charger votre profil',
              style: TextStyle(color: AppColors.gris, fontSize: 14),
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
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
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
