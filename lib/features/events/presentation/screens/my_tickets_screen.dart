import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';

/// My tickets screen with "À venir" / "Passés" tabs.
/// Route: /client/bookings/tickets
class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userTicketsProvider);
    final now = DateTime.now();

    final upcoming = state.tickets
        .where((t) =>
            t.eventDate != null &&
            t.eventDate!.isAfter(now) &&
            t.status != 'used')
        .toList()
      ..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));

    final past = state.tickets
        .where((t) =>
            t.eventDate == null ||
            t.eventDate!.isBefore(now) ||
            t.status == 'used')
        .toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: SpotbookAppBar(
        title: 'Mes billets',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: AppColors.blanc,
            indicatorWeight: 2,
            labelColor: AppColors.blanc,
            unselectedLabelColor: AppColors.gris,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: 'À venir (${upcoming.length})'),
              Tab(text: 'Passés (${past.length})'),
            ],
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.violet))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _TicketList(
                  tickets: upcoming,
                  emptyIcon: Icons.confirmation_number_outlined,
                  emptyLabel: 'Aucun billet à venir',
                  emptySubLabel:
                      'Vos prochains événements apparaîtront ici.',
                  onRefresh: () =>
                      ref.read(userTicketsProvider.notifier).refresh(),
                ),
                _TicketList(
                  tickets: past,
                  emptyIcon: Icons.history,
                  emptyLabel: 'Aucun billet passé',
                  emptySubLabel: 'Vos événements passés apparaîtront ici.',
                  onRefresh: () =>
                      ref.read(userTicketsProvider.notifier).refresh(),
                ),
              ],
            ),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.tickets,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.emptySubLabel,
    required this.onRefresh,
  });

  final List<TicketModel> tickets;
  final IconData emptyIcon;
  final String emptyLabel;
  final String emptySubLabel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, color: AppColors.gris, size: 48),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style:
                    const TextStyle(color: AppColors.gris, fontSize: 15)),
            const SizedBox(height: 4),
            Text(emptySubLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.grisInactif, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.blanc,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _TicketCard(ticket: tickets[index]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final TicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final dateFmt = ticket.eventDate != null
        ? DateFormat('dd MMM yyyy · HH:mm', 'fr_FR')
            .format(ticket.eventDate!)
        : null;

    Color statusColor;
    String statusLabel;
    switch (ticket.status) {
      case 'used':
        statusColor = AppColors.gris;
        statusLabel = 'Utilisé';
      case 'valid':
        statusColor = AppColors.success;
        statusLabel = 'Valide';
      case 'refunded':
        statusColor = AppColors.warning;
        statusLabel = 'Remboursé';
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'Annulé';
      default:
        statusColor = AppColors.success;
        statusLabel = 'Valide';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/ticket-detail', extra: ticket);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Event cover
            SizedBox(
              width: 90,
              height: 100,
              child: ticket.eventCoverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ticket.eventCoverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceAlt),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.event,
                            color: AppColors.gris, size: 28),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.event,
                          color: AppColors.gris, size: 28),
                    ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.eventTitle ?? 'Événement',
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateFmt != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: AppColors.gris, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(dateFmt,
                                style: const TextStyle(
                                    color: AppColors.gris,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                    if (ticket.eventLocation != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.gris, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ticket.eventLocation!,
                              style: const TextStyle(
                                  color: AppColors.gris,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (ticket.ticketTypeName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket.ticketTypeName!,
                              style: const TextStyle(
                                  color: AppColors.gris,
                                  fontSize: 11),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right,
                  color: AppColors.gris, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
