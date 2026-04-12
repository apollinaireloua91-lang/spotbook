import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';
import 'booking_strip.dart';
import 'catering_strip.dart';
import 'event_strip.dart';

/// Left column + bottom overlay for ProFeedScreen.
/// Premium layout: Book CTA → Pro name + PRO badge → video title → CTA strip.
class PostLeftColumnPro extends StatelessWidget {
  const PostLeftColumnPro({
    super.key,
    required this.video,
    this.onBook,
  });

  final VideoModel video;

  /// When non-null, the "Réserver" CTA pill is shown (hidden on own posts).
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final v = video;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Réserver CTA (viewing another Pro's post) ──
        if (onBook != null) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBook!();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.gradientAccent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withAlpha(100),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Réserver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Pro name + PRO badge ──
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Video title ──
        if (v.title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            v.title,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 6),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

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
