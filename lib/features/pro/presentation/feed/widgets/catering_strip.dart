import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';

/// CTA strip for traiteur (caterer) posts.
/// Shows "Buffet africain — dès 25 $/pers." with a "Soumission" button.
class CateringStrip extends StatelessWidget {
  const CateringStrip({
    super.key,
    this.title = 'Buffet africain — dès 25 \$/pers.',
    this.onSubmission,
  });

  final String title;
  final VoidCallback? onSubmission;

  static const _orange = AppColors.catering;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cateringBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _orange.withAlpha(77), // rgba(255,140,66,0.3)
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSubmission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      color: AppColors.blanc, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Soumission',
                    style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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
