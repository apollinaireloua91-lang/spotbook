import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../events/data/event_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/domain/video_model.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/pro_profile_content_widgets.dart';
import '../widgets/social_badge_widget.dart';
import '../widgets/social_link_sheets.dart';
import '../widgets/traiteur_soumission_sheet.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PRO SHELL PROFILE — Self-view with header, socials, actions, content tabs,
// and conditional Traiteur section
// ═════════════════════════════════════════════════════════════════════════════

// ─── Providers ────────────────────────────────────────────────────────────────

final _proSelfProfileProvider =
    FutureProvider.autoDispose<ProProfile?>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return null;
  return ref.read(profileRepositoryProvider).getProProfile(uid);
});

final _proSelfVideosProvider =
    FutureProvider.autoDispose<List<VideoModel>>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return [];
  final list = await ref.read(videoRepositoryProvider).getProVideos(uid);
  return list.where((v) => v.status == 'approved').toList();
});

final _proSelfServicesProvider =
    FutureProvider.autoDispose<List<ServiceModel>>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return [];
  return ref.read(bookingRepositoryProvider).getProServices(uid);
});

final _proSelfEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return [];
  return ref.read(eventRepositoryProvider).getEventsByProId(uid);
});

class ProShellProfileScreen extends ConsumerWidget {
  const ProShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_proSelfProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: AppColors.fond,
            body: Center(
              child: Text('Non connecté',
                  style: TextStyle(color: AppColors.gris)),
            ),
          );
        }
        return _ProSelfProfileBody(profile: profile);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.violet),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Text('Erreur : $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE BODY
// ═════════════════════════════════════════════════════════════════════════════

class _ProSelfProfileBody extends ConsumerWidget {
  const _ProSelfProfileBody({required this.profile});

  final ProProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTraiteur = profile.category.toLowerCase().contains('traiteur');

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () async {
            ref.invalidate(_proSelfProfileProvider);
            ref.invalidate(_proSelfVideosProvider);
            ref.invalidate(_proSelfServicesProvider);
            ref.invalidate(_proSelfEventsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // ── Header ──
              _ProfileHeader(profile: profile),

              const SizedBox(height: 20),

              // ── Social Links Grid ──
              if (profile.socialConnections.isNotEmpty) ...[
                _SocialGrid(connections: profile.socialConnections),
                const SizedBox(height: 20),
              ],

              // ── Quick Actions ──
              _QuickActions(profile: profile),

              const SizedBox(height: 24),

              // ── Videos Section ──
              _SectionHeader(
                title: 'Mes vidéos',
                onSeeAll: () => context.push('/pro/feed'),
              ),
              const SizedBox(height: 10),
              _VideosRow(ref: ref),

              const SizedBox(height: 24),

              // ── Services Section ──
              _SectionHeader(
                title: 'Mes services',
                onSeeAll: () => context.push('/pro/services'),
              ),
              const SizedBox(height: 10),
              _ServicesList(ref: ref),

              // ── Traiteur Section (conditional) ──
              if (isTraiteur) ...[
                const SizedBox(height: 24),
                _TraiteurSection(
                  ref: ref,
                  proId: profile.id,
                  services:
                      ref.watch(_proSelfServicesProvider).asData?.value ?? [],
                ),
              ],

              const SizedBox(height: 24),

              // ── Events Section ──
              _SectionHeader(
                title: 'Mes événements',
                onSeeAll: () => context.push('/pro/events'),
              ),
              const SizedBox(height: 10),
              _EventsList(ref: ref),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE HEADER — avatar, name, category badge, location
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.profile});

  final ProProfile profile;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final name = profile.businessName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Column(
      children: [
        // Settings gear top right
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/settings');
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blanc.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: AppColors.blanc, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Avatar with breathing animation
        AnimatedBuilder(
          animation: _breathAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _breathAnim.value),
              child: child,
            );
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.violet, width: 2.5),
              gradient: const LinearGradient(
                begin: Alignment(-0.5, -0.5),
                end: Alignment(0.5, 0.5),
                colors: [AppColors.violetDarkGradient, AppColors.violetDarkGradientEnd],
              ),
            ),
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 72,
                      height: 72,
                    ),
                  )
                : Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blanc,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Name
        Text(
          name.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.blanc,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Category badge
        if (profile.category.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blanc,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              profile.category,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.fond,
              ),
            ),
          ),
        const SizedBox(height: 6),
        // Location
        if (profile.city != null && profile.city!.trim().isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on,
                  size: 12, color: AppColors.grisInactif),
              const SizedBox(width: 3),
              Text(
                profile.city!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.grisInactif,
                ),
              ),
            ],
          ),
        // Rating
        if (profile.reviewsCount > 0) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.warning, size: 14),
              const SizedBox(width: 3),
              Text(
                '${profile.rating.toStringAsFixed(1)} (${profile.reviewsCount} avis)',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.gris,
                ),
              ),
            ],
          ),
        ],
        // Bio
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            profile.bio!.trim(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.gris,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Edit profile button
        SpotbookButton.outlined(
          label: 'Modifier le profil',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push('/edit-profile');
          },
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SOCIAL GRID — 4 columns
// ═════════════════════════════════════════════════════════════════════════════

class _SocialGrid extends StatelessWidget {
  const _SocialGrid({required this.connections});

  final List<SocialConnection> connections;

  static const _platformColors = {
    'tiktok': AppColors.brandTikTokDark,
    'instagram': AppColors.brandInstagramAlt,
    'youtube': AppColors.brandYouTube,
    'snapchat': AppColors.brandSnapchat,
    'twitter': AppColors.brandTwitter,
    'spotify': AppColors.spotifyGreen,
  };

  void _onTapSocial(BuildContext context, SocialConnection conn) async {
    final info = platformInfoFor(conn.platform.toLowerCase());
    if (info == null) return;
    HapticFeedback.selectionClick();
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialLinkBottomSheet(
        platform: info,
        currentUrl: conn.handle,
      ),
    );
  }

  void _onAddPlatform(BuildContext context) async {
    final existing = connections.map((c) => c.platform.toLowerCase()).toSet();
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<SocialPlatformInfo>(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddSocialPlatformSheet(alreadyAdded: existing),
    );
    if (picked != null && context.mounted) {
      await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.fond,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SocialLinkBottomSheet(platform: picked),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final conn in connections)
          GestureDetector(
            onTap: () => _onTapSocial(context, conn),
            child: _SocialIcon(
              platform: conn.platform,
              isLinked: true,
              color: _platformColors[conn.platform.toLowerCase()] ??
                  AppColors.surface,
            ),
          ),
        // Add platform button
        GestureDetector(
          onTap: () => _onAddPlatform(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.add, color: AppColors.grisInactif, size: 18),
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.platform,
    required this.isLinked,
    required this.color,
  });

  final String platform;
  final bool isLinked;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SocialIcon(platform: platform, size: 42),
        if (isLinked)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fond, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUICK ACTIONS — row of action buttons
// ═════════════════════════════════════════════════════════════════════════════

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.profile});

  final ProProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionBtn(
          icon: Icons.design_services_outlined,
          label: 'Services',
          onTap: () => context.push('/pro/services'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.event_outlined,
          label: 'Événements',
          onTap: () => context.push('/pro/events'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.bar_chart_rounded,
          label: 'Revenus',
          onTap: () => context.push('/pro/revenue'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.schedule_outlined,
          label: 'Dispo',
          onTap: () => context.push('/pro/availability'),
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.violet, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: AppColors.gris,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.blanc,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Voir tout',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.violet,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VIDEOS ROW — horizontal scroll
// ═════════════════════════════════════════════════════════════════════════════

class _VideosRow extends StatelessWidget {
  const _VideosRow({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_proSelfVideosProvider);

    return async.when(
      data: (videos) {
        if (videos.isEmpty) {
          return _EmptySection(
            icon: Icons.videocam_outlined,
            text: 'Aucune vidéo',
            actionLabel: '+ Ajouter une vidéo',
            onAction: () => context.push('/pro/camera'),
          );
        }
        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == videos.length) {
                return _AddVideoCard(
                  onTap: () => context.push('/pro/camera'),
                );
              }
              return SizedBox(
                width: 100,
                child: VideoThumbnailCard(video: videos[i]),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AddVideoCard extends StatelessWidget {
  const _AddVideoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.grisInactif, size: 24),
            const SizedBox(height: 6),
            Text(
              'Ajouter',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.grisInactif,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICES LIST
// ═════════════════════════════════════════════════════════════════════════════

class _ServicesList extends StatelessWidget {
  const _ServicesList({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_proSelfServicesProvider);

    return async.when(
      data: (services) {
        if (services.isEmpty) {
          return _EmptySection(
            icon: Icons.design_services_outlined,
            text: 'Aucun service',
            actionLabel: '+ Ajouter un service',
            onAction: () => context.push('/pro/services'),
          );
        }
        return Column(
          children: [
            for (final s in services.take(3))
              _ProSelfServiceCard(service: s),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProSelfServiceCard extends StatelessWidget {
  const _ProSelfServiceCard({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.violetDarkGradientEnd,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.design_services_outlined,
                color: AppColors.violet, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${service.durationMinutes} min',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: AppColors.grisInactif,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${service.price.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.violet,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EVENTS LIST
// ═════════════════════════════════════════════════════════════════════════════

class _EventsList extends StatelessWidget {
  const _EventsList({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_proSelfEventsProvider);

    return async.when(
      data: (events) {
        if (events.isEmpty) {
          return _EmptySection(
            icon: Icons.event_outlined,
            text: 'Aucun événement',
            actionLabel: '+ Créer un événement',
            onAction: () => context.push('/pro/events'),
          );
        }
        return Column(
          children: [
            for (final e in events.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProSelfEventCard(event: e),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProSelfEventCard extends StatelessWidget {
  const _ProSelfEventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.eventDate != null
        ? DateFormat.yMMMd('fr_FR').format(event.eventDate!)
        : '—';

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.rose.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event,
                  color: AppColors.rose, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blanc,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.gris,
                    ),
                  ),
                ],
              ),
            ),
            if (event.minPrice > 0)
              Text(
                '\$${event.minPrice.toStringAsFixed(0)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.violet,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRAITEUR SECTION — conditional, only for category == 'traiteur'
// ═════════════════════════════════════════════════════════════════════════════

class _TraiteurSection extends StatelessWidget {
  const _TraiteurSection({
    required this.ref,
    required this.proId,
    required this.services,
  });

  final WidgetRef ref;
  final String proId;
  final List<ServiceModel> services;

  @override
  Widget build(BuildContext context) {
    // Collect menu items from traiteur services
    final allItems = <MenuItemModel>[];
    for (final s in services) {
      allItems.addAll(s.menuItems);
    }
    final traiteurServices =
        services.where((s) => s.isTraiteurService).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        _TraiteurBanner(),

        const SizedBox(height: 14),

        // Menu Grid
        if (allItems.isNotEmpty) ...[
          _SectionHeader(title: 'Mon menu'),
          const SizedBox(height: 10),
          _MenuGrid(items: allItems.take(4).toList()),
          const SizedBox(height: 14),
        ],

        // Forfaits
        if (traiteurServices.isNotEmpty) ...[
          _SectionHeader(title: 'Mes forfaits'),
          const SizedBox(height: 10),
          for (final f in traiteurServices)
            _ForfaitCard(service: f),
          const SizedBox(height: 14),
        ],

        // Soumission CTA
        _SoumissionCTA(proId: proId),
      ],
    );
  }
}

class _TraiteurBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(0.5, 0.5),
          colors: [AppColors.catering, AppColors.cateringDark],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blanc.withAlpha(26),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🍽️ Section Traiteur',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blanc,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gérez votre menu, forfaits et demandes de soumission',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.blanc.withAlpha(204),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Menu Grid ────────────────────────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});

  final List<MenuItemModel> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.1,
      children: items.map((item) => _MenuItemCard(item: item)).toList(),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image zone with emoji
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.violet.withAlpha(40),
                  AppColors.rose.withAlpha(30),
                ],
              ),
            ),
            child: Center(
              child: Text(
                _getEmoji(item.name),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: GoogleFonts.dmSans(
                        fontSize: 8,
                        color: AppColors.grisInactif,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('poulet') || lower.contains('braisé')) return '🍗';
    if (lower.contains('mafé') || lower.contains('curry')) return '🍛';
    if (lower.contains('thiébou') || lower.contains('riz')) return '🥘';
    if (lower.contains('suya') || lower.contains('viande')) return '🥩';
    if (lower.contains('poisson')) return '🐟';
    if (lower.contains('salade') || lower.contains('végé')) return '🥬';
    return '🍽️';
  }
}

// ── Forfait Card ─────────────────────────────────────────────────────────────

class _ForfaitCard extends StatelessWidget {
  const _ForfaitCard({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                ),
              ),
              Text(
                '\$${service.pricePerPerson?.toStringAsFixed(0) ?? service.price.toStringAsFixed(0)} /pers.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.catering,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Capacity
          if (service.minPersons != null || service.maxPersons != null)
            Text(
              '👥 ${service.minPersons ?? 1} — ${service.maxPersons ?? '∞'} personnes',
              style: GoogleFonts.dmSans(
                fontSize: 8,
                color: AppColors.grisInactif,
              ),
            ),
          // Menu items as tags
          if (service.menuItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: service.menuItems.take(4).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.catering.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.catering.withAlpha(38),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      color: AppColors.cateringLight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Soumission CTA ───────────────────────────────────────────────────────────

class _SoumissionCTA extends StatelessWidget {
  const _SoumissionCTA({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showTraiteurSoumissionSheet(context, proId: proId),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.5, -0.5),
            end: Alignment(0.5, 0.5),
            colors: [AppColors.catering, AppColors.cateringDark],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blanc.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demandes de soumission',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                  ),
                  Text(
                    'Devis en 24-48h · Dépôt 30%',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: AppColors.blanc.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.blanc, size: 14),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.grisInactif, size: 28),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.gris,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.violet,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
