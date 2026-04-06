import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared notifier — loads notifications filtered by type categories.
// One provider per sheet type (follows project pattern from ClientNotifSheet).
// ─────────────────────────────────────────────────────────────────────────────

class _ProNotifState {
  const _ProNotifState({this.items = const [], this.isLoading = true});
  final List<Map<String, dynamic>> items;
  final bool isLoading;
}

/// Creates a Riverpod provider that loads notifications filtered by [types].
NotifierProvider<_TypedNotifNotifier, _ProNotifState> _makeNotifProvider(
    List<String> types) {
  return NotifierProvider<_TypedNotifNotifier, _ProNotifState>(
    () => _TypedNotifNotifier(types),
    isAutoDispose: true,
  );
}

class _TypedNotifNotifier extends Notifier<_ProNotifState> {
  _TypedNotifNotifier(this._types);
  final List<String> _types;

  @override
  _ProNotifState build() {
    _load();
    return const _ProNotifState();
  }

  Future<void> _load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      var query = Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', uid);
      if (_types.isNotEmpty) {
        query = query.inFilter('type', _types);
      }
      final data =
          await query.order('created_at', ascending: false).limit(30);
      state = _ProNotifState(
        items: (data as List).cast<Map<String, dynamic>>(),
        isLoading: false,
      );
    } catch (_) {
      state = const _ProNotifState(isLoading: false);
    }
  }
}

// Per-sheet providers
final _activityNotifProvider = _makeNotifProvider(
    ['post_liked', 'post_saved', 'new_follower', 'new_comment']);
final _rdvNotifProvider = _makeNotifProvider(
    ['booking_confirmed', 'booking_reminder', 'booking_cancelled', 'booking_rescheduled', 'new_booking']);
final _ticketsNotifProvider = _makeNotifProvider(
    ['ticket_confirmed', 'ticket_sold', 'ticket_alert']);
final _messagesNotifProvider = _makeNotifProvider(
    ['new_message', 'chat_message']);

// ─────────────────────────────────────────────────────────────────────────────
// Shared sheet chrome
// ─────────────────────────────────────────────────────────────────────────────

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: AppColors.gris, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          Flexible(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. ProActivitySheet — "Activité sur mes posts"
// ─────────────────────────────────────────────────────────────────────────────

class ProActivitySheet extends ConsumerWidget {
  const ProActivitySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_activityNotifProvider);
    return _SheetChrome(
      title: 'Activity on my posts',
      icon: Icons.notifications_outlined,
      iconColor: AppColors.rose,
      child: _NotifList(items: s.items, isLoading: s.isLoading, emptyText: 'No recent activity'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. ProRdvSheet — "Réservations & RDV"
// ─────────────────────────────────────────────────────────────────────────────

class ProRdvSheet extends ConsumerWidget {
  const ProRdvSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_rdvNotifProvider);
    return _SheetChrome(
      title: 'Bookings & Appointments',
      icon: Icons.calendar_today_outlined,
      iconColor: AppColors.violet,
      child: _NotifList(items: s.items, isLoading: s.isLoading, emptyText: 'No recent bookings'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. ProTicketsSheet — "Billets vendus"
// ─────────────────────────────────────────────────────────────────────────────

class ProTicketsSheet extends ConsumerWidget {
  const ProTicketsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_ticketsNotifProvider);
    return _SheetChrome(
      title: 'Tickets sold',
      icon: Icons.confirmation_number_outlined,
      iconColor: AppColors.rose,
      child: _NotifList(items: s.items, isLoading: s.isLoading, emptyText: 'No tickets sold recently'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. ProMessagesSheet — "Messages clients"
// ─────────────────────────────────────────────────────────────────────────────

class ProMessagesSheet extends ConsumerWidget {
  const ProMessagesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_messagesNotifProvider);
    return _SheetChrome(
      title: 'Client messages',
      icon: Icons.chat_bubble_outline,
      iconColor: AppColors.success,
      child: _NotifList(items: s.items, isLoading: s.isLoading, emptyText: 'No recent messages'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared notification list with staggered fadeSlideUp
// ─────────────────────────────────────────────────────────────────────────────

class _NotifList extends StatelessWidget {
  const _NotifList({
    required this.items,
    required this.isLoading,
    required this.emptyText,
  });

  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.blanc, strokeWidth: 2),
        ),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            emptyText,
            style: const TextStyle(color: AppColors.gris, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _StaggeredNotifItem(
          notification: items[index],
          delay: Duration(milliseconds: 50 * index),
        );
      },
    );
  }
}

class _StaggeredNotifItem extends StatefulWidget {
  const _StaggeredNotifItem({
    required this.notification,
    required this.delay,
  });

  final Map<String, dynamic> notification;
  final Duration delay;

  @override
  State<_StaggeredNotifItem> createState() => _StaggeredNotifItemState();
}

class _StaggeredNotifItemState extends State<_StaggeredNotifItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final title = n['title'] as String? ?? '';
    final body = n['body'] as String? ?? '';
    final isRead = n['is_read'] as bool? ?? true;
    final createdAt = n['created_at'] as String?;
    final avatarUrl = n['avatar_url'] as String?;
    final timeAgo =
        createdAt != null ? _formatTimeAgo(DateTime.parse(createdAt)) : '';

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              if (avatarUrl != null)
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.surfaceAlt,
                  backgroundImage: CachedNetworkImageProvider(avatarUrl),
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      _iconForType(n['type'] as String? ?? ''),
                      size: 20,
                      color: AppColors.grisClair,
                    ),
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
                      style: const TextStyle(
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
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'post_liked' || 'comment_like' => Icons.favorite_rounded,
      'post_saved' => Icons.bookmark_rounded,
      'new_follower' => Icons.person_add_alt_1_outlined,
      'new_comment' => Icons.chat_bubble_outline,
      'booking_confirmed' || 'new_booking' => Icons.check_circle_outline,
      'booking_reminder' => Icons.access_time_rounded,
      'booking_cancelled' => Icons.cancel_outlined,
      'booking_rescheduled' => Icons.schedule_outlined,
      'ticket_confirmed' || 'ticket_sold' => Icons.confirmation_number_outlined,
      'ticket_alert' => Icons.warning_amber_outlined,
      'new_message' || 'chat_message' => Icons.chat_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
