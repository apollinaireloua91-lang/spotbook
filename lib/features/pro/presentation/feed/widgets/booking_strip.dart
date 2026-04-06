import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';

/// CTA strip for service-linked posts.
/// Shows service name + price + availability, with a "Réserver" button.
class BookingStrip extends StatelessWidget {
  const BookingStrip({
    super.key,
    required this.serviceName,
    this.servicePrice,
    this.serviceNextSlot,
    this.serviceId,
    this.proId,
  });

  final String serviceName;
  final double? servicePrice;
  final String? serviceNextSlot;
  final String? serviceId;
  final String? proId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ctaBookingStripBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.violet.withAlpha(77),
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
                  serviceName,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (servicePrice != null)
                      Text(
                        '${servicePrice!.toStringAsFixed(0)} \$',
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (servicePrice != null && serviceNextSlot != null)
                      const Text(
                        '  ·  ',
                        style: TextStyle(color: AppColors.gris, fontSize: 10),
                      ),
                    if (serviceNextSlot != null)
                      Flexible(
                        child: Text(
                          serviceNextSlot!,
                          style: const TextStyle(
                            color: AppColors.gris,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (serviceId != null && proId != null) {
                context.push('/client/booking/$serviceId/$proId');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Book',
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
