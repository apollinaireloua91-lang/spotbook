import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../../../../feed/data/feed_notifier.dart';
import '../cubit/client_feed_cubit.dart';
import 'client_notif_sheet.dart';

class ClientTopBar extends StatelessWidget {
  const ClientTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientFeedCubit, ClientFeedState>(
      buildWhen: (p, c) =>
          p.activeTab != c.activeTab ||
          p.unreadNotifications != c.unreadNotifications,
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
                // CENTER — Tab pills in container
                _FeedTabGroup(
                  activeTab: state.activeTab,
                  onTabChanged: cubit.switchTab,
                ),
                const Spacer(),
                // RIGHT — Bell
                _NotifBell(
                  count: state.unreadNotifications,
                  onTap: () => _showNotifSheet(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotifSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ClientNotifSheet(),
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
            label: 'Découvrir',
            isActive: activeTab == FeedTab.discover,
            onTap: () => onTabChanged(FeedTab.discover),
          ),
          _TabButton(
            label: 'Abonnements',
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

class _NotifBell extends StatelessWidget {
  const _NotifBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.blanc,
                    size: 19,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _PulsingNotifDot(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingNotifDot extends StatefulWidget {
  @override
  State<_PulsingNotifDot> createState() => _PulsingNotifDotState();
}

class _PulsingNotifDotState extends State<_PulsingNotifDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.rose,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fond, width: 1),
        ),
      ),
    );
  }
}
