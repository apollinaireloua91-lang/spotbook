import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Show a Spotbook-styled bottom sheet.
///
/// ```dart
/// showSpotbookBottomSheet(
///   context: context,
///   title: 'Options',
///   child: MyContent(),
/// );
/// ```
Future<T?> showSpotbookBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (_) => SpotbookBottomSheet(title: title, child: child),
  );
}

/// Base bottom sheet widget with drag handle and rounded top corners.
class SpotbookBottomSheet extends StatelessWidget {
  const SpotbookBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title!,
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
            child: child,
          ),
        ],
      ),
    );
  }
}
