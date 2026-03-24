import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

class ProDashboardScreen extends ConsumerWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proDashboardProvider);
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final firstName =
        ((meta?['full_name'] as String?) ?? '').split(' ').firstOrNull ?? 'Pro';
    final avatarUrl = meta?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.fond,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/pro/events/create'),
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.fond,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.blanc))
            : RefreshIndicator(
                color: AppColors.blanc,
                backgroundColor: AppColors.surface,
                onRefresh: () =>
                    ref.read(proDashboardProvider.notifier).refresh(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                        child: _Header(
                            firstName: firstName, avatarUrl: avatarUrl)),
                    SliverToBoxAdapter(
                        child: _StatsRow(stats: state.stats)),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(child: _QuickActions()),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                        child: _UpcomingSection(
                            bookings: state.upcomingBookings)),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.avatarUrl});
  final String firstName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $firstName',
                    style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3)),
                const SizedBox(height: 2),
                const Text('Votre résumé du jour',
                    style: TextStyle(color: AppColors.gris, fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.surface, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.blanc, size: 20),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push('/pro/profile'),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceAlt,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.gris, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ──────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final revenue =
        ((stats['total_revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    final bookings = stats['total_bookings'] as int? ?? 0;
    final rating =
        ((stats['average_rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1);
    final upcoming = stats['upcoming'] as int? ?? 0;

    return SizedBox(
      height: 120,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(label: 'Revenus mois', value: '$revenue CA\$',
              icon: Icons.payments_outlined),
          const SizedBox(width: 10),
          _StatCard(label: 'RDV total', value: '$bookings',
              icon: Icons.calendar_today_outlined),
          const SizedBox(width: 10),
          _StatCard(label: 'À venir', value: '$upcoming',
              icon: Icons.upcoming_outlined),
          const SizedBox(width: 10),
          _StatCard(label: 'Note moy.', value: '★ $rating',
              icon: Icons.star_outline),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.gris, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5)),
          Text(label,
              style: const TextStyle(color: AppColors.gris, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Quick actions ───────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions rapides',
              style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/pro/events/create'),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                        color: AppColors.blanc,
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.all(14),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event, color: AppColors.fond, size: 22),
                        SizedBox(height: 6),
                        Text('Créer un événement',
                            style: TextStyle(
                                color: AppColors.fond,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => context.push('/pro/scanner'),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: AppColors.blanc, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push('/pro/calendar'),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      color: AppColors.blanc, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('Voir le calendrier',
                          style: TextStyle(
                              color: AppColors.blanc,
                              fontSize: 14,
                              fontWeight: FontWeight.w600))),
                  Icon(Icons.chevron_right,
                      color: AppColors.gris, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming bookings ───────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.bookings});
  final List<BookingModel> bookings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Prochains RDV',
                    style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                onTap: () => context.push('/pro/calendar'),
                child: const Text('Tout voir',
                    style:
                        TextStyle(color: AppColors.gris, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            SpotbookCard(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun RDV à venir',
                      style:
                          TextStyle(color: AppColors.gris, fontSize: 14)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _BookingTile(booking: bookings[i]),
            ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return SpotbookCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceAlt,
            backgroundImage: booking.clientAvatarUrl != null
                ? CachedNetworkImageProvider(booking.clientAvatarUrl!)
                : null,
            child: booking.clientAvatarUrl == null
                ? const Icon(Icons.person, color: AppColors.gris, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.serviceName ?? 'Service',
                    style: const TextStyle(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(booking.clientName ?? booking.bookingCode ?? '',
                    style: const TextStyle(
                        color: AppColors.gris, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(booking.slotDate ?? '',
                  style: const TextStyle(
                      color: AppColors.blanc, fontSize: 13)),
              const SizedBox(height: 2),
              Text(booking.slotStartTime?.substring(0, 5) ?? '',
                  style: const TextStyle(
                      color: AppColors.gris, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
