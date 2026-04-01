import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  factory EmptyState.noMessages({VoidCallback? onCta}) {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'Aucun message',
      subtitle: 'Vos conversations avec les pros apparaitront ici.',
      ctaLabel: onCta != null ? 'Découvrir des pros' : null,
      onCta: onCta,
    );
  }

  factory EmptyState.noEvents({VoidCallback? onCta}) {
    return EmptyState(
      icon: Icons.confirmation_number_outlined,
      title: 'Aucun événement',
      subtitle: 'Créez votre premier événement pour commencer à vendre des billets.',
      ctaLabel: onCta != null ? 'Créer un événement' : null,
      onCta: onCta,
    );
  }

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
              TextButton(
                onPressed: onCta,
                child: Text(
                  ctaLabel!,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
