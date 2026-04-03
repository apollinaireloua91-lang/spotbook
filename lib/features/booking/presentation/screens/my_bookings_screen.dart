import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../events/data/event_notifier.dart';
import '../../../events/domain/event_models.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/reservation_card.dart';
import '../widgets/review_sheet.dart';
import '../widgets/ticket_card.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  BookingFilter _filter = const BookingFilter();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFilterTap() {
    HapticFeedback.lightImpact();
    FilterSheet.show(
      context,
      currentFilter: _filter,
      onApply: (filter) => setState(() => _filter = filter),
    );
  }

  List<BookingModel> _applyFilter(List<BookingModel> bookings) {
    if (!_filter.isActive) return bookings;

    return bookings.where((b) {
      if (_filter.statuses.isNotEmpty && !_filter.statuses.contains(b.status)) {
        return false;
      }
      if (_filter.proName != null && _filter.proName!.isNotEmpty) {
        final name = (b.proName ?? '').toLowerCase();
        if (!name.contains(_filter.proName!.toLowerCase())) return false;
      }
      if (_filter.dateFrom != null && b.slotDate != null) {
        final d = DateTime.tryParse(b.slotDate!);
        if (d != null && d.isBefore(_filter.dateFrom!)) return false;
      }
      if (_filter.dateTo != null && b.slotDate != null) {
        final d = DateTime.tryParse(b.slotDate!);
        if (d != null && d.isAfter(_filter.dateTo!)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(clientBookingsProvider);
    final ticketsState = ref.watch(userTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'My Bookings',
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _onFilterTap,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _filter.isActive
                    ? AppColors.violet.withAlpha(30)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _filter.isActive
                      ? AppColors.violet
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 14,
                    color: _filter.isActive
                        ? AppColors.violet
                        : AppColors.gris,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Filtrer',
                    style: TextStyle(
                      color: _filter.isActive
                          ? AppColors.violet
                          : AppColors.gris,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.violet,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.blanc,
          unselectedLabelColor: AppColors.gris,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          dividerColor: AppColors.border,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('À venir'),
                  if (bookingsState.upcoming.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violet,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${bookingsState.upcoming.length}',
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Passés'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Billets'),
                  if (ticketsState.tickets.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${ticketsState.tickets.length}',
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── À venir ───
          _UpcomingTab(
            bookings: _applyFilter(bookingsState.upcoming),
            isLoading: bookingsState.isLoading,
            onRefresh: () =>
                ref.read(clientBookingsProvider.notifier).refresh(),
          ),
          // ─── Passés ───
          _PastTab(
            bookings: _applyFilter(bookingsState.past),
            isLoading: bookingsState.isLoading,
            onRefresh: () =>
                ref.read(clientBookingsProvider.notifier).refresh(),
          ),
          // ─── Billets ───
          _TicketsTab(
            tickets: ticketsState.tickets,
            isLoading: ticketsState.isLoading,
            onRefresh: () =>
                ref.read(userTicketsProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming bookings tab ──────────────────────────────────────────────────

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({
    required this.bookings,
    required this.isLoading,
    required this.onRefresh,
  });

  final List<BookingModel> bookings;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: SpotbookLoadingShimmer.card(itemCount: 4),
      );
    }

    if (bookings.isEmpty) {
      return _EmptyBookingsState(
        onRefresh: onRefresh,
        icon: Icons.calendar_month_outlined,
        title: 'No upcoming bookings',
        subtitle: 'Book a service to see\nyour appointments here',
        actionLabel: 'Discover Pros',
        onAction: () => GoRouter.of(context).go('/client/search'),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.violet,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => ReservationCard(
          booking: bookings[index],
          isUpcoming: true,
          animationDelay: Duration(milliseconds: index * 80),
        ),
      ),
    );
  }
}

// ─── Past bookings tab ──────────────────────────────────────────────────────

class _PastTab extends ConsumerWidget {
  const _PastTab({
    required this.bookings,
    required this.isLoading,
    required this.onRefresh,
  });

  final List<BookingModel> bookings;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: SpotbookLoadingShimmer.card(itemCount: 4),
      );
    }

    // Include cancelled bookings in "past" view
    if (bookings.isEmpty) {
      return _EmptyBookingsState(
        onRefresh: onRefresh,
        icon: Icons.history_rounded,
        title: 'No past bookings',
        subtitle: 'Your completed appointments\nwill appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.violet,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final booking = bookings[index];
          return ReservationCard(
            booking: booking,
            isPast: true,
            animationDelay: Duration(milliseconds: index * 80),
            onReview: () {
              HapticFeedback.lightImpact();
              ReviewSheet.show(
                context,
                bookingId: booking.id,
                proId: booking.proId,
                serviceName: booking.serviceName,
                onSubmit: (rating, comment) =>
                    ref.read(clientBookingsProvider.notifier).submitReview(
                          bookingId: booking.id,
                          proId: booking.proId,
                          rating: rating,
                          comment: comment,
                        ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Tickets tab ────────────────────────────────────────────────────────────

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({
    required this.tickets,
    required this.isLoading,
    required this.onRefresh,
  });

  final List<TicketModel> tickets;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: SpotbookLoadingShimmer.card(itemCount: 3),
      );
    }

    if (tickets.isEmpty) {
      return _EmptyBookingsState(
        onRefresh: onRefresh,
        icon: Icons.confirmation_number_outlined,
        title: 'No tickets yet',
        subtitle: 'Discover events and buy tickets\nto find them here',
        accentColor: AppColors.rose,
        actionLabel: 'Browse events',
        onAction: () => GoRouter.of(context).go('/client/search'),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.violet,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => TicketCard(
          ticket: tickets[index],
          animationDelay: Duration(milliseconds: index * 100),
        ),
      ),
    );
  }
}

// ─── Empty state (shared) ───────────────────────────────────────────────────

class _EmptyBookingsState extends StatefulWidget {
  const _EmptyBookingsState({
    required this.onRefresh,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  final Future<void> Function() onRefresh;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_EmptyBookingsState> createState() => _EmptyBookingsStateState();
}

class _EmptyBookingsStateState extends State<_EmptyBookingsState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -4).animate(
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
    final color = widget.accentColor ?? AppColors.violet;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.violet,
      backgroundColor: AppColors.surface,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _float,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _float.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withAlpha(20),
                      ),
                      child: Icon(widget.icon, size: 36, color: color),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onAction?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(50),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
