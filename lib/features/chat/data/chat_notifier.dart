import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/chat_models.dart';
import 'chat_repository.dart';

// ─── Conversations list ─────────────────────────────────────

class ConversationsState {
  const ConversationsState({
    this.conversations = const [],
    this.isLoading = true,
  });
  final List<ConversationModel> conversations;
  final bool isLoading;

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
  }) =>
      ConversationsState(
        conversations: conversations ?? this.conversations,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ConversationsNotifier extends Notifier<ConversationsState> {
  RealtimeChannel? _inboxChannel;
  Timer? _debounce;
  bool _microtaskScheduled = false;

  @override
  ConversationsState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _inboxChannel?.unsubscribe();
      _inboxChannel = null;
      _microtaskScheduled = false;
    });

    final uid = ref.read(chatRepositoryProvider).currentUserId;
    if (uid == null) {
      return const ConversationsState(conversations: [], isLoading: false);
    }

    if (_inboxChannel != null || _microtaskScheduled) {
      return state;
    }

    _microtaskScheduled = true;
    Future.microtask(() => _bootstrap(uid));
    return const ConversationsState(isLoading: true);
  }

  Future<void> _bootstrap(String uid) async {
    await _load();
    final repo = ref.read(chatRepositoryProvider);
    _inboxChannel?.unsubscribe();
    _inboxChannel = repo.subscribeInbox(
      userId: uid,
      onChange: _scheduleRefresh,
    );
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    final repo = ref.read(chatRepositoryProvider);
    final convs = await repo.getConversations();
    state = state.copyWith(conversations: convs, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
  ConversationsNotifier.new,
  isAutoDispose: true,
);

// ─── Chat messages ──────────────────────────────────────────

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isOtherTyping = false,
  });
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final bool isOtherTyping;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isOtherTyping,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        isOtherTyping: isOtherTyping ?? this.isOtherTyping,
      );
}

class ChatNotifier extends Notifier<ChatState> {
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _typingChannel;
  Timer? _typingTimer;
  String? _conversationId;

  @override
  ChatState build() => const ChatState();

  Future<void> loadMessages(String conversationId) async {
    _conversationId = conversationId;
    state = state.copyWith(isLoading: true);

    final repo = ref.read(chatRepositoryProvider);
    final messages = await repo.getMessages(conversationId);
    state = state.copyWith(messages: messages, isLoading: false);

    await repo.markRead(conversationId);
    _subscribeRealtime(conversationId);
  }

  void _subscribeRealtime(String conversationId) {
    final repo = ref.read(chatRepositoryProvider);

    _messagesChannel = repo.subscribeMessages(
      conversationId,
      onInsert: (msg) {
        if (!state.messages.any((m) => m.id == msg.id)) {
          state = state.copyWith(messages: [msg, ...state.messages]);
          repo.markRead(conversationId);
        }
      },
    );

    _typingChannel = repo.subscribeTyping(
      conversationId,
      onTyping: (userId) {
        if (userId != repo.currentUserId) {
          state = state.copyWith(isOtherTyping: true);
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 3), () {
            state = state.copyWith(isOtherTyping: false);
          });
        }
      },
    );
  }

  Future<void> sendMessage(String content) async {
    if (_conversationId == null || content.trim().isEmpty) return;

    state = state.copyWith(isSending: true);
    final repo = ref.read(chatRepositoryProvider);

    await repo.sendMessage(
      conversationId: _conversationId!,
      content: content.trim(),
    );
    state = state.copyWith(isSending: false);
  }

  Future<void> sendImage(String imageUrl) async {
    if (_conversationId == null) return;

    state = state.copyWith(isSending: true);
    final repo = ref.read(chatRepositoryProvider);
    await repo.sendMessage(
      conversationId: _conversationId!,
      imageUrl: imageUrl,
    );
    state = state.copyWith(isSending: false);
  }

  void sendTypingIndicator() {
    if (_conversationId == null) return;
    ref.read(chatRepositoryProvider).sendTypingIndicator(_conversationId!);
  }

  void dispose() {
    _messagesChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _typingTimer?.cancel();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
  isAutoDispose: true,
);
