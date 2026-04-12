import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// CTA strip for service-linked posts.
/// Frosted dark glass style for premium look on video overlay.
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(30)),
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
                        color: Colors.white,
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
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (servicePrice != null && serviceNextSlot != null)
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              color: Colors.white.withAlpha(100),
                              fontSize: 10,
                            ),
                          ),
                        if (serviceNextSlot != null)
                          Flexible(
                            child: Text(
                              serviceNextSlot!,
                              style: TextStyle(
                                color: Colors.white.withAlpha(130),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Book',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
