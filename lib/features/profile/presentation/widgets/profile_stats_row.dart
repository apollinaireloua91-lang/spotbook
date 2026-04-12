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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatItem(
                value: totalRdv,
                label: 'RDV',
                icon: Icons.calendar_today_rounded,
                color: AppColors.violet),
            _Divider(),
            _StatItem(
                value: totalFollowing,
                label: 'Abonnements',
                icon: Icons.people_outline_rounded,
                color: AppColors.rose),
            _Divider(),
            _StatItem(
                value: totalEvents,
                label: 'Événements',
                icon: Icons.confirmation_number_outlined,
                color: AppColors.violetClair),
            _Divider(),
            _StatItem(
                value: totalReviews,
                label: 'Avis',
                icon: Icons.star_outline_rounded,
                color: AppColors.starGold),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  final int value;
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color.withAlpha(120), size: 16),
            const SizedBox(height: 4),
          ],
          AnimatedCounter(
            value: value,
            style: GoogleFonts.dmSans(
              color: AppColors.blanc,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            duration: const Duration(milliseconds: 600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
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
      height: 28,
      color: AppColors.border,
    );
  }
}
