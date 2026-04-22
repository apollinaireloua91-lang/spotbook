import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';

/// Source unique de vérité pour la présentation d'un statut de réservation
/// (booking). Mapping `BookingModel.status` → (label humain, tint DS, type de
/// CTA primaire). Ré-utilisé par :
///  - `ReservationCard` (liste RDV client)
///  - `BookingDetailScreen` (badge top, timeline)
///
/// Règles de design importantes (cf. CLAUDE.md) :
///  - `confirmed` **n'utilise PAS** `AppColors.success` (vert). Le violet
///    de la DS est la couleur d'état positif confirmé.
///  - `cancelled_*` utilise `AppColors.error` avec `withAlpha(200)` (rouge
///    atténué), jamais pur.
///  - Aucun emoji, aucun point d'exclamation dans les labels.
class BookingStatusPresentation {
  const BookingStatusPresentation({
    required this.label,
    required this.tint,
    required this.primaryCta,
  });

  final String label;
  final Color tint;
  final BookingPrimaryCta primaryCta;
}

/// Type de CTA primaire attendu pour un status donné. L'appelant décide quoi
/// afficher concrètement (label + route) — ce presenter ne dicte que
/// l'intention métier.
enum BookingPrimaryCta {
  /// Finaliser le paiement (retourner au PaymentSheet / flow paiement).
  payNow,

  /// Ouvrir la messagerie avec le pro/client.
  message,

  /// Laisser un avis (status `completed`, côté client).
  leaveReview,

  /// Voir détails uniquement (bookings annulés, pas d'action métier).
  viewDetails,

  /// Pas de CTA primaire (états transitoires ou inconnus).
  none,
}

BookingStatusPresentation presentBookingStatus(
  String status,
  AppLocalizations l,
) {
  switch (status) {
    case 'pending_payment':
      return BookingStatusPresentation(
        label: l.statusPaymentPending,
        tint: AppColors.warning,
        primaryCta: BookingPrimaryCta.payNow,
      );
    case 'confirmed':
      return BookingStatusPresentation(
        label: l.confirmed,
        tint: AppColors.violet,
        primaryCta: BookingPrimaryCta.message,
      );
    case 'completed':
      return BookingStatusPresentation(
        label: l.statusCompleted,
        // Terminé = violet atténué (30% alpha) pour différencier de confirmed
        // sans quitter la palette.
        tint: AppColors.violet.withAlpha(180),
        primaryCta: BookingPrimaryCta.leaveReview,
      );
    case 'cancelled_full_refund':
    case 'cancelled_no_refund':
    case 'rejected':
      return BookingStatusPresentation(
        label: l.statusCancelled,
        tint: AppColors.error.withAlpha(200),
        primaryCta: BookingPrimaryCta.viewDetails,
      );
    case 'payment_failed':
      return BookingStatusPresentation(
        label: l.statusPaymentPending,
        tint: AppColors.error.withAlpha(200),
        primaryCta: BookingPrimaryCta.payNow,
      );
    default:
      return BookingStatusPresentation(
        label: status,
        tint: AppColors.gris,
        primaryCta: BookingPrimaryCta.none,
      );
  }
}
