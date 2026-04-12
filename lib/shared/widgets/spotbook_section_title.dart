import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Titre de section overline + icône optionnelle (profil, réglages, listes).
class SpotbookSectionTitle extends StatelessWidget {
  const SpotbookSectionTitle({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 15,
            color: iconColor ?? AppColors.violetClair,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.sectionLabel,
          ),
        ),
      ],
    );
  }
}
