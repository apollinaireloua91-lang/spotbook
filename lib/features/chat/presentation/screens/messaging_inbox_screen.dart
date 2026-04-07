import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/chat_notifier.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

/// Liste des conversations (style Stitch / messagerie), palette noir & blanc.
class MessagingInboxScreen extends ConsumerStatefulWidget {
  const MessagingInboxScreen({super.key, this.isProShell = false});

  /// Préfixe des routes chat : `/pro/messages` vs `/client/messages`.
  final bool isProShell;

  @override
  ConsumerState<MessagingInboxScreen> createState() =>
      _MessagingInboxScreenState();
}

class _MessagingInboxScreenState extends ConsumerState<MessagingInboxScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Typing indicator state per conversation
  final Map<String, bool> _typingStates = {};
  final Map<String, RealtimeChannel> _typingChannels = {};
  final Map<String, Timer> _typingTimers = {};
  Set<String> _subscribedIds = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final channel in _typingChannels.values) {
      channel.unsubscribe();
    }
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _syncTypingSubscriptions(List<ConversationModel> conversations) {
    final repo = ref.read(chatRepositoryProvider);
    final myUid = repo.currentUserId;
    if (myUid == null) return;

    final currentIds = conversations.map((c) => c.id).toSet();
    if (currentIds.length == _subscribedIds.length &&
        currentIds.every(_subscribedIds.contains)) {
      return; // No change
    }

    // Subscribe to new conversations
    for (final c in conversations) {
      if (_typingChannels.containsKey(c.id)) continue;
      _typingChannels[c.id] = repo.subscribeTyping(
        c.id,
        onTyping: (userId) {
          if (userId != myUid && mounted) {
            setState(() => _typingStates[c.id] = true);
            _typingTimers[c.id]?.cancel();
            _typingTimers[c.id] = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _typingStates[c.id] = false);
            });
          }
        },
      );
    }

    // Clean up removed conversations
    final removed = _subscribedIds.difference(currentIds);
    for (final id in removed) {
      _typingChannels.remove(id)?.unsubscribe();
      _typingTimers.remove(id)?.cancel();
      _typingStates.remove(id);
    }

    _subscribedIds = currentIds;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsProvider);

    // Subscribe to typing when conversations load
    if (!state.isLoading && state.conversations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncTypingSubscriptions(state.conversations);
      });
    }

    // Filter conversations by search query
    final filtered = _searchQuery.isEmpty
        ? state.conversations
        : state.conversations.where((c) {
            final name = (c.otherUserName ?? '').toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.blanc, size: 16),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
              )
            : null,
        title: Text(
          'Messages',
          style: GoogleFonts.sora(
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
            onCta: () => context.go('/client/discover'),
          ),
        false => Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.dmSans(
                      color: AppColors.blanc, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search conversations…',
                    hintStyle:
                        GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.gris, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.close,
                                color: AppColors.gris, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              // Conversation list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No conversations found'
                              : 'No messages',
                          style: GoogleFonts.dmSans(
                              color: AppColors.gris, fontSize: 15),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.blanc,
                        backgroundColor: AppColors.surface,
                        onRefresh: () =>
                            ref.read(conversationsProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            final isTyping = _typingStates[c.id] == true;
                            return _ConversationTile(
                              name: c.otherUserName ?? 'User',
                              avatarUrl: c.otherUserAvatar,
                              preview: c.lastMessage ?? '',
                              time: c.lastMessageAt,
                              unread: c.unreadCount,
                              isTyping: isTyping,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.push(
                                  '/chat/${c.id}',
                                  extra: <String, String>{
                                    'otherUserName': c.otherUserName ?? '',
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
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
    required this.isTyping,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final String preview;
  final DateTime? time;
  final int unread;
  final bool isTyping;
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
                          child: const Icon(Icons.person,
                              color: AppColors.gris),
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.person,
                            color: AppColors.gris),
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
                            style: GoogleFonts.dmSans(
                              color: AppColors.blanc,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: GoogleFonts.dmSans(
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
                          child: isTyping
                              ? Text(
                                  'typing…',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.violetClair,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.gris,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blanc,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: GoogleFonts.dmSans(
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
