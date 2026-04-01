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

  factory EmptyState.noVideos({VoidCallback? onCta}) => EmptyState(
        icon: Icons.videocam_outlined,
        title: 'Aucune vidéo pour le moment',
        subtitle: 'Les professionnels n\'ont pas encore publié de contenu.',
        ctaLabel: null,
        onCta: onCta,
      );

  factory EmptyState.noTickets({VoidCallback? onCta}) => EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'Aucun billet',
        subtitle: 'Vos billets d\'événements apparaîtront ici.',
        ctaLabel: onCta != null ? 'Explorer les événements' : null,
        onCta: onCta,
      );

  factory EmptyState.noNotifications() => const EmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'Aucune notification',
        subtitle: 'Vous serez notifié ici de vos réservations et messages.',
      );

  factory EmptyState.noReviews() => const EmptyState(
        icon: Icons.star_border_outlined,
        title: 'Aucun avis pour le moment',
        subtitle: 'Les avis apparaîtront ici après vos premiers services.',
      );

  factory EmptyState.noSearchResults() => const EmptyState(
        icon: Icons.search_off_outlined,
        title: 'Aucun résultat',
        subtitle: 'Essayez d\'autres termes de recherche.',
      );

  // ── Pro-specific empty states ──

  factory EmptyState.proNoBookings() => const EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Aucune réservation',
        subtitle: 'Partagez votre profil pour recevoir des clients.',
      );

  factory EmptyState.proNoVideos({VoidCallback? onCta}) => EmptyState(
        icon: Icons.videocam_outlined,
        title: 'Aucune vidéo publiée',
        subtitle: 'Publiez votre première vidéo pour attirer des clients.',
        ctaLabel: onCta != null ? 'Publier une vidéo' : null,
        onCta: onCta,
      );

  factory EmptyState.proNoEvents({VoidCallback? onCta}) => EmptyState(
        icon: Icons.event_outlined,
        title: 'Aucun événement créé',
        subtitle: 'Créez un événement pour vendre des billets.',
        ctaLabel: onCta != null ? 'Créer un événement' : null,
        onCta: onCta,
      );

  factory EmptyState.proNoServices({VoidCallback? onCta}) => EmptyState(
        icon: Icons.design_services_outlined,
        title: 'Aucun service configuré',
        subtitle: 'Ajoutez vos services pour recevoir des réservations.',
        ctaLabel: onCta != null ? 'Ajouter un service' : null,
        onCta: onCta,
      );

  factory EmptyState.proNoClients() => const EmptyState(
        icon: Icons.people_outline,
        title: 'Aucun client',
        subtitle: 'Vos clients apparaîtront ici après vos premières réservations.',
      );

  factory EmptyState.proNoRevenue() => const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Aucun revenu',
        subtitle: 'Configurez vos services pour commencer à gagner.',
      );

  factory EmptyState.proNoMessages() => const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Aucune conversation',
        subtitle: 'Vos clients vous contacteront ici.',
      );

  factory EmptyState.proNoReviews() => const EmptyState(
        icon: Icons.star_border_outlined,
        title: 'Aucun avis reçu',
        subtitle: 'Les avis apparaîtront ici après vos premiers services.',
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
