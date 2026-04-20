import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';
import '../widgets/buy_ticket_sheet.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
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
          Container(height: 320, color: AppColors.surface),
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
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BODY — sliver scroll + sticky bottom CTA
// ═════════════════════════════════════════════════════════════════════════════

class _EventDetailBody extends StatelessWidget {
  const _EventDetailBody({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    // The primary ticket used by the sticky CTA: first non-sold-out type.
    // Sticky bar only appears when the event has at least one active type,
    // so users don't need to scroll to find a Buy button.
    final primaryTicket = event.ticketTypes
        .cast<TicketTypeModel?>()
        .firstWhere((t) => !(t?.isSoldOut ?? true), orElse: () => null);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── Hero cover image (extended, darker gradient, stacked badges)
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.fond,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: _HeroIconButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.pop();
                },
              ),
              actions: [
                _HeroIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Share integration handled by parent context if needed.
                  },
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: _HeroCover(event: event),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                // Leave room for the sticky CTA + safe area.
                (primaryTicket != null ? 112 : 32) + bottomPad,
              ),
              sliver: SliverList.list(
                children: [
                  _TitleBlock(event: event),
                  const SizedBox(height: 22),
                  _DetailsCard(event: event),
                  if (event.description != null &&
                      event.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _AboutBlock(description: event.description!),
                  ],
                  const SizedBox(height: 22),
                  _TicketsBlock(event: event),
                ],
              ),
            ),
          ],
        ),
        if (primaryTicket != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyBuyBar(
              ticket: primaryTicket,
              event: event,
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO
// ═════════════════════════════════════════════════════════════════════════════

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (event.coverUrl != null)
          CachedNetworkImage(
            imageUrl: event.coverUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surface),
            errorWidget: (_, __, ___) => const _HeroFallback(),
          )
        else
          const _HeroFallback(),
        // Darken gradient for text legibility on any cover
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.15),
                AppColors.fond,
              ],
            ),
          ),
        ),
        // Event date chip pinned bottom-left — appears over the hero so the
        // "when" is the very first thing the user reads.
        if (event.eventDate != null)
          Positioned(
            left: 20,
            bottom: 26,
            child: _HeroDateChip(date: event.eventDate!),
          ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withValues(alpha: 0.6),
            AppColors.rose.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.celebration_outlined,
          color: AppColors.textOnPrimary.withValues(alpha: 0.6),
          size: 72,
        ),
      ),
    );
  }
}

