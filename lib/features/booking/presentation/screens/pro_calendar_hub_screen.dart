import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

/// Point d'entrée onglet RDV pro : raccourcis réservation + aperçu des RDV.
class ProCalendarHubScreen extends ConsumerWidget {
  const ProCalendarHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: SpotbookAppBar(
        title: 'Agenda',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.blanc),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(proBookingsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.blanc,
        onRefresh: () => ref.read(proBookingsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'RÉSERVATION & ÉVÉNEMENTS',
                      style: TextStyle(
                        color: AppColors.gris,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _HubActionCard(
                              icon: Icons.calendar_month_outlined,
                              label: 'Disponibilités',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/pro/profile/availability');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HubActionCard(
                              icon: Icons.payments_outlined,
                              label: 'Services & tarifs',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/pro/profile/services');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SpotbookButton.outlined(
                      label: 'Create an event',
                      icon: Icons.event_outlined,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/create-event');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROCHAINS RDV',
                      style: TextStyle(
                        color: AppColors.gris,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                child: SpotbookLoadingShimmer.list(itemCount: 4),
              )
            else ...[
              if (state.upcoming.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SpotbookCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No upcoming appointments',
                            style: TextStyle(
                              color: AppColors.blanc,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure tes disponibilités et tarifs pour que les clients puissent réserver.',
                            style: TextStyle(
                              color: AppColors.gris.withValues(alpha: 0.95),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: state.upcoming.length.clamp(0, 8),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      return _UpcomingBookingTile(booking: state.upcoming[i]);
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: SpotbookButton.secondary(
                    label: 'All my bookings',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push('/pro/calendar/bookings');
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.blanc, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingBookingTile extends StatelessWidget {
  const _UpcomingBookingTile({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final name = booking.clientName ?? 'Client';
    final dateStr = booking.slotDate ?? '';
    final timeStr = booking.slotStartTime != null &&
            booking.slotStartTime!.length >= 5
        ? booking.slotStartTime!.substring(0, 5)
        : (booking.slotStartTime ?? '');
    final service = booking.serviceName ?? 'Service';
    final String subtitle;
    if (dateStr.isEmpty) {
      subtitle = timeStr.isEmpty ? service : '$timeStr · $service';
    } else {
      final parsed = DateTime.tryParse(dateStr);
      final dateLabel =
          parsed != null ? DateFormat.yMMMd('fr_CA').format(parsed) : dateStr;
      subtitle =
          timeStr.isEmpty ? '$dateLabel · $service' : '$dateLabel · $timeStr · $service';
    }

    return SpotbookCard(
      onTap: () => context.push('/pro/calendar/bookings/${booking.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceAlt,
            backgroundImage: booking.clientAvatarUrl != null
                ? CachedNetworkImageProvider(booking.clientAvatarUrl!)
                : null,
            child: booking.clientAvatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.blanc),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.gris, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gris),
        ],
      ),
    );
  }
}
