import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';

class CateringStrip extends StatelessWidget {
  const CateringStrip({
    super.key,
    required this.proId,
  });

  final String proId;

  static const _orange = AppColors.catering;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/client/pro/$proId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cateringBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _orange.withAlpha(77)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Menu traiteur disponible',
                style: TextStyle(
                  color: AppColors.blanc.withAlpha(200),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '📋 Soumission',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
