import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/booking_notifier.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PRO RDV SCREEN — Agenda with 3 tabs, WeekStrip, Timeline, Revenue summary
// ═════════════════════════════════════════════════════════════════════════════

class ProRdvScreen extends ConsumerStatefulWidget {
  const ProRdvScreen({super.key});

  @override
  ConsumerState<ProRdvScreen> createState() => _ProRdvScreenState();
}

class _ProRdvScreenState extends ConsumerState<ProRdvScreen> {
  int _activeTab = 0; // 0=Aujourd'hui, 1=À venir, 2=Historique
  DateTime _selectedDate = DateTime.now();

  static const _tabs = ["Aujourd'hui", 'À venir', 'Historique'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () => ref.read(proBookingsProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.violetClair,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Agenda',
                        style: AppTypography.proHubTitle,
                      ),
                      const Spacer(),
                      Semantics(
                        label: 'Configurer calendrier et disponibilités',
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/pro/profile/availability');
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.blanc,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Revenue Summary Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _RevenueSummaryCard(bookings: state.bookings),
                ),
              ),

              // ── Tab bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _TabBar(
                    tabs: _tabs,
                    activeIndex: _activeTab,
                    onTap: (i) => setState(() => _activeTab = i),
                  ),
                ),
              ),

              // ── Tab content ──
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.violet),
                  ),
                )
              else
                ..._buildTabContent(state),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabContent(ClientBookingsState state) {
    switch (_activeTab) {
      case 0:
        return _buildTodayTab(state);
      case 1:
        return _buildUpcomingTab(state);
      case 2:
        return _buildHistoryTab(state);
      default:
        return [];
    }
  }

  // ── Tab 0: Aujourd'hui ──

  List<Widget> _buildTodayTab(ClientBookingsState state) {
    return [
      // Week strip
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _WeekStrip(
            selectedDate: _selectedDate,
            onDateSelected: (d) => setState(() => _selectedDate = d),
          ),
        ),
      ),
      // Timeline
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _TimelineView(
            bookings: _filterByDate(state.bookings, _selectedDate),
            onConfirm: (id) => _confirmBooking(id),
            onDecline: (id) => _declineBooking(id),
            onComplete: (id) => _completeBooking(id),
            onContact: (id) => _contactClient(id),
          ),
        ),
      ),
    ];
  }

  // ── Tab 1: À venir ──

  List<Widget> _buildUpcomingTab(ClientBookingsState state) {
    final upcoming = state.upcoming;
    if (upcoming.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(
            child: Text(
              'Aucun RDV à venir',
              style: TextStyle(color: AppColors.gris, fontSize: 14),
            ),
          ),
        ),
      ];
    }

    // Group by date
    final grouped = <String, List<BookingModel>>{};
    for (final b in upcoming) {
      final key = b.slotDate ?? 'Sans date';
      grouped.putIfAbsent(key, () => []).add(b);
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        sliver: SliverList.builder(
          itemCount: grouped.length,
          itemBuilder: (context, i) {
            final entry = grouped.entries.elementAt(i);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    _formatDateHeader(entry.key),
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                ...entry.value.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReservationSlot(
                      booking: b,
                      onConfirm: () => _confirmBooking(b.id),
                      onDecline: () => _declineBooking(b.id),
                      onComplete: () => _completeBooking(b.id),
                      onContact: () => _contactClient(b.id),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ];
  }

  // ── Tab 2: Historique ──

  List<Widget> _buildHistoryTab(ClientBookingsState state) {
    final history = [...state.past, ...state.cancelled];
    if (history.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(
            child: Text(
              'Aucun historique',
              style: TextStyle(color: AppColors.gris, fontSize: 14),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        sliver: SliverList.separated(
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _ReservationSlot(
            booking: history[i],
            onConfirm: null,
            onDecline: null,
            onComplete: null,
            onContact: null,
          ),
        ),
      ),
    ];
  }

  // ── Helpers ──

  List<BookingModel> _filterByDate(List<BookingModel> bookings, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return bookings.where((b) => b.slotDate == dateStr).toList();
  }

  String _formatDateHeader(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return DateFormat.yMMMMd('fr_CA').format(parsed).toUpperCase();
  }

  Future<void> _confirmBooking(String bookingId) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(bookingRepositoryProvider).proConfirmBooking(bookingId);
      ref.invalidate(proBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Réservation confirmée',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeBooking(String bookingId) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(bookingRepositoryProvider).markBookingCompleted(bookingId);
      ref.invalidate(proBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Rendez-vous marqué terminé',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    }
  }

  void _declineBooking(String bookingId) {
    HapticFeedback.lightImpact();
    context.push('/cancel-booking/$bookingId');
  }

  void _contactClient(String bookingId) {
    context.push('/pro/messages');
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REVENUE SUMMARY CARD
// ═════════════════════════════════════════════════════════════════════════════

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({required this.bookings});

  final List<BookingModel> bookings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = bookings.where((b) {
      return b.status == 'confirmed' || b.status == 'completed';
    }).where((b) {
      final d = DateTime.tryParse(b.slotDate ?? '');
      return d != null && d.month == now.month && d.year == now.year;
    }).toList();

    final thisWeek = thisMonth.where((b) {
      final d = DateTime.tryParse(b.slotDate ?? '');
      if (d == null) return false;
      final diff = now.difference(d).inDays;
      return diff >= 0 && diff < 7;
    }).toList();

    final monthRevenue = thisMonth.fold<double>(
        0, (sum, b) => sum + b.totalAmount * 0.88); // 12% commission
    final weekRevenue = thisWeek.fold<double>(
        0, (sum, b) => sum + b.totalAmount * 0.88);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.violetClair],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ce mois',
                  style: TextStyle(
                    color: AppColors.blanc.withAlpha(179),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${monthRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${thisMonth.length} réservation${thisMonth.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppColors.blanc.withAlpha(153),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.blanc.withAlpha(61),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cette semaine',
                    style: TextStyle(
                      color: AppColors.blanc.withAlpha(179),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${weekRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${thisWeek.length} réservation${thisWeek.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppColors.blanc.withAlpha(153),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB BAR
// ═════════════════════════════════════════════════════════════════════════════

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = i == activeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.violet : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? AppColors.blanc : AppColors.grisInactif,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WEEK STRIP — horizontal 7-day selector
// ═════════════════════════════════════════════════════════════════════════════

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    // Show 7 days starting from Monday of the current week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDateSelected(day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.violet : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.violet.withAlpha(102))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayAbbr(day.weekday),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.blanc
                          : AppColors.grisInactif,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected ? AppColors.blanc : AppColors.gris,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _dayAbbr(int weekday) {
    const abbrs = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return abbrs[weekday - 1];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TIMELINE VIEW — 30min slots
// ═════════════════════════════════════════════════════════════════════════════

class _TimelineView extends StatelessWidget {
  const _TimelineView({
    required this.bookings,
    required this.onConfirm,
    required this.onDecline,
    required this.onComplete,
    required this.onContact,
  });

  final List<BookingModel> bookings;
  final ValueChanged<String>? onConfirm;
  final ValueChanged<String>? onDecline;
  final ValueChanged<String>? onComplete;
  final ValueChanged<String>? onContact;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Center(
          child: Text(
            'Aucun RDV pour cette journée',
            style: TextStyle(color: AppColors.gris, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: bookings.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ReservationSlot(
            booking: b,
            onConfirm: b.status == 'pending_payment'
                ? () => onConfirm?.call(b.id)
                : null,
            onDecline: b.status == 'pending_payment'
                ? () => onDecline?.call(b.id)
                : null,
            onComplete: b.status == 'confirmed'
                ? () => onComplete?.call(b.id)
                : null,
            onContact: b.status == 'confirmed'
                ? () => onContact?.call(b.id)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESERVATION SLOT CARD
// ═════════════════════════════════════════════════════════════════════════════

class _ReservationSlot extends StatelessWidget {
  const _ReservationSlot({
    required this.booking,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
    this.onContact,
  });

  final BookingModel booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onContact;

  Color get _statusBorderColor {
    return switch (booking.status) {
      'confirmed' => AppColors.success,
      'pending_payment' => AppColors.violet,
      'completed' => AppColors.grisInactif,
      _ => AppColors.rose,
    };
  }

  String get _statusLabel {
    return switch (booking.status) {
      'confirmed' => 'Confirmée',
      'pending_payment' => 'En attente',
      'completed' => 'Terminée',
      'cancelled_full_refund' || 'cancelled_no_refund' => 'Annulée',
      _ => booking.status,
    };
  }

  Color get _statusBadgeColor {
    return switch (booking.status) {
      'confirmed' => AppColors.success,
      'pending_payment' => AppColors.violet,
      'completed' => AppColors.grisInactif,
      _ => AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final name = booking.clientName ?? 'Client';
    final time = booking.slotStartTime != null &&
            booking.slotStartTime!.length >= 5
        ? booking.slotStartTime!.substring(0, 5)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: _statusBorderColor, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + service + status
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceAlt,
                  backgroundImage: booking.clientAvatarUrl != null
                      ? CachedNetworkImageProvider(booking.clientAvatarUrl!)
                      : null,
                  child: booking.clientAvatarUrl == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (booking.serviceName != null)
                        Text(
                          booking.serviceName!,
                          style: const TextStyle(
                            color: AppColors.gris,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBadgeColor.withAlpha(31),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusBadgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pills: time, duration, price
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (time.isNotEmpty) _Pill(icon: Icons.schedule, text: time),
                if (booking.serviceDurationMinutes != null)
                  _Pill(
                    icon: Icons.hourglass_bottom,
                    text: '${booking.serviceDurationMinutes} min',
                  ),
                _Pill(
                  icon: Icons.attach_money,
                  text: '\$${booking.totalAmount.toStringAsFixed(0)}',
                ),
              ],
            ),

            // Actions
            if (onConfirm != null ||
                onDecline != null ||
                onComplete != null ||
                onContact != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (booking.status == 'pending_payment' &&
                        onConfirm != null) ...[
                      Expanded(
                        child: _ActionButton(
                          label: 'Confirmer',
                          color: AppColors.success,
                          icon: Icons.check,
                          onTap: onConfirm!,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (booking.status == 'pending_payment' &&
                        onDecline != null) ...[
                      Expanded(
                        child: _ActionButton(
                          label: 'Refuser',
                          color: AppColors.error,
                          textColor: AppColors.error,
                          icon: Icons.close,
                          onTap: onDecline!,
                          outlined: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (booking.status == 'confirmed') ...[
                      if (onComplete != null)
                        Expanded(
                          child: _ActionButton(
                            label: 'Terminer',
                            color: AppColors.violet,
                            icon: Icons.check_circle,
                            onTap: onComplete!,
                          ),
                        ),
                      if (onContact != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Contacter',
                            color: AppColors.surface,
                            textColor: AppColors.blanc,
                            icon: Icons.chat_bubble_outline,
                            onTap: onContact!,
                            outlined: true,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Small pill widget ────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gris, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.textColor,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final Color? textColor;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: outlined
              ? Border.all(color: AppColors.border, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor ?? AppColors.blanc, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? AppColors.blanc,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
