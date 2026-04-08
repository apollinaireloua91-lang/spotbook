import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';

/// My tickets screen with Upcoming / Past tabs.
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
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          'My Tickets',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.textOnPrimary,
              unselectedLabelColor: AppColors.gris,
              labelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Upcoming (${upcoming.length})'),
                Tab(text: 'Past (${past.length})'),
              ],
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.violet))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _TicketList(
                  tickets: upcoming,
                  emptyIcon: Icons.confirmation_number_outlined,
                  emptyLabel: 'No upcoming tickets',
                  emptySubLabel: 'Your upcoming events will appear here.',
                  onRefresh: () =>
                      ref.read(userTicketsProvider.notifier).refresh(),
                ),
                _TicketList(
                  tickets: past,
                  emptyIcon: Icons.history,
                  emptyLabel: 'No past tickets',
                  emptySubLabel: 'Your past events will appear here.',
                  onRefresh: () =>
                      ref.read(userTicketsProvider.notifier).refresh(),
                ),
              ],
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TICKET LIST
// ═════════════════════════════════════════════════════════════════════════════

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, color: AppColors.violet, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                emptyLabel,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.violet,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _TicketCard(ticket: tickets[index]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TICKET CARD
// ═════════════════════════════════════════════════════════════════════════════

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final TicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final dateFmt = ticket.eventDate != null
        ? DateFormat('EEE, MMM d · HH:mm').format(ticket.eventDate!)
        : null;

    final (statusColor, statusLabel) = switch (ticket.status) {
      'used' => (AppColors.gris, 'Used'),
      'valid' => (AppColors.success, 'Valid'),
      'refunded' => (AppColors.warning, 'Refunded'),
      'cancelled' => (AppColors.error, 'Cancelled'),
      _ => (AppColors.success, 'Valid'),
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/ticket-detail', extra: ticket);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Event cover
            SizedBox(
              width: 95,
              height: 110,
              child: ticket.eventCoverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ticket.eventCoverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceAlt),
                      errorWidget: (_, __, ___) => _coverFallback(),
                    )
                  : _coverFallback(),
            ),

            // Details
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.eventTitle ?? 'Event',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateFmt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: AppColors.gris, size: 12),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              dateFmt,
                              style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (ticket.eventLocation != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: AppColors.gris, size: 12),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              ticket.eventLocation!,
                              style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (ticket.ticketTypeName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ticket.ticketTypeName!,
                              style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.dmSans(
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

            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right,
                  color: AppColors.gris, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(Icons.confirmation_number_outlined,
            color: AppColors.gris.withAlpha(100), size: 28),
      ),
    );
  }
}
