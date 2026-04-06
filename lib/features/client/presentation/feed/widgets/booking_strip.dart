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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.violet.withAlpha(64),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                serviceName ?? 'Service',
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (servicePrice != null) ...[
              const SizedBox(width: 8),
              Text(
                '${servicePrice!.toStringAsFixed(0)}\$',
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Book',
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
