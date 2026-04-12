import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';
import '../widgets/buy_ticket_sheet.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: eventAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: TextStyle(color: AppColors.error)),
        ),
        data: (event) => _EventDetailBody(event: event),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: Column(
        children: [
          Container(height: 280, color: AppColors.surface),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 28,
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    )),
                const SizedBox(height: 16),
                Container(
                    height: 16,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    )),
                const SizedBox(height: 12),
                Container(
                    height: 16,
                    width: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    )),
                const SizedBox(height: 24),
                Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BODY
// ═════════════════════════════════════════════════════════════════════════════

class _EventDetailBody extends StatelessWidget {
  const _EventDetailBody({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      slivers: [
        // ── Hero cover image ──
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.fond,
          surfaceTintColor: Colors.transparent,
          leading: Semantics(
            label: 'Back',
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Cover image
                if (event.coverUrl != null)
                  CachedNetworkImage(
                    imageUrl: event.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.surface,
                      highlightColor: AppColors.surfaceAlt,
                      child: Container(color: AppColors.surface),
                    ),
                    errorWidget: (_, __, ___) => _coverFallback(),
                  )
                else
                  _coverFallback(),
                // Bottom gradient for text readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.fond,
                          AppColors.fond.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Content ──
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + bottomPad),
          sliver: SliverList.list(
            children: [
              // ── Title ──
              Text(
                event.title,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              // ── Date + Location info cards ──
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.violet,
                title: event.eventDate != null
                    ? DateFormat('EEEE d MMMM yyyy').format(event.eventDate!)
                    : 'Date TBD',
                subtitle: event.eventDate != null
                    ? DateFormat('HH:mm').format(event.eventDate!)
                    : null,
              ),
              const SizedBox(height: 10),
              if (event.location != null) ...[
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.locationBlue,
                  title: event.location!,
                  subtitle: event.address,
                ),
                const SizedBox(height: 10),
              ],

              // ── Organizer ──
              if (event.proName != null) ...[
                const SizedBox(height: 10),
                _OrganizerCard(event: event),
              ],

              // ── About ──
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'About',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.description!,
                  style: GoogleFonts.dmSans(
                    color: AppColors.grisClair,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],

              // ── Tickets ──
              const SizedBox(height: 28),
              Text(
                'Tickets',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (event.ticketTypes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      'No tickets available yet',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: event.ticketTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final type = event.ticketTypes[index];
                    return _TicketTypeCard(type: type, event: event);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverFallback() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(Icons.celebration_outlined,
            color: AppColors.gris.withAlpha(80), size: 64),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INFO ROW — date, location
// ═════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ORGANIZER CARD
// ═════════════════════════════════════════════════════════════════════════════

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceAlt,
            backgroundImage: event.proAvatarUrl != null
                ? CachedNetworkImageProvider(event.proAvatarUrl!)
                : null,
            child: event.proAvatarUrl == null
                ? Icon(Icons.person, color: AppColors.gris, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organized by',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.proName!,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'View',
              style: GoogleFonts.dmSans(
                color: AppColors.violet,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TICKET TYPE CARD
// ═════════════════════════════════════════════════════════════════════════════

class _TicketTypeCard extends StatelessWidget {
  const _TicketTypeCard({required this.type, required this.event});
  final TicketTypeModel type;
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final soldOut = type.isSoldOut;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: soldOut ? AppColors.border : AppColors.violet.withAlpha(30),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Ticket icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: soldOut
                  ? AppColors.gris.withAlpha(15)
                  : AppColors.violet.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: soldOut ? AppColors.gris : AppColors.violet,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),

          // Name + remaining
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  soldOut
                      ? 'Sold out'
                      : '${type.remaining} remaining',
                  style: GoogleFonts.dmSans(
                    color: soldOut ? AppColors.error : AppColors.gris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${type.price.toStringAsFixed(2)}',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'CAD',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Buy button
          GestureDetector(
            onTap: soldOut
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    showBuyTicketSheet(
                        context, ticketType: type, event: event);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: soldOut ? null : AppColors.gradientAccent,
                color: soldOut ? AppColors.surfaceAlt : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: soldOut
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Text(
                soldOut ? 'Sold out' : 'Buy',
                style: GoogleFonts.dmSans(
                  color: soldOut ? AppColors.gris : AppColors.textOnPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
