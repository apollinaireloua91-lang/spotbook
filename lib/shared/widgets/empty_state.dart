import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'spotbook_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  // Semantic factory constructors for common empty states
  factory EmptyState.noBookings({VoidCallback? onCta}) => EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Aucun rendez-vous',
        subtitle: 'Vos réservations apparaîtront ici.',
        ctaLabel: onCta != null ? 'Explorer les pros' : null,
        onCta: onCta,
      );

  factory EmptyState.noMessages({VoidCallback? onCta}) => EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Aucun message',
        subtitle: 'Vos conversations apparaîtront ici.',
        ctaLabel: onCta != null ? 'Trouver un pro' : null,
        onCta: onCta,
      );

  factory EmptyState.noFavorites({VoidCallback? onCta}) => EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun favori',
        subtitle: 'Sauvegardez des pros et des vidéos pour les retrouver ici.',
        ctaLabel: onCta != null ? 'Explorer' : null,
        onCta: onCta,
      );

  factory EmptyState.noEvents({VoidCallback? onCta}) => EmptyState(
        icon: Icons.event_outlined,
        title: 'Aucun événement',
        subtitle: 'Les événements à venir apparaîtront ici.',
        ctaLabel: onCta != null ? 'Découvrir les événements' : null,
        onCta: onCta,
      );

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.gris),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gris,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 24),
              SpotbookButton.primary(
                label: ctaLabel!,
                onPressed: onCta,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
