import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';

/// CTA strip for event-linked posts.
/// Shows event name + date, with an "Acheter" button.
class EventStrip extends StatelessWidget {
  const EventStrip({
    super.key,
    required this.eventName,
    this.eventDate,
    this.eventId,
  });

  final String eventName;
  final String? eventDate;
  final String? eventId;

  static const _stripBg = Color(0xE61E0532); // rgba(30,5,50,0.9)

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _stripBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.rose.withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventName,
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
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (eventId != null) {
                context.push('/event/$eventId');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.rose,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Acheter',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 11,
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
