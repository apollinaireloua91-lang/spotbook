import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/profile_models.dart';

class SocialBadgeWidget extends StatelessWidget {
  const SocialBadgeWidget({super.key, required this.connection});

  final SocialConnection connection;

  @override
  Widget build(BuildContext context) {
    if (connection.followersCount < 10000) return const SizedBox.shrink();

    final icon = switch (connection.platform) {
      'instagram' => Icons.camera_alt_outlined, // Fallback for IG
      'tiktok' => Icons.music_note_outlined, // Fallback for TikTok
      'youtube' => Icons.play_circle_outline, // Fallback for YouTube
      _ => Icons.link,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.blanc),
          const SizedBox(width: 4),
          Text(
            _formatCount(connection.followersCount),
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

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
