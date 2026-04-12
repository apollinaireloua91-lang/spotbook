import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum SnackType { success, error, info, warning }

void showSpotbookSnackBar(
  BuildContext context, {
  required String message,
  SnackType type = SnackType.info,
}) {
  final (emoji, color) = switch (type) {
    SnackType.success => ('\u2705', AppColors.success),
    SnackType.error => ('\u274C', AppColors.error),
    SnackType.warning => ('\u26A0\uFE0F', AppColors.warning),
    SnackType.info => ('\u2139\uFE0F', AppColors.violet),
  };

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withAlpha(80)),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
}
