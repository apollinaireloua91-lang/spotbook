import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';

class ClientBottomInfo extends StatelessWidget {
  const ClientBottomInfo({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pro name — tappable
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: Text(
            video.proName ?? 'Pro',
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: AppColors.overlayHeavy,
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Book button — navigates to Pro public profile
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.violet,
              borderRadius: BorderRadius.circular(20),
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
        ),
      ],
    );
  }
}
