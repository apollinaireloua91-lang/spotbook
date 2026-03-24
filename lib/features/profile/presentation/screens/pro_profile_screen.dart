import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../domain/entities/provider_profile_data.dart';
import '../notifiers/provider_profile_notifier.dart';

class ProProfileScreen extends ConsumerStatefulWidget {
  const ProProfileScreen({super.key, required this.proId});

  final String proId;

  @override
  ConsumerState<ProProfileScreen> createState() => _ProProfileScreenState();
}

class _ProProfileScreenState extends ConsumerState<ProProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(providerProfileNotifierProvider.notifier)
          .load(widget.proId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(providerProfileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: switch (profileState) {
        ProviderProfileInitial() || ProviderProfileLoading() => _ProfileShimmerLayout(),
        ProviderProfileLoaded(:final data) => _ProfileBody(data: data),
        ProviderProfileError(:final failure) => _ErrorView(
            message: failure.message,
            onRetry: () => ref
                .read(providerProfileNotifierProvider.notifier)
                .load(widget.proId),
          ),
      },
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _ProfileShimmerLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: const SpotbookLoadingShimmer.profile(),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gris, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Réessayer',
                style: TextStyle(color: AppColors.blanc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Body principal ───────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.data});

  final ProviderProfileData data;

  static const double _hPad = 20;
  static const double _sectionGap = 24;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                _buildAvatar(data.provider),
                const SizedBox(height: 16),
                _buildNameRow(data.provider),
                const SizedBox(height: 8),
                _buildProfessionLocation(data.provider),
                const SizedBox(height: _sectionGap),
                _buildStrategicOverview(data.provider),
                const SizedBox(height: _sectionGap),
                _buildReachAnalytics(data.provider),
                const SizedBox(height: _sectionGap),
                _buildQuickActions(context),
                const SizedBox(height: _sectionGap),
                _buildVisualStreams(context, data.videos),
                const SizedBox(height: _sectionGap),
                _buildActiveServices(context, data.services),
                const SizedBox(height: _sectionGap),
                _buildEvents(context, data.events),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.blanc),
          onPressed: () => context.push('/pro/profile/settings'),
        ),
      ],
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────

  Widget _buildAvatar(ProviderEntity p) {
    return SpotbookAvatar(
      imageUrl: p.avatarUrl,
      name: p.fullName,
      radius: 50,
      isVerified: p.isVerified,
    );
  }

  // ── Nom ───────────────────────────────────────────────────────────────────

  Widget _buildNameRow(ProviderEntity p) {
    return Text(
      p.fullName.toUpperCase(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.blanc,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Profession + Localisation ─────────────────────────────────────────────

  Widget _buildProfessionLocation(ProviderEntity p) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (p.profession.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blanc,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.profession,
              style: const TextStyle(
                color: AppColors.fond,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (p.location != null && p.location!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.gris, size: 14),
              const SizedBox(width: 3),
              Text(
                p.location!,
                style: const TextStyle(color: AppColors.gris, fontSize: 13),
              ),
            ],
          ),
      ],
    );
  }

  // ── Strategic Overview ────────────────────────────────────────────────────

  Widget _buildStrategicOverview(ProviderEntity p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'STRATEGIC OVERVIEW'),
        const SizedBox(height: 12),
        SpotbookCard(
          child: Text(
            p.bio?.isNotEmpty == true ? p.bio! : 'Aucune bio pour le moment.',
            style: const TextStyle(
              color: AppColors.gris,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Reach Analytics ───────────────────────────────────────────────────────

  Widget _buildReachAnalytics(ProviderEntity p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'REACH ANALYTICS'),
        const SizedBox(height: 12),
        SpotbookCard(
          child: Row(
            children: [
              Expanded(
                child: _StatColumn(
                  value: _formatCount(p.tiktokReach),
                  label: 'TIKTOK REACH',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _StatColumn(
                  value: _formatCount(p.igPresence),
                  label: 'IG PRESENCE',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _StatColumn(
                  value: _formatCount(p.subscribersCount),
                  label: 'SUBSCRIBERS',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Quick Actions (pro uniquement) ────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'QUICK ACTIONS'),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'CALENDRIER\n/ DISPOS',
                  onTap: () => context.push('/pro/profile/availability'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'CRÉER\nÉVÉNEMENT',
                  onTap: () => context.push('/pro/events/create'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.qr_code_outlined,
                  label: 'MON\nQR CODE',
                  onTap: () => context.push('/pro/profile/qr-code'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.confirmation_number_outlined,
                  label: 'CODES\nPROMO',
                  onTap: () => context.push('/pro/profile/promo-codes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.payments_outlined,
                  label: 'REVENUS',
                  onTap: () => context.push('/pro/revenue'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Visual Streams ────────────────────────────────────────────────────────

  Widget _buildVisualStreams(BuildContext context, List<VideoEntity> videos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel(label: 'VISUAL STREAMS'),
            Text(
              'SYS_READY',
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (videos.isEmpty)
          const _EmptyStreamHint()
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                return _VideoThumbnail(video: videos[i]);
              },
            ),
          ),
      ],
    );
  }

  // ── Active Services ───────────────────────────────────────────────────────

  Widget _buildActiveServices(
      BuildContext context, List<ServiceEntity> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel(label: 'ACTIVE SERVICES'),
            GestureDetector(
              onTap: () => context.push('/pro/profile/services'),
              child: const Text(
                'Gérer →',
                style: TextStyle(
                  color: AppColors.grisClair,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          const _EmptyHint(label: 'Aucun service actif.')
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ServiceRow(service: services[i]),
          ),
      ],
    );
  }

  // ── Mes Événements ────────────────────────────────────────────────────────

  Widget _buildEvents(BuildContext context, List<EventEntity> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel(label: 'MES ÉVÉNEMENTS'),
            GestureDetector(
              onTap: () => context.push('/pro/events'),
              child: const Text(
                'Voir tout →',
                style: TextStyle(
                  color: AppColors.grisClair,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          const _EmptyHint(label: 'Aucun événement à venir.')
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _EventRow(event: events[i], context: context),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─── Composants internes ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.gris,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 28,
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
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 48,
      color: AppColors.border,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.blanc, size: 24),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.video});
  final VideoEntity video;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 90,
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: video.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surface),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surface),
              )
            else
              Container(color: AppColors.surface),
            const Center(
              child: Icon(Icons.play_circle_outline,
                  color: AppColors.blanc, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});
  final ServiceEntity service;

  @override
  Widget build(BuildContext context) {
    final shortId =
        service.id.length >= 6 ? service.id.substring(0, 6).toUpperCase() : service.id.toUpperCase();

    return SpotbookCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: SRT-$shortId / ${service.durationMinutes} MINS',
                  style: const TextStyle(
                    color: AppColors.gris,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${service.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.context});
  final EventEntity event;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final date = event.eventDate;
    final day = date != null
        ? date.day.toString().padLeft(2, '0')
        : '--';
    final month = date != null
        ? _monthAbbr(date.month)
        : '---';

    return SpotbookCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Date block
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                day,
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                month,
                style: const TextStyle(
                  color: AppColors.gris,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 0.5, height: 40, color: AppColors.border),
          const SizedBox(width: 16),
          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (event.eventTime != null) event.eventTime!,
                    if (event.venueName != null) event.venueName!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Gérer button
          GestureDetector(
            onTap: () => context.push('/pro/events/${event.id}/edit'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'GÉRER',
                style: TextStyle(
                  color: AppColors.grisClair,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = [
      'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN',
      'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC',
    ];
    return months[m - 1];
  }
}

class _EmptyStreamHint extends StatelessWidget {
  const _EmptyStreamHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      alignment: Alignment.center,
      child: const Text(
        'Aucune vidéo publiée',
        style: TextStyle(color: AppColors.gris, fontSize: 13),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.gris, fontSize: 13),
      ),
    );
  }
}
