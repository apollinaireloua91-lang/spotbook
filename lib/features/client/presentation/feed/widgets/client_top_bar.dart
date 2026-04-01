import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../../../../feed/presentation/widgets/client_notif_sheet.dart';
import '../../../../feed/data/feed_notifier.dart';
import '../cubit/client_feed_cubit.dart';

/// Barre haute du feed client : logo Spotbook, onglets Découvrir / Abonnements, cloche.
class ClientTopBar extends StatelessWidget {
  const ClientTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientFeedCubit, ClientFeedState>(
      buildWhen: (p, c) =>
          p.activeTab != c.activeTab || p.unreadNotifications != c.unreadNotifications,
      builder: (context, state) {
        final cubit = context.read<ClientFeedCubit>();
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.violetClair,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Spotbook',
                      style: AppTypography.spotbookLogo(),
                    ),
                  ],
                ),
                const Spacer(),
                _TabButton(
                  label: 'Découvrir',
                  isActive: state.activeTab == FeedTab.discover,
                  onTap: () => cubit.switchTab(FeedTab.discover),
                ),
                const SizedBox(width: 20),
                _TabButton(
                  label: 'Abonnements',
                  isActive: state.activeTab == FeedTab.following,
                  onTap: () => cubit.switchTab(FeedTab.following),
                ),
                const Spacer(),
                _NotifBell(
                  hasUnread: state.unreadNotifications > 0,
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      builder: (_) => const ClientNotifSheet(),
                    );
                    if (context.mounted) {
                      await cubit.refreshUnreadCount();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.feedTab(active: isActive),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isActive ? 24 : 0,
            decoration: BoxDecoration(
              color: AppColors.blanc,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifBell extends StatelessWidget {
  const _NotifBell({required this.hasUnread, required this.onTap});

  final bool hasUnread;
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
              color: AppColors.surface.withAlpha(217),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.blanc.withAlpha(26),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.blanc,
                    size: 20,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.fond,
                          width: 1.5,
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
