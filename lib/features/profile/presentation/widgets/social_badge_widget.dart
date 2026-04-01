import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class SocialBadgeWidget extends StatelessWidget {
  const SocialBadgeWidget({
    super.key,
    required this.platform,
    required this.followersCount,
    this.compact = false,
  });

  final String platform;
  final int followersCount;
  final bool compact;

  static String formatReach(int count) {
    if (count >= 1000000) {
      final v = count / 1000000;
      return v >= 10 ? '${v.round()}M' : '${v.toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      final v = count / 1000;
      return v >= 100 ? '${v.round()}K' : '${v.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (followersCount < 10000) return const SizedBox.shrink();

    final icon = switch (platform.toLowerCase()) {
      'instagram' => Icons.camera_alt_outlined,
      'tiktok' => Icons.music_note_outlined,
      'youtube' => Icons.play_circle_outline,
      _ => Icons.link,
    };

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.blanc),
          const SizedBox(width: 6),
          Text(
            formatReach(followersCount),
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.blanc),
          const SizedBox(width: 4),
          Text(
            formatReach(followersCount),
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
