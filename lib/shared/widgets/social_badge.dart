import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SocialBadge extends StatelessWidget {
  const SocialBadge({
    super.key,
    required this.platform,
    required this.handle,
    this.followersCount = 0,
  });

  final String platform;
  final String handle;
  final int followersCount;

  IconData get _icon {
    switch (platform) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      case 'youtube':
        return Icons.play_circle_outline;
      default:
        return Icons.link;
    }
  }

  String get _formattedFollowers {
    if (followersCount < 10000) return '';
    if (followersCount < 1000000) {
      return '${(followersCount / 1000).toStringAsFixed(0)}K';
    }
    return '${(followersCount / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: AppColors.blanc),
          const SizedBox(width: 6),
          Text(
            '@$handle',
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_formattedFollowers.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              _formattedFollowers,
              style: TextStyle(
                color: AppColors.gris,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
