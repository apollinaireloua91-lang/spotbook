import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/utils/time_ago.dart';
import '../../../../notifications/data/notification_repository.dart';
import '../../../../notifications/domain/notification_model.dart';

class ClientNotifSheet extends ConsumerStatefulWidget {
  const ClientNotifSheet({super.key});

  @override
  ConsumerState<ClientNotifSheet> createState() => _ClientNotifSheetState();
}

class _ClientNotifSheetState extends ConsumerState<ClientNotifSheet>
    with SingleTickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final notifs = await repo.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
        _staggerCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '🔔 Mes notifications',
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: AppColors.border.withAlpha(80)),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.violet,
                          strokeWidth: 2,
                        ),
                      )
                    : _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  color: AppColors.gris.withAlpha(80),
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No notifications',
                                  style: TextStyle(
                                    color: AppColors.gris,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _staggerCtrl,
                            builder: (context, _) {
                              return ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.only(top: 6),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  return _buildNotifItem(
                                    _notifications[index],
                                    index,
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotifItem(NotificationModel notif, int index) {
    // Staggered fade-slide animation
    final delay = (index * 0.05).clamp(0.0, 0.8);
    final end = (delay + 0.2).clamp(0.0, 1.0);
    final t = ((_staggerCtrl.value - delay) / (end - delay)).clamp(0.0, 1.0);
    final opacity = Curves.easeOut.transform(t);
    final slideY = 12.0 * (1.0 - t);

    final meta = _notifMeta(notif.type);

    return Transform.translate(
      offset: Offset(0, slideY),
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notif.isRead
                ? Colors.transparent
                : AppColors.violet.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Emoji icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: meta.bgColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    meta.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.body,
                      style: TextStyle(
                        color: AppColors.gris,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time + unread dot
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeAgo(notif.createdAt),
                    style: TextStyle(
                      color: AppColors.grisInactif,
                      fontSize: 9,
                    ),
                  ),
                  if (!notif.isRead) ...[
                    const SizedBox(height: 4),
                    _PulsingDot(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _NotifMeta _notifMeta(String type) {
    return switch (type) {
      'booking_confirmed' => _NotifMeta('✅', AppColors.success),
      'booking_reminder' => _NotifMeta('⏰', AppColors.warning),
      'ticket' => _NotifMeta('🎟', AppColors.rose),
      'like' => _NotifMeta('❤', AppColors.rose),
      'follow' => _NotifMeta('👤', AppColors.violet),
      'post' => _NotifMeta('🔥', AppColors.warning),
      _ => _NotifMeta('📢', AppColors.violet),
    };
  }

}

class _NotifMeta {
  const _NotifMeta(this.emoji, this.bgColor);
  final String emoji;
  final Color bgColor;
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.rose,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
