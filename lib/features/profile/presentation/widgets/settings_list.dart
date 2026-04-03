import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';

/// A single settings item configuration.
class SettingsItemData {
  const SettingsItemData({
    required this.icon,
    required this.label,
    this.onTap,
    this.textColor,
    this.isSpecial = false,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool isSpecial;
}

/// Settings list section with icons and chevrons.
class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.items});

  final List<SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
                indent: 48,
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

  static const _iconMap = <String, IconData>{
    'notifications_outlined': Icons.notifications_outlined,
    'credit_card': Icons.credit_card,
    'lock_outline': Icons.lock_outline,
    'language': Icons.language,
    'star_outline': Icons.star_outline,
    'rocket_launch': Icons.rocket_launch,
    'logout': Icons.logout,
  };

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.item.textColor ?? AppColors.grisClair;
    final iconData = _iconMap[widget.item.icon];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.item.onTap?.call();
      },
      onTapDown: (_) => setState(() => _chevronOffset = 4),
      onTapUp: (_) => setState(() => _chevronOffset = 0),
      onTapCancel: () => setState(() => _chevronOffset = 0),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (iconData != null)
              Icon(iconData, size: 18, color: textColor)
            else
              Text(
                widget.item.icon,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.item.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: widget.item.isSpecial
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(_chevronOffset, 0, 0),
              child: const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.grisInactif,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
