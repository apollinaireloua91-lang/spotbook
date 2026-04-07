import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';
import 'booking_strip.dart';
import 'catering_strip.dart';
import 'event_strip.dart';

/// Left column + bottom overlay for ProFeedScreen.
/// Shows: Pro name + category badge, CTA strip.
class PostLeftColumnPro extends StatelessWidget {
  const PostLeftColumnPro({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final v = video;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Pro name + category badge ──
        GestureDetector(
          onTap: () => context.push('/pro/${v.proId}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  v.proName ?? 'Pro',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (v.proCategory != null) ...[
                const SizedBox(width: 8),
                _CategoryBadge(category: v.proCategory!),
              ],
            ],
          ),
        ),

        // ── CTA strip ──
        if (v.serviceName != null || v.eventName != null) ...[
          const SizedBox(height: 10),
          if (v.serviceName != null &&
              v.category?.toLowerCase() == 'traiteur')
            CateringStrip(
              title: '${v.serviceName} — from ${v.servicePrice?.toStringAsFixed(0) ?? '?'} \$/pers.',
              onSubmission: () {
                if (v.serviceId != null) {
                  context.push('/client/booking/${v.serviceId}/${v.proId}');
                }
              },
            )
          else if (v.serviceName != null)
            BookingStrip(
              serviceName: v.serviceName!,
              servicePrice: v.servicePrice,
              serviceNextSlot: v.serviceNextSlot,
              serviceId: v.serviceId,
              proId: v.proId,
            )
          else if (v.eventName != null)
            EventStrip(
              eventName: v.eventName!,
              eventDate: v.eventDate,
              eventId: v.eventId,
            ),
        ],

      ],
    );
  }
}

/// Category badge pill with semi-transparent colored background.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _colorForCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('coiffure') || lower.contains('barb')) {
      return AppColors.violet;
    }
    if (lower.contains('traiteur') || lower.contains('cater')) {
      return AppColors.catering;
    }
    if (lower.contains('événement') || lower.contains('event')) {
      return AppColors.rose;
    }
    if (lower.contains('beauté') || lower.contains('beauty') ||
        lower.contains('makeup')) {
      return AppColors.roseClair;
    }
    if (lower.contains('fitness') || lower.contains('sport') ||
        lower.contains('coach')) {
      return AppColors.success;
    }
    if (lower.contains('photo') || lower.contains('vidéo') ||
        lower.contains('video')) {
      return AppColors.infoBlue;
    }
    if (lower.contains('musique') || lower.contains('music') ||
        lower.contains('dj')) {
      return AppColors.spotifyGreen;
    }
    return AppColors.violetClair;
  }
}
