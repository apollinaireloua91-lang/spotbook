import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/animated_counter.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

class ProDashboardScreen extends ConsumerWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            top: MediaQuery.paddingOf(context).top + 16,
            bottom: MediaQuery.paddingOf(context).bottom + 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingHeader(
                name: state.proName,
                avatarUrl: state.proAvatarUrl,
              ),
              const SizedBox(height: 20),
              _StatsCardsRow(
                stats: state.stats,
                ticketsSold: state.ticketsSold,
                revenueChange: state.revenueChange,
              ),
              const SizedBox(height: 24),
              const _QuickActions(),
              const SizedBox(height: 24),
              _UpcomingBookingsSection(
                bookings: state.upcomingBookings,
              ),
              if (state.nextEvent != null) ...[
                const SizedBox(height: 24),
                _NextEventCard(event: state.nextEvent!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Greeting Header ─────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({this.name, this.avatarUrl});

  final String? name;
  final String? avatarUrl;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceAlt,
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.gris, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gris,
                  ),
                ),
                Text(
                  name ?? 'Pro',
                  style: GoogleFonts.dmSans(
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
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.blanc, size: 24),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Cards Row ─────────────────────────────────────────

class _StatsCardsRow extends StatelessWidget {
  const _StatsCardsRow({
    required this.stats,
    required this.ticketsSold,
    this.revenueChange,
  });

  final Map<String, dynamic> stats;
  final int ticketsSold;
  final double? revenueChange;

  @override
  Widget build(BuildContext context) {
    final revenue =
        ((stats['total_revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    final bookings = stats['total_bookings'] ?? 0;
    final rating =
        ((stats['average_rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1);
    final reviewCount = stats['review_count'] ?? 0;

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _StatCard(
            icon: Icons.attach_money_rounded,
            iconColor: AppColors.success,
            label: 'Revenus',
            value: '$revenue CA\$',
            numericValue: int.tryParse(revenue),
            valueSuffix: ' CA\$',
            subtitle: revenueChange != null
                ? '${revenueChange! >= 0 ? '+' : ''}${revenueChange!.toStringAsFixed(0)}% ce mois'
                : null,
            subtitleColor:
                (revenueChange ?? 0) >= 0 ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.violet,
            label: 'Réservations',
            value: '$bookings',
            numericValue: bookings as int?,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.warning,
            label: 'Note moyenne',
            value: rating,
            subtitle: '$reviewCount avis',
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.confirmation_number_outlined,
            iconColor: AppColors.roseClair,
            label: 'Billets vendus',
            value: '$ticketsSold',
            numericValue: ticketsSold,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.numericValue,
    this.valueSuffix = '',
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final int? numericValue;
  final String valueSuffix;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final valueStyle = GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.blanc,
    );

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          if (numericValue != null)
            AnimatedCounter(
              value: numericValue!,
              suffix: valueSuffix,
              style: valueStyle,
            )
          else
            Text(value, style: valueStyle),
          const SizedBox(height: 2),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: subtitleColor ?? AppColors.gris,
              ),
            )
          else
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.gris,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIONS RAPIDES',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppColors.gris,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickActionButton(
                icon: Icons.event,
                label: 'Créer\névénement',
                color: AppColors.violet,
                onTap: () => context.push('/create-event'),
              ),
              const SizedBox(width: 10),
              _QuickActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Scanner\nbillet',
                color: AppColors.rose,
                onTap: () => context.push('/pro/scanner-picker'),
              ),
              const SizedBox(width: 10),
              _QuickActionButton(
                icon: Icons.calendar_month,
                label: 'Voir\ncalendrier',
                color: AppColors.accent,
                onTap: () => context.push('/pro/rdv'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuickActionButton(
                icon: Icons.build_outlined,
                label: 'Gérer\nservices',
                color: AppColors.violetClair,
                onTap: () => context.push('/pro/services'),
              ),
              const SizedBox(width: 10),
              _QuickActionButton(
                icon: Icons.bar_chart_rounded,
                label: 'Revenus\n& Stats',
                color: AppColors.success,
                onTap: () => context.push('/pro/revenue'),
              ),
              const SizedBox(width: 10),
              _QuickActionButton(
                icon: Icons.celebration,
                label: 'Mes\névénements',
                color: AppColors.warning,
                onTap: () => context.push('/pro/events'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: AppColors.blanc,
                ),
              ),
            ],
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
              Expanded(
                child: Text(
                  'Prochains RDV',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                ),
              ),
              if (bookings.isNotEmpty)
                GestureDetector(
                  onTap: () => context.push('/pro/rdv'),
                  child: Text(
                    'Voir tout',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.violet,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.grisInactif, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun RDV à venir',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.gris,
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
                  _BookingTile(booking: bookings[index]),
            ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

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

  String get _statusLabel {
    switch (booking.status) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return booking.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/booking/${booking.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceAlt,
                        backgroundImage: booking.clientAvatarUrl != null
                            ? CachedNetworkImageProvider(
                                booking.clientAvatarUrl!)
                            : null,
                        child: booking.clientAvatarUrl == null
                            ? const Icon(Icons.person,
                                color: AppColors.gris, size: 20)
                            : null,
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
                            const SizedBox(height: 2),
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel,
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

// ─── Next Event Card ─────────────────────────────────────────

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({required this.event});

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
          Text(
            'Prochain événement',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.blanc,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/event/$eventId'),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 140,
                        color: AppColors.surfaceAlt,
                        child: const Center(
                          child: Icon(Icons.image,
                              color: AppColors.grisInactif, size: 32),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 140,
                        color: AppColors.surfaceAlt,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: AppColors.grisInactif, size: 32),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      color: AppColors.surfaceAlt,
                      child: const Center(
                        child: Icon(Icons.event,
                            color: AppColors.grisInactif, size: 40),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blanc,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.gris, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              parsedDate != null
                                  ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
                                  : date,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.gris,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.gris, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.gris,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            top: MediaQuery.paddingOf(context).top + 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Row(
                children: [
                  const CircleAvatar(radius: 24, backgroundColor: AppColors.surface),
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
                height: 110,
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Quick actions
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 80,
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
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
                      height: 80,
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Booking tiles
              ...List.generate(
                3,
                (_) => Container(
                  height: 72,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
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
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: AppColors.gris, size: 48),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger le dashboard',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
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
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: AppColors.blanc,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
