import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../../../../feed/data/feed_notifier.dart';
import '../cubit/client_feed_cubit.dart';

class ClientTopBar extends StatelessWidget {
  const ClientTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientFeedCubit, ClientFeedState>(
      buildWhen: (p, c) =>
          p.activeTab != c.activeTab ||
          p.unreadBookings != c.unreadBookings ||
          p.unreadTickets != c.unreadTickets ||
          p.unreadMessages != c.unreadMessages,
      builder: (context, state) {
        final cubit = context.read<ClientFeedCubit>();
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // LEFT — Logo
                Text(
                  'Spotbook',
                  style: AppTypography.spotbookLogo(onVideoBackground: true)
                      .copyWith(fontSize: 19),
                ),
                const Spacer(),
                // CENTER — Tab pills
                _FeedTabGroup(
                  activeTab: state.activeTab,
                  onTabChanged: cubit.switchTab,
                ),
                const Spacer(),
                // RIGHT — Bell only
                _TopBarButton(
                  icon: Icons.notifications_outlined,
                  dotColor: AppColors.rose,
                  hasUnread: state.unreadBookings > 0 ||
                      state.unreadTickets > 0 ||
                      state.unreadMessages > 0,
                  onTap: () => _showNotificationsSheet(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ClientNotificationsSheet(),
    );
  }
}

class _FeedTabGroup extends StatelessWidget {
  const _FeedTabGroup({
    required this.activeTab,
    required this.onTabChanged,
  });

  final FeedTab activeTab;
  final ValueChanged<FeedTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.blanc.withAlpha(15), // rgba(255,255,255,0.06)
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabButton(
            label: 'Discover',
            isActive: activeTab == FeedTab.discover,
            onTap: () => onTabChanged(FeedTab.discover),
          ),
          _TabButton(
            label: 'Following',
            isActive: activeTab == FeedTab.following,
            onTap: () => onTabChanged(FeedTab.following),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.violet.withAlpha(128) // rgba(108,62,244,0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isActive
                ? AppColors.blanc
                : AppColors.blanc.withAlpha(115), // rgba(255,255,255,0.45)
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Shared top bar button with pulsing colored dot — used for Client feed.
class _TopBarButton extends StatefulWidget {
  const _TopBarButton({
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
  State<_TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<_TopBarButton>
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
  void didUpdateWidget(covariant _TopBarButton oldWidget) {
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
        borderRadius: BorderRadius.circular(11),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt.withAlpha(217), // rgba(22,22,31,0.85)
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.blanc.withAlpha(26)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    widget.icon,
                    color: AppColors.blanc,
                    size: 17,
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
                        width: 7,
                        height: 7,
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

/// Placeholder notifications bottom sheet for Client.
class _ClientNotificationsSheet extends StatelessWidget {
  const _ClientNotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gris.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Notifications',
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 40),
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.gris,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'No notifications',
            style: TextStyle(color: AppColors.gris, fontSize: 14),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
