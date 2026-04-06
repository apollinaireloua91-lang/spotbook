import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';

/// Bottom overlay: Pro name + Book button. Nothing else.
class ClientBottomInfo extends StatelessWidget {
  const ClientBottomInfo({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            video.proName ?? 'Pro',
            style: const TextStyle(
              color: AppColors.textOnVideo,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: AppColors.overlayHeavy,
                  blurRadius: 4,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/pro/${video.proId}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.violet,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withAlpha(102),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Book',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
