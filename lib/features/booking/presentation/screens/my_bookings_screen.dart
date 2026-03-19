import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientBookingsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          title: const Text(
            'Mes RDV',
            style: TextStyle(
              color: AppColors.blanc,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.blanc,
            labelColor: AppColors.blanc,
            unselectedLabelColor: AppColors.gris,
            tabs: [
              Tab(text: 'À venir'),
              Tab(text: 'Passés'),
              Tab(text: 'Annulés'),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.blanc))
            : TabBarView(
                children: [
                  _BookingsList(
                    bookings: state.upcoming,
                    emptyMessage: 'Aucun RDV à venir',
                    showCancel: true,
                  ),
                  _BookingsList(
                    bookings: state.past,
                    emptyMessage: 'Aucun RDV passé',
                  ),
                  _BookingsList(
                    bookings: state.cancelled,
                    emptyMessage: 'Aucun RDV annulé',
                  ),
                ],
              ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.bookings,
    required this.emptyMessage,
    this.showCancel = false,
  });

  final List<BookingModel> bookings;
  final String emptyMessage;
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.gris, size: 48),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(color: AppColors.gris, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(booking: booking, showCancel: showCancel);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.showCancel = false});

  final BookingModel booking;
  final bool showCancel;

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
        children: [
          Row(
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
                      booking.proName ?? 'Pro',
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      booking.serviceName ?? 'Service',
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: AppColors.gris, size: 14),
              const SizedBox(width: 6),
              Text(
                booking.slotDate ?? '',
                style: const TextStyle(color: AppColors.gris, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time,
                  color: AppColors.gris, size: 14),
              const SizedBox(width: 6),
              Text(
                booking.slotStartTime?.substring(0, 5) ?? '',
                style: const TextStyle(color: AppColors.gris, fontSize: 13),
              ),
            ],
          ),
          if (booking.bookingCode != null) ...[
            const SizedBox(height: 8),
            Text(
              booking.bookingCode!,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
          if (showCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push(
                    '/cancel-booking/${booking.id}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Annuler le RDV'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'confirmed':
        bg = AppColors.success.withAlpha(30);
        fg = AppColors.success;
        label = 'Confirmé';
      case 'pending_payment':
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
        label = 'En attente';
      case 'completed':
        bg = AppColors.gris.withAlpha(30);
        fg = AppColors.gris;
        label = 'Terminé';
      case 'cancelled_full_refund':
        bg = AppColors.error.withAlpha(30);
        fg = AppColors.error;
        label = 'Remboursé';
      case 'cancelled_no_refund':
        bg = AppColors.error.withAlpha(30);
        fg = AppColors.error;
        label = 'Annulé';
      default:
        bg = AppColors.gris.withAlpha(30);
        fg = AppColors.gris;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
