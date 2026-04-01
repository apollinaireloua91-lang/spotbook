import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'spotbook_button.dart';

class EmptyState extends StatefulWidget {
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
        subtitle:
            'Sauvegardez des pros et des vidéos pour les retrouver ici.',
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
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(curve);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curve);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône avec cercle de fond subtil
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceAlt,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40,
                      color: AppColors.gris,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (widget.ctaLabel != null && widget.onCta != null) ...[
                    const SizedBox(height: 24),
                    SpotbookButton.gradient(
                      label: widget.ctaLabel!,
                      onPressed: widget.onCta,
                      width: 200,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
