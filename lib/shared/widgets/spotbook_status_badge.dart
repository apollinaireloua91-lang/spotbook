import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BookingStatus { confirmed, pending, cancelled, completed }

class SpotbookStatusBadge extends StatelessWidget {
  const SpotbookStatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  const SpotbookStatusBadge.confirmed({super.key, this.label})
      : status = BookingStatus.confirmed;

  const SpotbookStatusBadge.pending({super.key, this.label})
      : status = BookingStatus.pending;

  const SpotbookStatusBadge.cancelled({super.key, this.label})
      : status = BookingStatus.cancelled;

  const SpotbookStatusBadge.completed({super.key, this.label})
      : status = BookingStatus.completed;

  final BookingStatus status;

  /// Override the default label. If null, uses the French default.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final text = label ?? _defaultLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.success;
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.completed:
        return AppColors.gris;
    }
  }

  String get _defaultLabel {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}