class _HeroDateChip extends StatelessWidget {
  const _HeroDateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('d').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    month,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(date),
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('HH:mm').format(date),
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TITLE
// ═════════════════════════════════════════════════════════════════════════════

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.violet.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            'EVENT',
            style: GoogleFonts.dmSans(
              color: AppColors.violetClair,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          event.title,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DETAILS CARD — unified: date, location, organizer with dividers
// ═════════════════════════════════════════════════════════════════════════════

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppColors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.event_rounded,
            iconColor: AppColors.violet,
            title: event.eventDate != null
                ? DateFormat('EEEE d MMMM yyyy').format(event.eventDate!)
                : 'Date TBD',
            subtitle: event.eventDate != null
                ? DateFormat('HH:mm').format(event.eventDate!)
                : null,
            trailing: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.gris,
              size: 18,
            ),
          ),
          if (event.location != null) ...[
            _Divider(),
            _DetailRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.locationBlue,
              title: event.location!,
              subtitle: event.address,
              trailing: Icon(
                Icons.north_east_rounded,
                color: AppColors.gris,
                size: 18,
              ),
            ),
          ],
          if (event.proName != null) ...[
            _Divider(),
            _OrganizerRow(event: event),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.border,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _OrganizerRow extends StatelessWidget {
  const _OrganizerRow({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final name = event.proName ?? 'Organizer';
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _OrganizerAvatar(
            avatarUrl: event.proAvatarUrl,
            name: name,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organized by',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/client/provider/${event.proId}');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.isDark
                      ? [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textOnPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textOnPrimary,
                      size: 14,
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

class _OrganizerAvatar extends StatelessWidget {
  const _OrganizerAvatar({required this.avatarUrl, required this.name});
  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientAccent,
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: Container(
          color: AppColors.surface,
          alignment: Alignment.center,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Text(
                    initial,
                    style: GoogleFonts.sora(
                      color: AppColors.textOnPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Text(
                    initial,
                    style: GoogleFonts.sora(
                      color: AppColors.textOnPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Text(
                  initial,
                  style: GoogleFonts.sora(
                    color: AppColors.textOnPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ABOUT
// ═════════════════════════════════════════════════════════════════════════════

class _AboutBlock extends StatefulWidget {
  const _AboutBlock({required this.description});
  final String description;

  @override
  State<_AboutBlock> createState() => _AboutBlockState();
}

class _AboutBlockState extends State<_AboutBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.description.length > 180;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'About'),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _expanded || !isLong
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: _bodyStyle,
          ),
          secondChild: Text(
            widget.description,
            style: _bodyStyle,
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Read more',
              style: GoogleFonts.dmSans(
                color: AppColors.violetClair,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  TextStyle get _bodyStyle => GoogleFonts.dmSans(
        color: AppColors.grisClair,
        fontSize: 14,
        height: 1.65,
        fontWeight: FontWeight.w400,
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TICKETS
// ═════════════════════════════════════════════════════════════════════════════

class _TicketsBlock extends StatelessWidget {
  const _TicketsBlock({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final count = event.ticketTypes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Tickets',
          trailing: count > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    count == 1 ? '1 option' : '$count options',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 14),
        if (event.ticketTypes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.gris,
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No tickets available yet',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < event.ticketTypes.length; i++) ...[
                _TicketTypeCard(type: event.ticketTypes[i], event: event),
                if (i != event.ticketTypes.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _TicketTypeCard extends StatelessWidget {
  const _TicketTypeCard({required this.type, required this.event});
  final TicketTypeModel type;
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final soldOut = type.isSoldOut;
    final progress = type.quantity > 0
        ? (type.soldCount / type.quantity).clamp(0.0, 1.0)
        : 0.0;

    return Opacity(
      opacity: soldOut ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: soldOut
                ? AppColors.border
                : AppColors.violet.withValues(alpha: 0.35),
            width: 0.8,
          ),
          boxShadow: soldOut || !AppColors.isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Left "stub" — ticket metaphor: gradient block with icon that
            // reads as a torn ticket edge when paired with the dashed seam.
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                gradient: soldOut
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.violet.withValues(alpha: 0.18),
                          AppColors.rose.withValues(alpha: 0.12),
                        ],
                      ),
                color: soldOut ? AppColors.surfaceAlt : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_rounded,
                    color: soldOut ? AppColors.gris : AppColors.violetClair,
                    size: 22,
                  ),
                ],
              ),
            ),
            // Dashed vertical seam — purely decorative, cheap to draw.
            _DashedSeam(color: AppColors.border),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.sora(
                              color: AppColors.blanc,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          CurrencyFormatter.formatAmount(
                            type.price,
                            currency: type.currency,
                          ),
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar — scarcity signal
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          soldOut ? AppColors.error : AppColors.violet,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          soldOut
                              ? Icons.block_rounded
                              : Icons.people_outline_rounded,
                          size: 13,
                          color: soldOut ? AppColors.error : AppColors.gris,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            soldOut
                                ? 'Sold out'
                                : '${type.remaining} remaining',
                            style: GoogleFonts.dmSans(
                              color: soldOut
                                  ? AppColors.error
                                  : AppColors.gris,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _BuyPill(
                          soldOut: soldOut,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            showBuyTicketSheet(
                              context,
                              ticketType: type,
                              event: event,
                            );
                          },
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
    );
  }
}

class _BuyPill extends StatelessWidget {
  const _BuyPill({required this.soldOut, required this.onTap});
  final bool soldOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: soldOut ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: soldOut ? null : AppColors.gradientAccent,
            color: soldOut ? AppColors.surfaceAlt : null,
            borderRadius: BorderRadius.circular(22),
            boxShadow: soldOut || !AppColors.isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                soldOut ? 'Sold out' : 'Buy',
                style: GoogleFonts.dmSans(
                  color: soldOut ? AppColors.gris : AppColors.textOnPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!soldOut) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textOnPrimary,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical dashed line used between a ticket card's stub and its body.
/// Lightweight — just a column of 1-height dashes, no CustomPainter needed.
class _DashedSeam extends StatelessWidget {
  const _DashedSeam({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the parent's max or fall back to a sane default when the
        // column is laid out without a bounded height.
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 100.0;
        const dashHeight = 4.0;
        const gap = 4.0;
        final dashCount = (height / (dashHeight + gap)).floor();
        return SizedBox(
          width: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: 1,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STICKY BUY BAR
// ═════════════════════════════════════════════════════════════════════════════

class _StickyBuyBar extends StatelessWidget {
  const _StickyBuyBar({required this.ticket, required this.event});
  final TicketTypeModel ticket;
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
          decoration: BoxDecoration(
            color: AppColors.fond.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'From',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatAmount(
                      ticket.price,
                      currency: ticket.currency,
                    ),
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      showBuyTicketSheet(
                        context,
                        ticketType: ticket,
                        event: event,
                      );
                    },
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.isDark
                            ? [
                                BoxShadow(
                                  color: AppColors.violet
                                      .withValues(alpha: 0.5),
                                  blurRadius: 22,
                                  spreadRadius: 0.5,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: AppColors.violet
                                      .withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.confirmation_number_rounded,
                            color: AppColors.textOnPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buy ticket',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textOnPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
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
