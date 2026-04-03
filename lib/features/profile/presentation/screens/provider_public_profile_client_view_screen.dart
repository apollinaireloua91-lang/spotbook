import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../reviews/domain/review_model.dart';
import '../../domain/entities/provider_profile_data.dart';
import '../bloc/public_provider_profile_bloc.dart';
import '../widgets/share_profile_modal.dart';
import '../widgets/social_badge_widget.dart';

/// Profil pro vu par le client (conversion) — route hors shell.
///
/// État : [PublicProviderProfileBloc] doit être fourni par le parent (GoRouter).
class ProviderPublicProfileClientViewScreen extends StatefulWidget {
  const ProviderPublicProfileClientViewScreen({super.key});

  @override
  State<ProviderPublicProfileClientViewScreen> createState() =>
      _ProviderPublicProfileClientViewScreenState();
}

class _ProviderPublicProfileClientViewScreenState
    extends State<ProviderPublicProfileClientViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static String _shareUrl(String providerId) =>
      'https://spotbook.app/client/provider/$providerId';

  Future<void> _openSocial(ProviderSocialLink link) async {
    final uri = _socialUri(link.platform, link.handle);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Uri? _socialUri(String platform, String handle) {
    final h = handle.replaceFirst(RegExp(r'^@'), '');
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Uri.parse('https://www.tiktok.com/@$h');
      case 'instagram':
        return Uri.parse('https://www.instagram.com/$h/');
      case 'youtube':
        return Uri.parse('https://www.youtube.com/@$h');
      case 'twitter':
      case 'x':
        return Uri.parse('https://twitter.com/$h');
      case 'facebook':
        return Uri.parse('https://www.facebook.com/$h');
      default:
        return null;
    }
  }

  ServiceEntity? _firstActiveService(PublicProviderProfileReady s) {
    for (final x in s.data.services) {
      if (x.isActive) return x;
    }
    return null;
  }

  Future<void> _onReserve(BuildContext context, PublicProviderProfileReady s) async {
    HapticFeedback.mediumImpact();
    final svc = _firstActiveService(s);
    final pid = s.data.provider.id;
    if (svc == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Aucun service réservable pour le moment.',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      context.push('/client/booking-flow/$pid?serviceId=${svc.id}');
    }
  }

  Future<void> _onMessage(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final bloc = context.read<PublicProviderProfileBloc>();
    final s = bloc.state;
    if (s is! PublicProviderProfileReady) return;
    final convId = await bloc.ensureConversationAndGetId();
    if (!context.mounted) return;
    if (convId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'Connecte-toi pour envoyer un message.',
            style: TextStyle(color: AppColors.blanc),
          ),
        ),
      );
      return;
    }
    context.push(
      '/client/messages/$convId',
      extra: <String, String>{
        'otherUserName': s.data.provider.fullName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return BlocConsumer<PublicProviderProfileBloc, PublicProviderProfileState>(
      listenWhen: (p, c) =>
          (p is PublicProviderProfileReady) != (c is PublicProviderProfileReady) ||
          c is PublicProviderProfileFailure,
      listener: (context, state) {
        if (state is PublicProviderProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surface,
              content: Text(
                state.message,
                style: const TextStyle(color: AppColors.blanc),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.fond,
          appBar: SpotbookAppBar(
            showBack: true,
            title: state is PublicProviderProfileReady
                ? state.data.provider.fullName
                : null,
            actions: state is PublicProviderProfileReady
                ? [
                    IconButton(
                      icon: const Icon(Icons.ios_share, color: AppColors.blanc),
                      tooltip: t?.share ?? 'Partager',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final p = state.data.provider;
                        showShareProfileModal(
                          context: context,
                          profileUrl: _shareUrl(p.id),
                          displayName: p.fullName,
                          avatarUrl: p.avatarUrl,
                        );
                      },
                    ),
                  ]
                : null,
          ),
          bottomNavigationBar: state is PublicProviderProfileReady
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SpotbookButton.primary(
                            label: 'Réserver',
                            onPressed: () => _onReserve(context, state),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SpotbookButton.outlined(
                            label: 'Message',
                            onPressed: () => _onMessage(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          body: switch (state) {
            PublicProviderProfileLoading() => const Center(
                child: SpotbookLoadingShimmer.profile(),
              ),
            PublicProviderProfileFailure(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.gris),
                      ),
                      const SizedBox(height: 16),
                      SpotbookButton.primary(
                        label: 'Réessayer',
                        onPressed: () {
                          final bloc = context.read<PublicProviderProfileBloc>();
                          final id = bloc.providerId;
                          if (id != null && id.isNotEmpty) {
                            bloc.add(PublicProviderProfileStarted(id));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            PublicProviderProfileReady() => _ReadyBody(
                state: state,
                tabController: _tabController,
                onBookTap: () {
                  HapticFeedback.selectionClick();
                  _tabController.animateTo(1);
                },
                onTicketTap: () {
                  HapticFeedback.selectionClick();
                  _tabController.animateTo(3);
                },
                onOpenSocial: _openSocial,
                onVideoTap: (v) {
                  HapticFeedback.lightImpact();
                  context.push('/client/profile-video', extra: v);
                },
              ),
          },
        );
      },
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.state,
    required this.tabController,
    required this.onBookTap,
    required this.onTicketTap,
    required this.onOpenSocial,
    required this.onVideoTap,
  });

  final PublicProviderProfileReady state;
  final TabController tabController;
  final VoidCallback onBookTap;
  final VoidCallback onTicketTap;
  final Future<void> Function(ProviderSocialLink) onOpenSocial;
  final void Function(VideoEntity) onVideoTap;

  @override
  Widget build(BuildContext context) {
    final p = state.data.provider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (p.coverUrl != null && p.coverUrl!.isNotEmpty)
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: p.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        height: 250,
                        child: SpotbookLoadingShimmer.card(itemCount: 1),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.gris,
                          size: 48,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      SpotbookAvatar(
                        imageUrl: p.avatarUrl,
                        name: p.fullName,
                        radius: 40,
                        isVerified: p.isVerified,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          p.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.profession,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.gris,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (p.location != null && p.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.grisClair),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                p.location!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.grisClair,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatsRow(
                    followers: p.followersCount,
                    rating: p.averageRating,
                    bookingsDone: p.bookingsCompleted,
                  ),
                ),
                if (p.bio != null && p.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      p.bio!.trim(),
                      style: const TextStyle(
                        color: AppColors.grisClair,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                if (p.socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final link in p.socialLinks)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onOpenSocial(link);
                            },
                            child: SocialIcon(
                              platform: link.platform,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _FollowButton(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.calendar_today_rounded,
                          label: 'BOOK APPT.',
                          onTap: onBookTap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.confirmation_number_outlined,
                          label: 'BUY TICKET',
                          onTap: onTicketTap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Material(
          color: AppColors.fond,
          child: TabBar(
            controller: tabController,
            labelColor: AppColors.blanc,
            unselectedLabelColor: AppColors.gris,
            indicatorColor: AppColors.violet,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            tabs: const [
              Tab(text: 'VIDÉOS'),
              Tab(text: 'SERVICES'),
              Tab(text: 'AVIS'),
              Tab(text: 'ÉVÉNEMENTS'),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: TabBarView(
            controller: tabController,
            children: [
              _VideosTab(
                videos: state.data.videos,
                onVideoTap: onVideoTap,
              ),
              _ServicesTab(
                providerId: p.id,
                services: state.data.services,
              ),
              _ReviewsTab(reviews: state.reviews),
              _EventsTab(events: state.data.events),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.followers,
    required this.rating,
    required this.bookingsDone,
  });

  final int followers;
  final double rating;
  final int bookingsDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: '$followers',
            label: 'Abonnés',
          ),
        ),
        Expanded(
          child: _StatCell(
            value: rating > 0 ? '${rating.toStringAsFixed(1)}★' : '—',
            label: 'Avis',
          ),
        ),
        Expanded(
          child: _StatCell(
            value: '$bookingsDone',
            label: 'RDV complétés',
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gris,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PublicProviderProfileBloc, PublicProviderProfileState>(
      buildWhen: (p, c) {
        if (c is! PublicProviderProfileReady || p is! PublicProviderProfileReady) {
          return true;
        }
        return p.isFollowedByMe != c.isFollowedByMe || p.followBusy != c.followBusy;
      },
      builder: (context, s) {
        if (s is! PublicProviderProfileReady) return const SizedBox.shrink();
        final authId = Supabase.instance.client.auth.currentUser?.id;
        if (authId == null) {
          return SpotbookButton.outlined(
            label: 'Connecte-toi pour suivre',
            onPressed: () => context.push('/auth/login'),
          );
        }
        if (authId == s.data.provider.id) {
          return const SizedBox.shrink();
        }
        final followed = s.isFollowedByMe;
        return SpotbookButton.primary(
          label: followed ? 'Suivi(e)' : 'Suivre',
          isLoading: s.followBusy,
          onPressed: s.followBusy
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  context
                      .read<PublicProviderProfileBloc>()
                      .add(const PublicProviderProfileToggleFollow());
                },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpotbookCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.blanc),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({
    required this.videos,
    required this.onVideoTap,
  });

  final List<VideoEntity> videos;
  final void Function(VideoEntity) onVideoTap;

  static String _formatViews(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(
        child: Text(
          'Aucune vidéo pour l’instant.',
          style: TextStyle(color: AppColors.gris),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        final v = videos[i];
        return GestureDetector(
          onTap: () => onVideoTap(v),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: v.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const SpotbookLoadingShimmer.card(itemCount: 1),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceAlt,
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: AppColors.gris,
                        ),
                      ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: AppColors.blanc,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatViews(v.viewsCount),
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({
    required this.providerId,
    required this.services,
  });

  final String providerId;
  final List<ServiceEntity> services;

  @override
  Widget build(BuildContext context) {
    final active = services.where((s) => s.isActive).toList();
    if (active.isEmpty) {
      return const Center(
        child: Text(
          'Aucun service disponible.',
          style: TextStyle(color: AppColors.gris),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: active.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = active[i];
        final price = NumberFormat.currency(symbol: r'$', decimalDigits: 0)
            .format(s.price);
        return SpotbookCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${s.durationMinutes} min · $price',
                  style: const TextStyle(color: AppColors.gris, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SpotbookButton.primary(
                  label: 'Réserver',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push(
                      '/client/booking-flow/$providerId?serviceId=${s.id}',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.reviews});

  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Center(
        child: Text(
          'Pas encore d’avis.',
          style: TextStyle(color: AppColors.gris),
        ),
      );
    }
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = reviews[i];
        return SpotbookCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpotbookAvatar(
                  imageUrl: r.clientAvatarUrl,
                  name: r.clientName ?? 'Client',
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.clientName ?? 'Client',
                              style: const TextStyle(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            fmt.format(r.createdAt),
                            style: const TextStyle(
                              color: AppColors.gris,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (si) {
                          return Icon(
                            si < r.rating ? Icons.star : Icons.star_border,
                            color: AppColors.blanc,
                            size: 16,
                          );
                        }),
                      ),
                      if (r.serviceName != null &&
                          r.serviceName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.serviceName!.trim(),
                          style: const TextStyle(
                            color: AppColors.grisClair,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (r.comment != null && r.comment!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          r.comment!.trim(),
                          style: const TextStyle(
                            color: AppColors.grisClair,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.events});

  final List<EventEntity> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Aucun événement à venir.',
          style: TextStyle(color: AppColors.gris),
        ),
      );
    }
    final fmt = DateFormat.MMMEd(Localizations.localeOf(context).toString());
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final e = events[i];
        final dateStr = e.eventDate != null ? fmt.format(e.eventDate!) : '';
        return SpotbookCard(
          padding: EdgeInsets.zero,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/event/${e.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: e.coverUrl != null && e.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: e.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                const SpotbookLoadingShimmer.card(itemCount: 1),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceAlt,
                            ),
                          )
                        : Container(color: AppColors.surfaceAlt),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppColors.gris,
                            fontSize: 13,
                          ),
                        ),
                      if (e.venueName != null && e.venueName!.isNotEmpty)
                        Text(
                          e.venueName!,
                          style: const TextStyle(
                            color: AppColors.grisClair,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gris),
              ],
            ),
          ),
        );
      },
    );
  }
}