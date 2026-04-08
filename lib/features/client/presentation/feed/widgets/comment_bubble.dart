import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/utils/time_ago.dart';
import '../../../../feed/domain/video_model.dart';

class CommentBubble extends StatelessWidget {
  const CommentBubble({
    super.key,
    required this.comment,
    required this.isLiked,
    required this.onLikeTap,
    required this.onReplyTap,
  });

  final CommentModel comment;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onReplyTap;

  @override
  Widget build(BuildContext context) {
    final initial = (comment.userName ?? 'U').isNotEmpty
        ? (comment.userName ?? 'U')[0].toUpperCase()
        : 'U';

    // Deterministic color from name
    final hue = (comment.userName?.hashCode ?? 0) % 360;
    final avatarColor = HSLColor.fromAHSL(1.0, hue.abs().toDouble(), 0.6, 0.45).toColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: avatarColor.withAlpha(80),
            child: Text(
              initial,
              style: TextStyle(
                color: avatarColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.userName ?? 'Utilisateur',
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comment.content,
                    style: TextStyle(
                      color: AppColors.blanc.withAlpha(170),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Actions row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onLikeTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 12,
                              color: isLiked ? AppColors.rose : AppColors.gris,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${comment.likeCount}',
                              style: TextStyle(
                                color: isLiked ? AppColors.rose : AppColors.gris,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: onReplyTap,
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: AppColors.gris,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeAgo(comment.createdAt),
                        style: TextStyle(
                          color: AppColors.grisInactif,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
