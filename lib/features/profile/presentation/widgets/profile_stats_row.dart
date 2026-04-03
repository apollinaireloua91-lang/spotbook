import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/animated_counter.dart';

/// Client profile stats row with 4 count-up animated counters.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.totalRdv,
    required this.totalFollowing,
    required this.totalEvents,
    required this.totalReviews,
  });

  final int totalRdv;
  final int totalFollowing;
  final int totalEvents;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blanc.withAlpha(13)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatItem(value: totalRdv, label: 'RDV'),
            _Divider(),
            _StatItem(value: totalFollowing, label: 'Pros suivis'),
            _Divider(),
            _StatItem(value: totalEvents, label: 'Événements'),
            _Divider(),
            _StatItem(value: totalReviews, label: 'Avis'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedCounter(
            value: value,
            style: GoogleFonts.dmSans(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            duration: const Duration(milliseconds: 600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.blanc.withAlpha(15),
    );
  }
}
