import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';

class ClientBottomInfo extends StatefulWidget {
  const ClientBottomInfo({super.key, required this.video});

  final VideoModel video;

  @override
  State<ClientBottomInfo> createState() => _ClientBottomInfoState();
}

class _ClientBottomInfoState extends State<ClientBottomInfo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.video;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pro name — tappable
        GestureDetector(
          onTap: () => context.push('/pro/${v.proId}'),
          child: Text(
            v.proName ?? 'Pro',
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
        const SizedBox(height: 4),

        // Category badge
        if (v.proCategory != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.violet.withAlpha(60)),
            ),
            child: Text(
              v.proCategory!,
              style: const TextStyle(
                color: AppColors.violetClair,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Caption / description
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: _buildCaption(v),
        ),

        // Hashtags
        if (v.hashtags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: v.hashtags.map((tag) {
              final display = tag.startsWith('#') ? tag : '#$tag';
              return Text(
                display,
                style: const TextStyle(
                  color: AppColors.violet,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: AppColors.overlayHeavy,
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCaption(VideoModel v) {
    final text = v.description ?? v.title;
    if (text.isEmpty) return const SizedBox.shrink();

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              color: AppColors.blanc.withAlpha(221),
              fontSize: 11,
              height: 1.4,
              shadows: const [
                Shadow(
                  color: AppColors.overlayHeavy,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          if (!_expanded && text.length > 80)
            const TextSpan(
              text: ' voir plus',
              style: TextStyle(
                color: AppColors.violet,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      maxLines: _expanded ? 8 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
