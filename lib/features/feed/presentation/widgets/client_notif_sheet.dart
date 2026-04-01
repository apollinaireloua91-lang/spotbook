import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';

class _NotifState {
  const _NotifState({this.notifications = const [], this.isLoading = true});
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
}

class _NotifNotifier extends Notifier<_NotifState> {
  @override
  _NotifState build() {
    _load();
    return const _NotifState();
  }

  Future<void> _load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(30);
      state = _NotifState(
        notifications: (data as List).cast<Map<String, dynamic>>(),
        isLoading: false,
      );
    } catch (_) {
      state = const _NotifState(isLoading: false);
    }
  }
}

final _notifProvider = NotifierProvider<_NotifNotifier, _NotifState>(
  _NotifNotifier.new,
  isAutoDispose: true,
);

class ClientNotifSheet extends ConsumerWidget {
  const ClientNotifSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_notifProvider);
    final maxH = MediaQuery.sizeOf(context).height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Mes notifications',
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.gris,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          if (s.isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.blanc),
            )
          else if (s.notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'Aucune notification',
                style: TextStyle(color: AppColors.gris, fontSize: 14),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: s.notifications.length,
                itemBuilder: (context, index) {
                  final n = s.notifications[index];
                  return _NotifItem(notification: n);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  const _NotifItem({required this.notification});

  final Map<String, dynamic> notification;

  IconData get _icon {
    final type = notification['type'] as String? ?? '';
    return switch (type) {
      'booking_confirmed' => Icons.check_circle_outline,
      'booking_reminder' => Icons.access_time_rounded,
      'ticket_confirmed' => Icons.confirmation_number_outlined,
      'ticket_alert' => Icons.confirmation_number_outlined,
      'comment_like' => Icons.favorite_rounded,
      'new_follower' => Icons.person_add_alt_1_outlined,
      'new_post' => Icons.play_circle_outline_rounded,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['is_read'] as bool? ?? true;
    final createdAt = notification['created_at'] as String?;
    final timeAgo = createdAt != null ? _formatTimeAgo(DateTime.parse(createdAt)) : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(_icon, size: 20, color: AppColors.grisClair),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.grisClair,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(color: AppColors.gris, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                timeAgo,
                style: const TextStyle(color: AppColors.gris, fontSize: 9),
              ),
              const SizedBox(height: 4),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.blanc,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${(diff.inDays / 7).floor()}sem';
  }
}
