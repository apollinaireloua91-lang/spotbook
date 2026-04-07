import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_config_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/animated_counter.dart';
import '../../data/booking_notifier.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PRO RDV SCREEN — Square/Calendly-style calendar with stats, week strip,
// time slots, and revenue chart
// ═════════════════════════════════════════════════════════════════════════════

class ProRdvScreen extends ConsumerStatefulWidget {
  const ProRdvScreen({super.key});

  @override
  ConsumerState<ProRdvScreen> createState() => _ProRdvScreenState();
}

class _ProRdvScreenState extends ConsumerState<ProRdvScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proBookingsProvider);
    final appConfig =
        ref.watch(appConfigProvider).value ?? AppConfig.fallback;
    final commissionRate = appConfig.commissionBookings;

    // Filter bookings for the selected day
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayBookings = state.bookings
        .where((b) => b.slotDate == dateStr)
        .toList()
      ..sort((a, b) =>
          (a.slotStartTime ?? '').compareTo(b.slotStartTime ?? ''));

    // Stats
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayBookings =
        state.bookings.where((b) => b.slotDate == todayStr).toList();
    final confirmedToday =
        todayBookings.where((b) => b.status == 'confirmed').length;
    final pendingToday = todayBookings
        .where(
            (b) => b.status == 'pending_payment' || b.status == 'pending')
        .length;

    // Month stats
    final monthStart = DateTime(now.year, now.month, 1);
    final monthBookings = state.bookings.where((b) {
      final d = DateTime.tryParse(b.slotDate ?? '');
      return d != null && !d.isBefore(monthStart);
    }).length;

    // Week revenue
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekBookings = state.bookings.where((b) {
      final d = DateTime.tryParse(b.slotDate ?? '');
      if (d == null) return false;
      return !d.isBefore(monday) &&
          d.isBefore(monday.add(const Duration(days: 7))) &&
          (b.status == 'confirmed' || b.status == 'completed');
    }).toList();

    final weekRevenue = weekBookings.fold<double>(
        0, (sum, b) => sum + b.totalAmount * (1 - commissionRate));

    // Weekly revenue by day for chart
    final weekData = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      final dayRev = state.bookings
          .where((b) =>
              b.slotDate == dayStr &&
              (b.status == 'confirmed' || b.status == 'completed'))
          .fold<double>(0, (sum, b) => sum + b.totalAmount * (1 - commissionRate));
      return _DailyRevenue(
        dayLabel: _shortDay(day.weekday),
        amount: dayRev,
        isToday: day.day == now.day &&
            day.month == now.month &&
            day.year == now.year,
      );
    });

    final weekClientCount = weekBookings.map((b) => b.clientName).toSet().length;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () => ref.read(proBookingsProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // ── Header ──
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.violetClair,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text('Agenda', style: AppTypography.proHubTitle),
                  const Spacer(),
                  _HeaderButton(
                    icon: Icons.event_outlined,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/create-event');
                    },
                  ),
                  const SizedBox(width: 8),
                  _HeaderButton(
                    icon: Icons.payments_outlined,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/pro/services');
                    },
                  ),
                  const SizedBox(width: 8),
                  _HeaderButton(
                    icon: Icons.tune,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/pro/availability');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Stats Row ──
              _StatsRow(
                staggerCtrl: _staggerCtrl,
                todayCount: todayBookings.length,
                confirmedCount: confirmedToday,
                pendingCount: pendingToday,
                monthCount: monthBookings,
              ),

              const SizedBox(height: 20),

              // ── Calendar Week Strip ──
              _CalendarWeekStrip(
                selectedDate: _selectedDate,
                bookings: state.bookings,
                onDateSelected: (d) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = d);
                },
              ),

              const SizedBox(height: 20),

              // ── Time Slots ──
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.violet),
                  ),
                )
              else if (dayBookings.isEmpty)
                _EmptyDayState(
                  date: _selectedDate,
                  onAddTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/pro/availability');
                  },
                )
              else
                ..._buildTimeSlots(dayBookings),

              const SizedBox(height: 24),

              // ── Revenue Section ──
              _RevenueSection(
                weekRevenue: weekRevenue,
                weekClientCount: weekClientCount,
                weekData: weekData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTimeSlots(List<BookingModel> bookings) {
    final widgets = <Widget>[];

    for (int i = 0; i < bookings.length; i++) {
      // Insert empty slot if there's a gap > 60min between bookings
      if (i > 0) {
        final prevEnd = _estimateEndTime(bookings[i - 1]);
        final currStart = _parseTime(bookings[i].slotStartTime);
        if (prevEnd != null && currStart != null) {
          final gapMinutes =
              currStart.difference(prevEnd).inMinutes;
          if (gapMinutes >= 60) {
            final gapLabel = _formatTimeOfDay(prevEnd);
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EmptySlotCard(
                  timeLabel: gapLabel,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/pro/availability');
                  },
                ),
              ),
            );
          }
        }
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TimeSlotCard(
            booking: bookings[i],
            index: i,
            onConfirm: bookings[i].status == 'pending_payment' ||
                    bookings[i].status == 'pending'
                ? () => _confirmBooking(bookings[i].id)
                : null,
            onDecline: bookings[i].status == 'pending_payment' ||
                    bookings[i].status == 'pending'
                ? () => _declineBooking(bookings[i].id)
                : null,
            onComplete: bookings[i].status == 'confirmed'
                ? () => _completeBooking(bookings[i].id)
                : null,
            onTap: () => context.push('/booking/${bookings[i].id}'),
          ),
        ),
      );
    }

    return widgets;
  }

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.length < 5) return null;
    final parts = timeStr.substring(0, 5).split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, h, m);
  }

  DateTime? _estimateEndTime(BookingModel booking) {
    final start = _parseTime(booking.slotStartTime);
    if (start == null) return null;
    final dur = booking.serviceDurationMinutes ?? 60;
    return start.add(Duration(minutes: dur));
  }

  String _formatTimeOfDay(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _shortDay(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
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
            content: Text('Booking confirmed',
                style: TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content:
                Text(e.toString(), style: const TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    }
  }

  Future<void> _completeBooking(String bookingId) async {
    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(bookingRepositoryProvider)
          .markBookingCompleted(bookingId);
      ref.invalidate(proBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('Appointment marked complete',
                style: TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content:
                Text(e.toString(), style: const TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    }
  }

  void _declineBooking(String bookingId) {
    HapticFeedback.lightImpact();
    context.push('/cancel-booking/$bookingId');
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER BUTTON
// ═════════════════════════════════════════════════════════════════════════════

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.blanc.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, color: AppColors.blanc, size: 18),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STATS ROW — 4 animated stat cards
// ═════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.staggerCtrl,
    required this.todayCount,
    required this.confirmedCount,
    required this.pendingCount,
    required this.monthCount,
  });

  final AnimationController staggerCtrl;
  final int todayCount;
  final int confirmedCount;
  final int pendingCount;
  final int monthCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
        value: todayCount,
        color: AppColors.violet,
        label: "Today's appts",
      ),
      _StatData(
        value: confirmedCount,
        color: AppColors.success,
        label: 'Confirmed',
        meta: '/ $todayCount total',
      ),
      _StatData(
        value: pendingCount,
        color: AppColors.catering,
        label: 'Pending',
        meta: 'to confirm',
      ),
      _StatData(
        value: monthCount,
        color: AppColors.rose,
        label: 'This month',
      ),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final interval = Interval(
            i * 0.1,
            0.4 + i * 0.1,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: staggerCtrl,
              curve: interval,
            )),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: staggerCtrl,
                curve: interval,
              ),
              child: _StatCard(data: cards[i]),
            ),
          );
        },
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.value,
    required this.color,
    required this.label,
    this.meta,
  });
  final int value;
  final Color color;
  final String label;
  final String? meta;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 95),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedCounter(
            value: data.value,
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: data.color,
            ),
            duration: const Duration(milliseconds: 400),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: AppColors.gris,
            ),
          ),
          if (data.meta != null) ...[
            const SizedBox(height: 2),
            Text(
              data.meta!,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.gris,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CALENDAR WEEK STRIP — 7-day strip with status dots
// ═════════════════════════════════════════════════════════════════════════════

class _CalendarWeekStrip extends StatefulWidget {
  const _CalendarWeekStrip({
    required this.selectedDate,
    required this.bookings,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<BookingModel> bookings;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_CalendarWeekStrip> createState() => _CalendarWeekStripState();
}

class _CalendarWeekStripState extends State<_CalendarWeekStrip> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getMonday(widget.selectedDate);
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final monthName = DateFormat('MMMM yyyy', 'en_US').format(_weekStart);

    return Column(
      children: [
        // Month header with arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavArrow(icon: Icons.chevron_left, onTap: _prevWeek),
            const SizedBox(width: 12),
            Text(
              monthName[0].toUpperCase() + monthName.substring(1),
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.blanc,
              ),
            ),
            const SizedBox(width: 12),
            _NavArrow(icon: Icons.chevron_right, onTap: _nextWeek),
          ],
        ),
        const SizedBox(height: 12),
        // 7-day row
        Row(
          children: days.map((day) {
            final isSelected = day.year == widget.selectedDate.year &&
                day.month == widget.selectedDate.month &&
                day.day == widget.selectedDate.day;
            final isToday = day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;

            // Get dots (status indicators for this day)
            final dayStr = DateFormat('yyyy-MM-dd').format(day);
            final dayBookings =
                widget.bookings.where((b) => b.slotDate == dayStr).toList();
            final dots = _buildDots(dayBookings);

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onDateSelected(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.violet
                        : isToday
                            ? AppColors.violet.withAlpha(38)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.violet.withAlpha(77),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _dayName(day.weekday),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: isSelected
                              ? AppColors.blanc
                              : AppColors.grisInactif,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.blanc
                              : AppColors.gris,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (dots.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dots,
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildDots(List<BookingModel> bookings) {
    if (bookings.isEmpty) return [];
    final statuses = bookings
        .map((b) => b.status)
        .toSet()
        .take(4)
        .toList();
    return statuses.map((s) {
      final color = switch (s) {
        'confirmed' => AppColors.success,
        'pending_payment' || 'pending' => AppColors.catering,
        'completed' => AppColors.violet,
        _ => AppColors.rose,
      };
      return Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }).toList();
  }

  String _dayName(int weekday) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return names[weekday - 1];
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.blanc.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.gris, size: 16),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TIME SLOT CARD — with status color bar
// ═════════════════════════════════════════════════════════════════════════════

class _TimeSlotCard extends StatelessWidget {
  const _TimeSlotCard({
    required this.booking,
    required this.index,
    required this.onTap,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
  });

  final BookingModel booking;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;

  Color get _barColor => switch (booking.status) {
        'confirmed' => AppColors.success,
        'pending_payment' || 'pending' => AppColors.catering,
        'completed' => AppColors.violet,
        _ => AppColors.rose,
      };

  String get _statusLabel => switch (booking.status) {
        'confirmed' => '✓ Confirmed',
        'pending_payment' || 'pending' => '⏳ Pending',
        'completed' => '✓ Completed',
        _ => 'Cancelled',
      };

  Color get _badgeBg => switch (booking.status) {
        'confirmed' => AppColors.success.withAlpha(31),
        'pending_payment' || 'pending' =>
          AppColors.catering.withAlpha(31),
        'completed' => AppColors.violet.withAlpha(31),
        _ => AppColors.error.withAlpha(31),
      };

  Color get _badgeText => switch (booking.status) {
        'confirmed' => AppColors.success,
        'pending_payment' || 'pending' => AppColors.catering,
        'completed' => AppColors.statusCompleted,
        _ => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final time = booking.slotStartTime != null &&
            booking.slotStartTime!.length >= 5
        ? booking.slotStartTime!.substring(0, 5)
        : '';
    final name = booking.clientName ?? 'Client';

    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 42,
            child: Text(
              time,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.grisInactif,
              ),
            ),
          ),
          // Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Color bar
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: _barColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + badge
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage:
                                      booking.clientAvatarUrl != null
                                          ? CachedNetworkImageProvider(
                                              booking.clientAvatarUrl!)
                                          : null,
                                  child: booking.clientAvatarUrl == null
                                      ? Text(
                                          name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.blanc,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.blanc,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _statusLabel,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: _badgeText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Service name
                            if (booking.serviceName != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                booking.serviceName!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.gris,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Meta: duration + price
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (booking.serviceDurationMinutes !=
                                    null) ...[
                                  const Icon(Icons.schedule,
                                      size: 11, color: AppColors.grisInactif),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${booking.serviceDurationMinutes} min',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      color: AppColors.grisInactif,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                const Icon(Icons.attach_money,
                                    size: 11, color: AppColors.grisInactif),
                                Text(
                                  '\$${booking.totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    color: AppColors.grisInactif,
                                  ),
                                ),
                              ],
                            ),
                            // Deposit / remaining status
                            if (booking.isDepositMode &&
                                (booking.status == 'confirmed' ||
                                    booking.status == 'completed')) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Deposit \$${booking.depositAmount.toStringAsFixed(0)}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: booking.isRemainingPaid
                                          ? AppColors.success.withAlpha(25)
                                          : AppColors.warning.withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      booking.isRemainingPaid
                                          ? 'Balance paid'
                                          : 'Due \$${(booking.remainingAmount ?? 0).toStringAsFixed(0)}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: booking.isRemainingPaid
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // Action buttons
                            if (onConfirm != null ||
                                onDecline != null ||
                                onComplete != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (onConfirm != null)
                                    _SlotAction(
                                      label: 'Confirm',
                                      color: AppColors.success,
                                      onTap: onConfirm!,
                                    ),
                                  if (onConfirm != null && onDecline != null)
                                    const SizedBox(width: 6),
                                  if (onDecline != null)
                                    _SlotAction(
                                      label: 'Decline',
                                      color: AppColors.error,
                                      outlined: true,
                                      onTap: onDecline!,
                                    ),
                                  if (onComplete != null)
                                    _SlotAction(
                                      label: 'Complete',
                                      color: AppColors.violet,
                                      onTap: onComplete!,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotAction extends StatelessWidget {
  const _SlotAction({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(8),
          border: outlined
              ? Border.all(color: AppColors.border, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: outlined ? color : AppColors.blanc,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY SLOT CARD — dashed border gap between bookings
// ═════════════════════════════════════════════════════════════════════════════

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard({required this.timeLabel, required this.onTap});

  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            timeLabel,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.grisInactif,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '+ Available',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.grisInactif,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY DAY STATE
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({required this.date, required this.onAddTap});

  final DateTime date;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, MMMM d', 'en_US').format(date);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 1,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available,
              color: AppColors.grisInactif, size: 32),
          const SizedBox(height: 10),
          Text(
            'No bookings on $label',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.gris,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAddTap,
            child: Text(
              '+ Manage availability',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.violet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REVENUE SECTION — with bar chart
// ═════════════════════════════════════════════════════════════════════════════

class _RevenueSection extends StatefulWidget {
  const _RevenueSection({
    required this.weekRevenue,
    required this.weekClientCount,
    required this.weekData,
  });

  final double weekRevenue;
  final int weekClientCount;
  final List<_DailyRevenue> weekData;

  @override
  State<_RevenueSection> createState() => _RevenueSectionState();
}

class _RevenueSectionState extends State<_RevenueSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.weekData
        .map((d) => d.amount)
        .fold<double>(0, (a, b) => math.max(a, b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              '💰 Revenue',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.blanc,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blanc.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This week',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.gris,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue amount
              Text(
                '\$${widget.weekRevenue.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.weekClientCount} client${widget.weekClientCount > 1 ? 's' : ''}',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.gris,
                ),
              ),
              const SizedBox(height: 14),
              // Bar chart
              SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: widget.weekData.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    final fraction =
                        maxAmount > 0 ? d.amount / maxAmount : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedBuilder(
                          animation: _barCtrl,
                          builder: (context, _) {
                            final delay = i * 0.1;
                            final progress = ((_barCtrl.value - delay) /
                                    (1 - delay))
                                .clamp(0.0, 1.0);
                            final curved =
                                Curves.easeOutBack.transform(progress);
                            return FractionallySizedBox(
                              heightFactor: fraction * curved,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: d.isToday
                                      ? AppColors.violet
                                      : AppColors.violet.withAlpha(77),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              // Day labels
              Row(
                children: widget.weekData.map((d) {
                  return Expanded(
                    child: Text(
                      d.dayLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 8,
                        color: d.isToday
                            ? AppColors.blanc
                            : AppColors.grisInactif,
                        fontWeight:
                            d.isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyRevenue {
  const _DailyRevenue({
    required this.dayLabel,
    required this.amount,
    required this.isToday,
  });
  final String dayLabel;
  final double amount;
  final bool isToday;
}
