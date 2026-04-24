import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';

/// Widget partagé d'affichage d'un QR code Spotbook.
///
/// Conçu pour être utilisé dans :
/// - Le détail d'une réservation client (`booking_detail_screen.dart`)
/// - L'écran plein écran scan-friendly (`booking_qr_screen.dart`)
/// - Plus tard : l'affichage des billets d'événement
///
/// Le payload [qrData] est attendu sous forme déjà préfixée :
///   - `B:{bookingId}|{qrHash}` pour un RDV
///   - `{ticketId}|{qrHash}`    pour un billet
/// Cette construction est gérée par le repo (cf. `BookingModel.qrData`).
///
/// Le widget ne gère PAS la récupération du payload — il l'affiche.
/// La séparation concerns/présentation est volontaire : le même widget
/// affiche n'importe quelle source de QR.
class QrDisplayWidget extends StatelessWidget {
  const QrDisplayWidget({
    super.key,
    required this.qrData,
    this.size = 200,
    this.title,
    this.helpText,
    this.statusBadge,
    this.onTap,
  });

  /// Payload encodé dans le QR. Voir doc de classe pour le format attendu.
  final String qrData;

  /// Taille du QR en logical pixels. 200 = compact (card), 300+ = scan-friendly.
  /// La taille du module data est calculée automatiquement par qr_flutter.
  final double size;

  /// Titre optionnel au-dessus du QR (ex: "Votre code QR").
  /// Si null, aucun titre ne s'affiche.
  final String? title;

  /// Texte d'aide sous le QR (ex: "Présentez à l'arrivée").
  /// Masqué si [statusBadge] est fourni (priorité au statut).
  final String? helpText;

  /// Badge de statut sous le QR (ex: "Déjà validé").
  /// Si fourni, remplace [helpText].
  final Widget? statusBadge;

  /// Callback au tap sur le QR. Typiquement utilisé pour ouvrir le mode
  /// plein écran depuis la version compacte.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Le QR DOIT être affiché sur fond blanc opaque même en dark mode :
    // les apps de scan calibrent leur exposition sur le contraste, et
    // un fond noir + modules noirs sur QR foncé fait échouer la
    // détection sur les caméras de gamme moyenne. C'est pour ça qu'on
    // hardcode `Colors.white` ici plutôt que d'utiliser `AppColors.surface`.
    final qrTile = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        // ErrorCorrectLevel.H = 30% redondance. Les écrans de smartphone
        // produisent souvent des reflets / moiré sur la caméra du Pro,
        // un niveau H tolère mieux les pertes que M (15%).
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (onTap != null)
          GestureDetector(onTap: onTap, child: qrTile)
        else
          qrTile,
        const SizedBox(height: 12),
        if (statusBadge != null)
          statusBadge!
        else if (helpText != null)
          Text(
            helpText!,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

/// Badge "Déjà validé" — vert avec check. Réutilisable dans les widgets
/// qui veulent afficher l'état scanné d'un QR.
class QrValidatedBadge extends StatelessWidget {
  const QrValidatedBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.success,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// État vide : QR non encore disponible (ex: paiement pas confirmé).
/// Affiché à la place du QR pour rassurer le client : il sait que le
/// QR arrive, pas que c'est cassé.
class QrUnavailablePlaceholder extends StatelessWidget {
  const QrUnavailablePlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.violetClair,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
