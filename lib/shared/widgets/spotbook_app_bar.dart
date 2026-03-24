import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Transparent AppBar with white title and optional back/actions.
/// Use [preferredSize] on Scaffold.appBar via [PreferredSize] or
/// simply assign this as appBar — it extends [PreferredSizeWidget].
class SpotbookAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpotbookAppBar({
    super.key,
    this.title,
    this.showBack = true,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.onBack,
  });

  final String? title;
  final bool showBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppColors.blanc,
              onPressed: onBack ?? () => context.pop(),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }
}
