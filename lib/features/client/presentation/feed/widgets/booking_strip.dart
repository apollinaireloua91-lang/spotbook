import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';

class BookingStrip extends StatelessWidget {
  const BookingStrip({
    super.key,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceId,
    required this.proId,
  });

  final String? serviceName;
  final double? servicePrice;
  final String serviceId;
  final String proId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/client/booking-flow/$proId?serviceId=$serviceId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.ctaBookingStripBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.violet.withAlpha(77)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    serviceName ?? 'Service',
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    servicePrice != null
                        ? 'À partir de ${servicePrice!.toStringAsFixed(0)} \$'
                        : 'Voir les tarifs',
                    style: TextStyle(
                      color: AppColors.blanc.withAlpha(136),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '📅 Réserver',
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
