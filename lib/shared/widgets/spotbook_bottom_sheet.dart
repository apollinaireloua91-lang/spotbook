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
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
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
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, color: AppColors.gris),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
            child: child,
          ),
        ],
      ),
    );
  }
}
