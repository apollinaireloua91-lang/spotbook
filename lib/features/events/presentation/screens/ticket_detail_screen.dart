import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/event_models.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.ticket});
  final TicketModel ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsed = ticket.status == 'used';
    final statusColor = isUsed ? AppColors.gris : AppColors.success;
    final statusLabel = isUsed ? 'Utilisé' : 'Valide';

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text('My ticket', style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Semantics(
            label: 'Share ticket',
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.blanc),
              onPressed: () {
                HapticFeedback.mediumImpact();
                SharePlus.instance.share(
                  ShareParams(text: 'My ticket for ${ticket.eventTitle ?? 'the event'} — Spotbook'),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Cover
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
                    child: const Icon(Icons.event, color: AppColors.gris),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              ticket.eventTitle ?? 'Event',
              style: const TextStyle(color: AppColors.blanc, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            if (ticket.ticketTypeName != null)
              Text(ticket.ticketTypeName!, style: const TextStyle(color: AppColors.gris, fontSize: 14)),
            const SizedBox(height: 24),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blanc,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ticket.qrHash != null
                  ? QrImageView(
                      data: '${ticket.id}|${ticket.qrHash}',
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: AppColors.blanc,
                    )
                  : const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: Text('QR non disponible', style: TextStyle(color: AppColors.gris)),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            // Event info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (ticket.eventDate != null) _InfoRow(
                    icon: Icons.calendar_today,
                    text: DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(ticket.eventDate!),
                  ),
                  if (ticket.eventLocation != null) _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: ticket.eventLocation!,
                  ),
                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    text: 'Purchased on ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.purchasedAt)}',
                  ),
                  if (ticket.scannedAt != null) _InfoRow(
                    icon: Icons.check_circle_outline,
                    text: 'Scanned on ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.scannedAt!)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Add to calendar
            if (ticket.eventDate != null && !isUsed)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Add2Calendar.addEvent2Cal(Event(
                      title: ticket.eventTitle ?? 'Spotbook Event',
                      startDate: ticket.eventDate!,
                      endDate: ticket.eventDate!.add(const Duration(hours: 3)),
                      location: ticket.eventLocation,
                    ));
                  },
                  icon: const Icon(Icons.calendar_month, color: AppColors.blanc, size: 20),
                  label: const Text('Add to calendar',
                      style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gris, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.grisClair, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
