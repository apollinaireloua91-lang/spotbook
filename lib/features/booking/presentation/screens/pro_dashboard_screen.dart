import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

class ProDashboardScreen extends ConsumerWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blanc))
          : RefreshIndicator(
              color: AppColors.blanc,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  ref.read(proDashboardProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsGrid(stats: state.stats),
                  const SizedBox(height: 24),
                  const Text(
                    'Prochains RDV',
                    style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.upcomingBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Aucun RDV à venir',
                          style:
                              TextStyle(color: AppColors.gris, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.upcomingBookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _UpcomingBookingTile(
                            booking: state.upcomingBookings[index]);
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.calendar_today,
          label: 'Total RDV',
          value: '${stats['total_bookings'] ?? 0}',
        ),
        _StatCard(
          icon: Icons.upcoming,
          label: 'À venir',
          value: '${stats['upcoming'] ?? 0}',
        ),
        _StatCard(
          icon: Icons.attach_money,
          label: 'Revenus',
          value:
              '${((stats['total_revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} CA\$',
        ),
        _StatCard(
          icon: Icons.star,
          label: 'Note',
          value:
              '${((stats['average_rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} (${stats['review_count'] ?? 0})',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gris, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.gris, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBookingTile extends StatelessWidget {
  const _UpcomingBookingTile({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceAlt,
            backgroundImage: booking.proAvatarUrl != null
                ? CachedNetworkImageProvider(booking.proAvatarUrl!)
                : null,
            child: booking.proAvatarUrl == null
                ? const Icon(Icons.person, color: AppColors.gris, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName ?? 'Service',
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.bookingCode ?? '',
                  style: const TextStyle(
                      color: AppColors.gris, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking.slotDate ?? '',
                style: const TextStyle(
                    color: AppColors.blanc, fontSize: 13),
              ),
              Text(
                booking.slotStartTime?.substring(0, 5) ?? '',
                style: const TextStyle(
                    color: AppColors.gris, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
