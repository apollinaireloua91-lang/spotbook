import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/booking_models.dart';

/// Category-to-gradient mapping for pro avatar rings.
LinearGradient _categoryGradient(String? category) {
  switch (category?.toLowerCase()) {
    case 'barbier':
    case 'coiffure':
      return LinearGradient(
        colors: [AppColors.violet, AppColors.violetClair],
      );
    case 'nails':
    case 'esthétique':
      return LinearGradient(
        colors: [AppColors.rose, AppColors.roseClair],
      );
    case 'massage':
    case 'bien-être':
      return LinearGradient(
        colors: [AppColors.success, AppColors.successLight],
      );
    case 'traiteur':
    case 'cuisine':
      return LinearGradient(
        colors: [AppColors.warning, AppColors.starGoldLight],
      );
    default:
      return AppColors.gradientAccent;
  }
}

/// Status badge configuration.
({Color bg, Color fg, String label}) _statusStyle(String status, AppLocalizations l) {
  switch (status) {
    case 'confirmed':
      return (
        bg: AppColors.success.withAlpha(38),
        fg: AppColors.success,
        label: '✓ ${l.confirmed}',
      );
    case 'pending_payment':
      return (
        bg: AppColors.violet.withAlpha(38),
        fg: AppColors.violetClair,
        label: '⏳ ${l.pending}',
      );
    case 'completed':
      return (
        bg: AppColors.gris.withAlpha(38),
        fg: AppColors.gris,
        label: '✓ ${l.markAsDone}',
      );
    case 'cancelled_full_refund':
    case 'cancelled_no_refund':
      return (
        bg: AppColors.error.withAlpha(38),
        fg: AppColors.error,
        label: '✗ ${l.cancel}',
      );
    default:
      return (
        bg: AppColors.gris.withAlpha(38),
        fg: AppColors.gris,
        label: status,
      );
  }
}

class ReservationCard extends StatefulWidget {
  const ReservationCard({
    super.key,
    required this.booking,
    this.isUpcoming = false,
    this.isPast = false,
    this.onCancel,
    this.onContact,
    this.onReview,
    this.onRebook,
    this.animationDelay = Duration.zero,
  });

  final BookingModel booking;
  final bool isUpcoming;
  final bool isPast;
  final VoidCallback? onCancel;
  final VoidCallback? onContact;
  final VoidCallback? onReview;
  final VoidCallback? onRebook;
  final Duration animationDelay;

  @override
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // 3D tilt state
  double _rotateX = 0;
  double _rotateY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotateY = (details.localPosition.dx - 150) / 300 * 0.05;
      _rotateX = -(details.localPosition.dy - 80) / 160 * 0.05;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = widget.booking;
    final status = _statusStyle(b.status, l);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: () => context.push('/booking/${b.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_rotateX)
            ..rotateY(_rotateY),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.blanc.withAlpha(13),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: avatar + name + service + badge ───
              Row(
                children: [
                  // Category gradient avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _categoryGradient(null),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: b.proAvatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: b.proAvatarUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceAlt,
                                  child: Icon(Icons.person,
                                      color: AppColors.gris, size: 20),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceAlt,
                                child: Icon(Icons.person,
                                    color: AppColors.gris, size: 20),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.proName ?? 'Professionnel',
                          style: TextStyle(
                            color: AppColors.blanc,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.serviceName ?? 'Service',
                          style: TextStyle(
                            color: AppColors.gris,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.fg,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ─── Info pills ───
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoPill(
                    text: _formatDate(b.slotDate),
                    icon: '📅',
                  ),
                  _InfoPill(
                    text: b.slotStartTime?.substring(0, 5) ?? '--:--',
                    icon: '⏰',
                  ),
                  _InfoPill(
                    text: '${b.totalAmount.toStringAsFixed(0)} \$',
                    icon: '💰',
                  ),
                ],
              ),

              // ─── Deposit info ───
              if (b.isDepositMode) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Acompte : ${b.depositAmount.toStringAsFixed(0)} \$',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ─── Action buttons ───
              if (widget.isUpcoming) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: l.cancel,
                        bgColor: AppColors.rose.withAlpha(30),
                        textColor: AppColors.roseClair,
                        onTap: widget.onCancel ?? () {
                          HapticFeedback.lightImpact();
                          context.push('/cancel-booking/${b.id}');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: '💬 Message',
                        bgColor: AppColors.violet,
                        textColor: AppColors.blanc,
                        onTap: widget.onContact,
                      ),
                    ),
                  ],
                ),
              ],

              if (widget.isPast) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: '⭐ ${l.leaveReview}',
                        bgColor: AppColors.violet.withAlpha(20),
                        textColor: AppColors.violetClair,
                        onTap: widget.onReview ?? () {
                          HapticFeedback.lightImpact();
                          context.push('/review', extra: {
                            'bookingId': b.id,
                            'proId': b.proId,
                            'serviceName': b.serviceName ?? '',
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: '🔄 ${l.bookAgain}',
                        bgColor: AppColors.surface,
                        textColor: AppColors.blanc,
                        borderColor: AppColors.border,
                        onTap: widget.onRebook ?? () {
                          HapticFeedback.lightImpact();
                          context.push('/client/booking-flow/${b.proId}');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '--/--';
    try {
      final parsed = DateTime.parse(date);
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      const months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
        'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
      ];
      return '${days[parsed.weekday - 1]} ${parsed.day} ${months[parsed.month - 1]}';
    } catch (_) {
      return date;
    }
  }
}

// ─── Info pill widget ─────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, required this.icon});

  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blanc.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $text',
        style: TextStyle(
          color: AppColors.blanc,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
