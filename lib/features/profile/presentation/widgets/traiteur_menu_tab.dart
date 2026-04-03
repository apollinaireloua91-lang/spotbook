import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../booking/domain/booking_models.dart';

class TraiteurMenuTab extends StatelessWidget {
  const TraiteurMenuTab({super.key, required this.services});

  final List<ServiceModel> services;

  @override
  Widget build(BuildContext context) {
    // Collect all menu items grouped by category
    final allItems = <String, List<MenuItemModel>>{};
    for (final service in services) {
      for (final item in service.menuItems) {
        final cat = item.category ?? 'Menu';
        allItems.putIfAbsent(cat, () => []).add(item);
      }
    }

    if (allItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\uD83C\uDF7D', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Aucun menu disponible',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        for (final entry in allItems.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              entry.key.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
          for (final item in entry.value) _MenuItemCard(item: item),
        ],
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (item.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: CachedNetworkImage(
                imageUrl: item.photoUrl!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(width: 90, height: 90, color: AppColors.surfaceAlt),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.isVegetarian ||
                      item.isVegan ||
                      item.isGlutenFree) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (item.isVegetarian)
                          _DietBadge(label: 'Végétarien', emoji: '\uD83E\uDD66'),
                        if (item.isVegan)
                          _DietBadge(label: 'Végan', emoji: '\uD83C\uDF31'),
                        if (item.isGlutenFree)
                          _DietBadge(label: 'Sans gluten', emoji: '\uD83C\uDF3E'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DietBadge extends StatelessWidget {
  const _DietBadge({required this.label, required this.emoji});

  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.success,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
