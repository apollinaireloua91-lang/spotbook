import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/notification_notifier.dart';
import '../../domain/notification_model.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.retourLabel,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(l.notifications,
            style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (state.notifications.any((n) => !n.isRead))
            Semantics(
              label: l.notificationsMarkAllRead,
              child: IconButton(
                icon: Icon(Icons.done_all, color: AppColors.blanc),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(notificationListProvider.notifier).markAllAsRead();
                },
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? _buildShimmer()
          : state.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, color: AppColors.gris, size: 48),
                      const SizedBox(height: 12),
                      Text(l.notificationsEmpty,
                          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.blanc,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      return _NotificationTile(
                        notification: state.notifications[index],
                        delay: index * 50,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerStatefulWidget {
  const _NotificationTile({required this.notification, required this.delay});
  final NotificationModel notification;
  final int delay;

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking_reminder':
        return Icons.alarm;
      case 'booking_update':
        return Icons.event_note;
      case 'chat':
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'review_request':
        return Icons.star_border;
      case 'waitlist':
        return Icons.hourglass_top;
      case 'follow':
        return Icons.person_add_outlined;
      case 'like':
        return Icons.favorite_border;
      case 'video_ready':
        return Icons.videocam_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          ref.read(notificationListProvider.notifier).deleteNotification(n.id);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete_outline, color: AppColors.error),
        ),
        child: GestureDetector(
          onTap: () {
            if (!n.isRead) {
              ref.read(notificationListProvider.notifier).markAsRead(n.id);
            }
            _navigateForType(context, n);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.isRead ? AppColors.surface : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: n.isRead ? AppColors.border : AppColors.blanc.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.fond,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForType(n.type), color: AppColors.blanc, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: GoogleFonts.dmSans(
                          color: AppColors.blanc,
                          fontSize: 14,
                          fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(n.body,
                          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(n.createdAt),
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
                ),
                if (!n.isRead) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.blanc,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('dd/MM').format(dt);
  }

  void _navigateForType(BuildContext context, NotificationModel n) {
    switch (n.type) {
      case 'booking_reminder':
      case 'booking_update':
        final bookingId = n.data['bookingId'] as String?;
        if (bookingId != null) context.push('/booking/$bookingId');
        break;
      case 'chat':
      case 'new_message':
        final convId = (n.data['conversationId'] ?? n.data['conversation_id']) as String?;
        if (convId != null) context.push('/chat/$convId');
        break;
      case 'review_request':
        final bookingId = n.data['bookingId'] as String?;
        if (bookingId != null) context.push('/booking/$bookingId');
        break;
      case 'waitlist':
        final eventId = n.data['eventId'] as String?;
        if (eventId != null) context.push('/event/$eventId');
        break;
      default:
        break;
    }
  }
}
