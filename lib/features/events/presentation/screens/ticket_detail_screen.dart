import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/share_branding.dart';
import '../../domain/event_models.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.ticket});
  final TicketModel ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final isUsed = ticket.status == 'used';
    final statusColor = isUsed ? AppColors.gris : AppColors.success;
    final statusLabel = isUsed ? 'Used' : 'Valid';

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
          'Mon billet',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          Semantics(
            label: 'Partager le billet',
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Icon(Icons.share_outlined,
                    color: AppColors.blanc, size: 16),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ShareBranding.shareWithLogo(
                  text:
                      'Mon billet pour ${ticket.eventTitle ?? 'l\'événement'} — Spotbook',
                );
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Cover ──
            if (ticket.eventCoverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: ticket.eventCoverUrl!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.surface,
                    highlightColor: AppColors.surfaceAlt,
                    child: Container(height: 140, color: AppColors.surface),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 140,
                    color: AppColors.surface,
                    child:
                        Icon(Icons.event, color: AppColors.gris),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // ── Title ──
            Text(
              ticket.eventTitle ?? 'Event',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            if (ticket.ticketTypeName != null)
              Text(
                ticket.ticketTypeName!,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 24),

            // ── QR Code ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.blanc,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blanc.withAlpha(10),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ticket.qrHash != null
                  ? QrImageView(
                      data: '${ticket.id}|${ticket.qrHash}',
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: AppColors.blanc,
                    )
                  : SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: Text(
                          'QR unavailable',
                          style: GoogleFonts.dmSans(color: AppColors.gris),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // ── Status chip ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.dmSans(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Event info card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  if (ticket.eventDate != null)
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: DateFormat('EEEE d MMMM yyyy')
                          .format(ticket.eventDate!),
                    ),
                  if (ticket.eventLocation != null)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: ticket.eventLocation!,
                    ),
                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    text:
                        'Purchased ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.purchasedAt)}',
                  ),
                  if (ticket.scannedAt != null)
                    _InfoRow(
                      icon: Icons.check_circle_outline,
                      text:
                          'Scanned ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.scannedAt!)}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Add to calendar ──
            if (ticket.eventDate != null && !isUsed)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Add2Calendar.addEvent2Cal(Event(
                    title: ticket.eventTitle ?? 'Spotbook Event',
                    startDate: ticket.eventDate!,
                    endDate:
                        ticket.eventDate!.add(const Duration(hours: 3)),
                    location: ticket.eventLocation,
                  ));
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month,
                          color: AppColors.blanc, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Add to Calendar',
                        style: GoogleFonts.dmSans(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INFO ROW
// ═════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.violet, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                color: AppColors.grisClair,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
