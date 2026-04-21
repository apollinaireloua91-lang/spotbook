import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';

/// A single settings item configuration.
class SettingsItemData {
  const SettingsItemData({
    required this.icon,
    required this.label,
    this.onTap,
    this.textColor,
    this.isSpecial = false,
    this.trailing,
    this.showChevron = true,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool isSpecial;

  /// Optional trailing widget — when non-null it replaces the chevron.
  /// Useful for inline toggles (e.g. dark-mode switch) so they feel part
  /// of the settings list rather than floating in their own card.
  final Widget? trailing;

  /// Whether to render the default chevron when [trailing] is null.
  final bool showChevron;
}

/// Settings list section with tinted icon badges, dividers, and chevrons.
class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.items});

  final List<SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blanc.withAlpha(13)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SettingsItemTile(item: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: AppColors.blanc.withAlpha(10),
                indent: 62,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItemTile extends StatefulWidget {
  const _SettingsItemTile({required this.item});

  final SettingsItemData item;

  @override
  State<_SettingsItemTile> createState() => _SettingsItemTileState();
}

class _SettingsItemTileState extends State<_SettingsItemTile> {
  double _chevronOffset = 0;

  // Icon map — keep string keys to match call sites. New icons added when
  // referenced in the client profile (receipts, referrals, theme toggle).
  static const _iconMap = <String, IconData>{
    'notifications_outlined': Icons.notifications_outlined,
    'credit_card': Icons.credit_card,
    'lock_outline': Icons.lock_outline,
    'language': Icons.language,
    'star_outline': Icons.star_outline,
    'rocket_launch': Icons.rocket_launch,
    'logout': Icons.logout,
    'receipt_long': Icons.receipt_long_outlined,
    'volunteer_activism': Icons.volunteer_activism_outlined,
    'dark_mode': Icons.dark_mode_outlined,
    'light_mode': Icons.light_mode_outlined,
    'palette': Icons.palette_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final iconData = _iconMap[widget.item.icon];
    final hasTap = widget.item.onTap != null;

    return GestureDetector(
      onTap: hasTap
          ? () {
              HapticFeedback.lightImpact();
              widget.item.onTap!.call();
            }
          : null,
      onTapDown: hasTap ? (_) => setState(() => _chevronOffset = 4) : null,
      onTapUp: hasTap ? (_) => setState(() => _chevronOffset = 0) : null,
      onTapCancel: hasTap ? () => setState(() => _chevronOffset = 0) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Tinted icon tile — gives the settings list a richer, more
            // intentional feel than naked 18px icons on a flat row.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.violet.withAlpha(35),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: iconData != null
                    ? Icon(iconData, size: 17, color: AppColors.violetClair)
                    : const Icon(Icons.circle_outlined, size: 17),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.item.label,
                style: GoogleFonts.dmSans(
                  color: widget.item.textColor ?? AppColors.blanc,
                  fontSize: 14,
                  fontWeight: widget.item.isSpecial
                      ? FontWeight.w700
                      : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            if (widget.item.trailing != null)
              widget.item.trailing!
            else if (widget.item.showChevron)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(_chevronOffset, 0, 0),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.grisInactif,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
