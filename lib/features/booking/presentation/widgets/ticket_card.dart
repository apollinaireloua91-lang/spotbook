import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../events/domain/event_models.dart';

/// A ticket card that flips in 3D to reveal an enlarged QR code.
class TicketCard extends StatefulWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    this.animationDelay = Duration.zero,
  });

  final TicketModel ticket;
  final Duration animationDelay;

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late final AnimationController _appearController;
  late final Animation<double> _appearFade;
  late final Animation<double> _appearSlide;

  bool _showFront = true;

  @override
  void initState() {
    super.initState();

    // Flip animation
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
    _flipAnimation.addListener(() {
      // Swap faces at the halfway point
      final newShowFront = _flipAnimation.value < pi / 2;
      if (newShowFront != _showFront) {
        setState(() => _showFront = newShowFront);
      }
    });

    // Staggered appear animation
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _appearFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
    );
    _appearSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.animationDelay, () {
      if (mounted) _appearController.forward();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final statusStyle = _ticketStatusStyle(t.status);

    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _appearSlide.value),
          child: Opacity(opacity: _appearFade.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: _toggleFlip,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, _) {
            final angle = _flipAnimation.value;
            // Mirror the back face so text isn't reversed
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: _showFront
                  ? _buildFront(t, statusStyle)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildBack(t),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront(
    TicketModel t,
    ({Color bg, Color fg, String label}) statusStyle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blanc.withAlpha(13)),
      ),
      child: Row(
        children: [
          // Event icon with gradient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.rose, AppColors.roseClair],
              ),
            ),
            child: t.eventCoverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: t.eventCoverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.celebration,
                        color: AppColors.blanc,
                        size: 22,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.celebration,
                    color: AppColors.blanc,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.eventTitle ?? 'Event',
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (t.eventDate != null)
                  Text(
                    _formatEventDate(t.eventDate!),
                    style: const TextStyle(
                      color: AppColors.rose,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (t.ticketTypeName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    t.ticketTypeName!,
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Mini QR + status
          Column(
            children: [
              if (t.qrHash != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: QrImageView(
                    data: t.qrHash!,
                    version: QrVersions.auto,
                    size: 40,
                    backgroundColor: Colors.transparent,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.blanc,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.blanc,
                    ),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: AppColors.gris,
                    size: 24,
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusStyle.bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusStyle.label,
                  style: TextStyle(
                    color: statusStyle.fg,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(TicketModel t) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.violet.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.eventTitle ?? 'Event',
            style: const TextStyle(
              color: AppColors.blanc,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (t.qrHash != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blanc,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: t.qrHash!,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: AppColors.blanc,
              ),
            )
          else
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, color: AppColors.gris, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'QR non disponible',
                    style: TextStyle(color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Tap to flip',
            style: TextStyle(
              color: AppColors.gris.withAlpha(150),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

({Color bg, Color fg, String label}) _ticketStatusStyle(String status) {
  switch (status) {
    case 'valid':
      return (
        bg: AppColors.success.withAlpha(38),
        fg: AppColors.success,
        label: 'Valide',
      );
    case 'used':
      return (
        bg: AppColors.gris.withAlpha(38),
        fg: AppColors.gris,
        label: 'Utilisé',
      );
    case 'cancelled':
      return (
        bg: AppColors.error.withAlpha(38),
        fg: AppColors.error,
        label: 'Annulé',
      );
    default:
      return (
        bg: AppColors.gris.withAlpha(38),
        fg: AppColors.gris,
        label: status,
      );
  }
}
