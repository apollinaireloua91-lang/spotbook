import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/animated_counter.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

class ProDashboardScreen extends ConsumerWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final state = ref.watch(proDashboardProvider);

    if (state.isLoading) return const _DashboardShimmer();

    if (state.error != null) {
      return _ErrorView(
        error: state.error!,
        onRetry: () => ref.read(proDashboardProvider.notifier).refresh(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: RefreshIndicator(
        color: AppColors.violet,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.read(proDashboardProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 12,
            bottom: MediaQuery.paddingOf(context).bottom + 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PremiumGreetingHeader(
                name: state.proName,
                avatarUrl: state.proAvatarUrl,
              ),
              const SizedBox(height: 24),
              _PremiumStatsRow(
                stats: state.stats,
                ticketsSold: state.ticketsSold,
                revenueChange: state.revenueChange,
              ),
              const SizedBox(height: 28),
              const _PremiumQuickActions(),
              const SizedBox(height: 28),
              _UpcomingBookingsSection(
                bookings: state.upcomingBookings,
              ),
              if (state.nextEvent != null) ...[
                const SizedBox(height: 28),
                _PremiumNextEventCard(event: state.nextEvent!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium Greeting Header ─────────────────────────────────

class _PremiumGreetingHeader extends StatelessWidget {
  const _PremiumGreetingHeader({this.name, this.avatarUrl});

  final String? name;
  final String? avatarUrl;

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.greetingMorning;
    if (hour < 18) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientAccent,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.fond,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, color: AppColors.gris, size: 24)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(l),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gris,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name ?? 'Pro',
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _HeaderActionButton(
            icon: Icons.notifications_outlined,
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.blanc, size: 20),
      ),
    );
  }
}

// ─── Premium Stats Row ─────────────────────────────────────────

class _PremiumStatsRow extends StatelessWidget {
  const _PremiumStatsRow({
    required this.stats,
    required this.ticketsSold,
    this.revenueChange,
  });

  final Map<String, dynamic> stats;
  final int ticketsSold;
  final double? revenueChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final revenue =
        ((stats['total_revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    final bookings = stats['total_bookings'] ?? 0;
    final rating =
        ((stats['average_rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1);
    final reviewCount = stats['review_count'] ?? 0;

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _PremiumStatCard(
            icon: Icons.attach_money_rounded,
            gradientColors: [AppColors.success, AppColors.successLight2],
            label: l.revenue,
            numericValue: int.tryParse(revenue),
            valueSuffix: ' CA\$',
            subtitle: revenueChange != null
                ? '${revenueChange! >= 0 ? '+' : ''}${revenueChange!.toStringAsFixed(0)}% ce mois'
                : null,
            subtitleColor:
                (revenueChange ?? 0) >= 0 ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 12),
          _PremiumStatCard(
            icon: Icons.calendar_today_rounded,
            gradientColors: [AppColors.violet, AppColors.violetClair],
            label: l.reservations,
            numericValue: bookings as int?,
          ),
          const SizedBox(width: 12),
          _PremiumStatCard(
            icon: Icons.star_rounded,
            gradientColors: [AppColors.warning, AppColors.starGold],
            label: l.avgRating,
            displayValue: rating,
            subtitle: '$reviewCount avis',
          ),
          const SizedBox(width: 12),
          _PremiumStatCard(
            icon: Icons.confirmation_number_outlined,
            gradientColors: [AppColors.rose, AppColors.roseClair],
            label: l.ticketsSold,
            numericValue: ticketsSold,
          ),
        ],
      ),
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  const _PremiumStatCard({
    required this.icon,
    required this.gradientColors,
    required this.label,
    this.numericValue,
    this.displayValue,
    this.valueSuffix = '',
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final String label;
  final int? numericValue;
  final String? displayValue;
  final String valueSuffix;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final valueStyle = GoogleFonts.sora(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.blanc,
    );

    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withAlpha(30),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  gradientColors[0].withAlpha(30),
                  gradientColors[1].withAlpha(15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                colors: gradientColors,
              ).createShader(rect),
              child: Icon(icon, color: AppColors.blanc, size: 18),
            ),
          ),
          const Spacer(),
          // Value
          if (numericValue != null)
            AnimatedCounter(
              value: numericValue!,
              suffix: valueSuffix,
              style: valueStyle,
            )
          else
            Text(displayValue ?? '', style: valueStyle),
          const SizedBox(height: 2),
          // Subtitle or label
          Text(
            subtitle ?? label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor ?? AppColors.gris,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Quick Actions ───────────────────────────────────────────

class _PremiumQuickActions extends StatelessWidget {
  const _PremiumQuickActions();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.gradientAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.quickActionsHeader,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: AppColors.gris,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PremiumActionButton(
                icon: Icons.event,
                label: l.createEvent,
                gradientColors: [AppColors.violet, AppColors.violetClair],
                onTap: () => context.push('/create-event'),
              ),
              const SizedBox(width: 10),
              _PremiumActionButton(
                icon: Icons.qr_code_scanner,
                label: l.scanTicket,
                gradientColors: [AppColors.rose, AppColors.roseClair],
                onTap: () => context.push('/pro/scanner-picker'),
              ),
              const SizedBox(width: 10),
              _PremiumActionButton(
                icon: Icons.calendar_month,
                label: l.viewCalendar,
                gradientColors: [AppColors.accent, AppColors.accentCyan],
                onTap: () => context.push('/pro/rdv'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _PremiumActionButton(
                icon: Icons.build_outlined,
                label: l.manageServices,
                gradientColors: [AppColors.violetClair, AppColors.violetPastel],
                onTap: () => context.push('/pro/services'),
              ),
              const SizedBox(width: 10),
              _PremiumActionButton(
                icon: Icons.bar_chart_rounded,
                label: l.revenueAndStats,
                gradientColors: [AppColors.success, AppColors.successLight2],
                onTap: () => context.push('/pro/revenue'),
              ),
              const SizedBox(width: 10),
              _PremiumActionButton(
                icon: Icons.celebration,
                label: l.myEventsLabel,
                gradientColors: [AppColors.warning, AppColors.starGold],
                onTap: () => context.push('/pro/events'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumActionButton extends StatefulWidget {
  const _PremiumActionButton({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  State<_PremiumActionButton> createState() => _PremiumActionButtonState();
}

class _PremiumActionButtonState extends State<_PremiumActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.gradientColors[0].withAlpha(25),
              ),
            ),
            child: Column(
              children: [
                // Gradient icon
                ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(rect),
                  child: Icon(widget.icon, color: AppColors.blanc, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: AppColors.grisClair,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming Bookings Section ───────────────────────────────

class _UpcomingBookingsSection extends StatelessWidget {
  const _UpcomingBookingsSection({required this.bookings});

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
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.gradientAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.upcomingBookingsHeader,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: AppColors.gris,
                  ),
                ),
              ),
              if (bookings.isNotEmpty)
                GestureDetector(
                  onTap: () => context.push('/pro/rdv'),
                  child: Text(
                    AppLocalizations.of(context)!.viewAll,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.violet,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (bookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.calendar_today_outlined,
                          color: AppColors.gris, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.noUpcomingAppointments,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gris,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.upcomingAppointmentsHint,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.grisInactif,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) =>
                  _PremiumBookingTile(booking: bookings[index]),
            ),
        ],
      ),
    );
  }
}

class _PremiumBookingTile extends StatelessWidget {
  const _PremiumBookingTile({required this.booking});

  final BookingModel booking;

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.violet;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.gris;
    }
  }

  String _statusLabel(AppLocalizations l) {
    switch (booking.status) {
      case 'confirmed':
        return l.confirmed;
      case 'pending':
        return l.pending;
      case 'completed':
        return l.markAsDone;
      case 'cancelled':
        return l.cancel;
      default:
        return booking.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push('/booking/${booking.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status strip
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      // Client avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _statusColor.withAlpha(40),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceAlt,
                          backgroundImage: booking.clientAvatarUrl != null
                              ? CachedNetworkImageProvider(
                                  booking.clientAvatarUrl!)
                              : null,
                          child: booking.clientAvatarUrl == null
                              ? Icon(Icons.person,
                                  color: AppColors.gris, size: 20)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.clientName ?? 'Client',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blanc,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              booking.serviceName ?? 'Service',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.gris,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            booking.slotDate ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blanc,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.slotStartTime?.substring(0, 5) ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.gris,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor.withAlpha(18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _statusColor.withAlpha(30),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _statusLabel(l),
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium Next Event Card ─────────────────────────────────────

class _PremiumNextEventCard extends StatelessWidget {
  const _PremiumNextEventCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final coverUrl = event['cover_url'] as String?;
    final title = event['title'] as String? ?? '';
    final date = event['event_date'] as String? ?? '';
    final location = event['location'] as String? ?? '';
    final eventId = event['id'] as String? ?? '';

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.gradientAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.nextEventHeader,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: AppColors.gris,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/event/$eventId'),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover with gradient overlay
                  if (coverUrl != null)
                    Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: coverUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 150,
                            color: AppColors.surfaceAlt,
                            child: Center(
                              child: Icon(Icons.image,
                                  color: AppColors.grisInactif, size: 32),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 150,
                            color: AppColors.surfaceAlt,
                            child: Center(
                              child: Icon(Icons.broken_image,
                                  color: AppColors.grisInactif, size: 32),
                            ),
                          ),
                        ),
                        // Bottom gradient
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.surface.withAlpha(200),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.violet.withAlpha(20),
                            AppColors.rose.withAlpha(15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.event,
                            color: AppColors.grisInactif, size: 40),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blanc,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.violet.withAlpha(15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: AppColors.violet, size: 12),
                                  const SizedBox(width: 5),
                                  Text(
                                    parsedDate != null
                                        ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
                                        : date,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.violet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      color: AppColors.gris, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.gris,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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

// ─── Shimmer Loading State ───────────────────────────────────

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surfaceAlt,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Row(
                children: [
                  CircleAvatar(
                      radius: 26, backgroundColor: AppColors.surface),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 140,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Stats
              SizedBox(
                height: 130,
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Quick actions
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 90,
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 90,
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Booking tiles
              ...List.generate(
                3,
                (_) => Container(
                  height: 76,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error View ──────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.cloud_off,
                    color: AppColors.error, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                l.dashboardLoadError,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blanc,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.gris,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.gradientAccent,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onRetry();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.blanc,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
