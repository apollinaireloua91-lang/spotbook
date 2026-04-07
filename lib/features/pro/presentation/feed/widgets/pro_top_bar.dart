import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../cubit/pro_feed_cubit.dart';
import 'pro_notif_sheets.dart';

/// Pro feed top bar: 4 notification buttons aligned right.
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Spacer(),
                _ProNotifButton(
                  icon: Icons.notifications_outlined,
                  dotColor: AppColors.rose,
                  hasUnread: state.unreadNotif > 0,
                  onTap: () => _openSheet(
                    context,
                    const ProActivitySheet(),
                  ),
                ),
                const SizedBox(width: 6),
                _ProNotifButton(
                  icon: Icons.calendar_today_outlined,
                  dotColor: AppColors.violet,
                  hasUnread: state.unreadRdv > 0,
                  onTap: () => _openSheet(
                    context,
                    const ProRdvSheet(),
                  ),
                ),
                const SizedBox(width: 6),
                _ProNotifButton(
                  icon: Icons.confirmation_number_outlined,
                  dotColor: AppColors.rose,
                  hasUnread: state.unreadTickets > 0,
                  onTap: () => _openSheet(
                    context,
                    const ProTicketsSheet(),
                  ),
                ),
                const SizedBox(width: 6),
                _ProNotifButton(
                  icon: Icons.chat_bubble_outline,
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

/// 32x32 notification button with pulsing colored dot.
class _ProNotifButton extends StatefulWidget {
  const _ProNotifButton({
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
  State<_ProNotifButton> createState() => _ProNotifButtonState();
}

class _ProNotifButtonState extends State<_ProNotifButton>
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
    _pulseScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.hasUnread) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ProNotifButton oldWidget) {
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
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(77),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(26)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 16,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
                if (widget.hasUnread)
                  Positioned(
                    top: 4,
                    right: 4,
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
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.dotColor,
                          shape: BoxShape.circle,
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
