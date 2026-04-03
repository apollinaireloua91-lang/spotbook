import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../booking/presentation/screens/booking_bottom_sheet.dart';
import '../../../events/domain/event_models.dart';
import '../../../feed/domain/video_model.dart';
import '../../domain/profile_models.dart';

String formatVideoDuration(double? seconds) {
  if (seconds == null || seconds <= 0) return '—';
  final s = seconds.round().clamp(0, 359999);
  final m = s ~/ 60;
  final r = s % 60;
  return '$m:${r.toString().padLeft(2, '0')}';
}

class VideoThumbnailCard extends StatelessWidget {
  const VideoThumbnailCard({
    super.key,
    required this.video,
    this.onTap,
  });

  final VideoModel video;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  video.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: video.thumbnailUrl!,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: AppColors.surfaceAlt,
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 40,
                            color: AppColors.gris.withValues(alpha: 0.5),
                          ),
                        ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.overlayStrong,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formatVideoDuration(video.durationSeconds),
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProServiceCard extends StatelessWidget {
  const ProServiceCard({
    super.key,
    required this.service,
    required this.proProfile,
  });

  final ServiceModel service;
  final ProProfile proProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${service.durationMinutes} min · ${service.price.toStringAsFixed(0)} €',
            style: const TextStyle(color: AppColors.gris, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SpotbookButton.primary(
            label: 'Réserver',
            onPressed: () {
              HapticFeedback.mediumImpact();
              showBookingSheet(
                context,
                proId: proProfile.id,
                proProfile: proProfile,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProEventProfileCard extends StatelessWidget {
  const ProEventProfileCard({
    super.key,
    required this.event,
  });

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.eventDate != null
        ? DateFormat.yMMMd('fr_FR').format(event.eventDate!)
        : '—';
    final priceStr = event.minPrice > 0
        ? '${event.minPrice.toStringAsFixed(0)} €'
        : 'Gratuit';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/event/${event.id}');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: event.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: event.coverUrl!,
                        fit: BoxFit.cover,
                      )
                    : const ColoredBox(
                        color: AppColors.surfaceAlt,
                        child: Icon(
                          Icons.event_outlined,
                          color: AppColors.gris,
                          size: 36,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Billet · $priceStr',
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
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
