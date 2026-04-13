import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../cubit/pro_feed_cubit.dart';
import 'pro_notif_sheets.dart';

/// Pro feed top bar — premium glassmorphism.
///
/// Layout: "Spotbook" logo (left) ← spacer → 4 notification buttons (right).
/// Each button uses frosted glass with colored badge dots and pulse animation.
class ProTopBar extends StatelessWidget {
  const ProTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProFeedCubit, ProFeedState>(
      buildWhen: (p, c) =>
          p.unreadNotif != c.unreadNotif ||
          p.unreadRdv != c.unreadRdv ||
          p.unreadTickets != c.unreadTickets ||
          p.unreadMessages != c.unreadMessages,
      builder: (context, state) {
        return SafeArea(
          bottom: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // ── Spotbook logo ──
                Text(
                  'Spotbook',
                  style: AppTypography.spotbookLogo(
                      onVideoBackground: true),
                ),
                const Spacer(),
                // ── Notification buttons ──
                _PremiumNotifButton(
                  icon: Icons.notifications_outlined,
                  dotColor: AppColors.rose,
                  hasUnread: state.unreadNotif > 0,
                  onTap: () => _openSheet(
                    context,
                    const ProActivitySheet(),
                  ),
                ),
                const SizedBox(width: 8),
                _PremiumNotifButton(
                  icon: Icons.calendar_today_outlined,
                  dotColor: AppColors.violetClair,
                  hasUnread: state.unreadRdv > 0,
                  onTap: () => _openSheet(
                    context,
                    const ProRdvSheet(),
                  ),
                ),
                const SizedBox(width: 8),
                _PremiumNotifButton(
                  icon: Icons.confirmation_number_outlined,
                  dotColor: AppColors.rose,
                  hasUnread: state.unreadTickets > 0,
                  onTap: () => _openSheet(
                    context,
                    const ProTicketsSheet(),
                  ),
                ),
                const SizedBox(width: 8),
                _PremiumNotifButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  dotColor: AppColors.success,
                  hasUnread: state.unreadMessages > 0,
                  onTap: () => _openSheet(
                    context,
                    const ProMessagesSheet(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }
}

/// 38×38 premium glassmorphism notification button with animated badge.
///
/// Upgrades from old 32×32:
/// - Larger touch target (38px)
/// - Stronger frosted glass (12σ blur)
/// - Rounded rect instead of small square (radius 12)
/// - Glowing dot badge with scale pulse
/// - Subtle gradient border on hover/active states
class _PremiumNotifButton extends StatefulWidget {
  const _PremiumNotifButton({
    required this.icon,
    required this.dotColor,
    required this.hasUnread,
    required this.onTap,
  });

  final IconData icon;
  final Color dotColor;
  final bool hasUnread;
  final VoidCallback onTap;

  @override
  State<_PremiumNotifButton> createState() => _PremiumNotifButtonState();
}

class _PremiumNotifButtonState extends State<_PremiumNotifButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.hasUnread) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PremiumNotifButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasUnread && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.hasUnread && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(90),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.hasUnread
                    ? widget.dotColor.withAlpha(40)
                    : Colors.white.withAlpha(20),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 18,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
                if (widget.hasUnread)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseScale.value,
                          child: Opacity(
                            opacity: _pulseOpacity.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: widget.dotColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.dotColor.withAlpha(120),
                              blurRadius: 6,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
