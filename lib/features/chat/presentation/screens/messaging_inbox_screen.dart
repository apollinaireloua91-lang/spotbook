import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/chat_notifier.dart';

/// Liste des conversations (style Stitch / messagerie), palette noir & blanc.
class MessagingInboxScreen extends ConsumerWidget {
  const MessagingInboxScreen({super.key, this.isProShell = false});

  /// Préfixe des routes chat : `/pro/messages` vs `/client/messages`.
  final bool isProShell;

  String get _base => isProShell ? '/pro/messages' : '/client/messages';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
              )
            : null,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: switch (state.isLoading) {
        true => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SpotbookLoadingShimmer.list(itemCount: 8),
          ),
        false when state.conversations.isEmpty => EmptyState.noMessages(
            onCta: context.canPop() ? () => context.pop() : null,
          ),
        false => RefreshIndicator(
            color: AppColors.blanc,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.border,
              ),
              itemBuilder: (context, i) {
                final c = state.conversations[i];
                return _ConversationTile(
                  name: c.otherUserName ?? 'Utilisateur',
                  avatarUrl: c.otherUserAvatar,
                  preview: c.lastMessage ?? '',
                  time: c.lastMessageAt,
                  unread: c.unreadCount,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push(
                      '$_base/${c.id}',
                      extra: {
                        'otherUserName': c.otherUserName ?? '',
                      },
                    );
                  },
                );
              },
            ),
          ),
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.avatarUrl,
    required this.preview,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final String preview;
  final DateTime? time;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr = time != null
        ? DateFormat('dd/MM HH:mm').format(time!.toLocal())
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.surfaceAlt,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.surfaceAlt,
                          child: const Icon(Icons.person, color: AppColors.gris),
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.person, color: AppColors.gris),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.blanc,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppColors.gris,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gris,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blanc,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: AppColors.fond,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
