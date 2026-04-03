import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';

class EventStrip extends StatelessWidget {
  const EventStrip({
    super.key,
    required this.eventName,
    required this.eventDate,
    required this.eventId,
  });

  final String? eventName;
  final String? eventDate;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/client/event/$eventId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.ctaEventStripBg.withAlpha(230),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.rose.withAlpha(77)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eventName ?? 'Événement',
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (eventDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      eventDate!,
                      style: TextStyle(
                        color: AppColors.blanc.withAlpha(136),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.rose,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🎟 Acheter',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
