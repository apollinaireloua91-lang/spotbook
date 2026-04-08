import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/spotbook_colors.dart';

/// Ouvre une bottom sheet Spotbook avec animation slide + scale.
///
/// ```dart
/// showCoreBottomSheet(
///   context: context,
///   title: 'Options',
///   child: MyContent(),
/// );
/// ```
Future<T?> showCoreBottomSheet<T>({
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
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 350),
    ),
    builder: (_) => _SpotbookSheet(title: title, child: child),
  );
}

class _SpotbookSheet extends StatefulWidget {
  const _SpotbookSheet({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  State<_SpotbookSheet> createState() => _SpotbookSheetState();
}

class _SpotbookSheetState extends State<_SpotbookSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: SpotbookColors.surfaceAlt,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // ─── Handle ───
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SpotbookColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ─── Header ───
              if (widget.title != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: GoogleFonts.dmSans(
                            color: SpotbookColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.close,
                          color: SpotbookColors.textSecondary,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              // ─── Contenu ───
              Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
