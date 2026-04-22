import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/realtime/realtime_events.dart';
import '../../../core/realtime/realtime_manager.dart';
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
  StreamSubscription<RealtimeEvent>? _rtSub;

  @override
  ConversationsState build() {
    _listenRealtime();
    _load();
    ref.onDispose(() => _rtSub?.cancel());
    return const ConversationsState();
  }

  void _listenRealtime() {
    _rtSub = ref.read(realtimeManagerProvider).conversationStream.listen((event) {
      if (event is ConversationUpdated || event is InboxMessageReceived) {
        // Refetch to get the authoritative unread_count_{client,pro}
        // from the conversations row + updated last_message / ordering.
        // The derived `unreadMessageCountProvider` recomputes automatically
        // from this state — no manual increment/decrement needed.
        _load();
      }
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
  ChatState build() {
    // Riverpod Notifier n'appelle jamais une méthode `dispose()` nommée —
    // seul `ref.onDispose(...)` est invoqué. Sans ce hook, les channels
    // Supabase (`messages:<id>`, `typing:<id>`) et le Timer restaient
    // ouverts à chaque fermeture du chat → fuite cumulative (plusieurs
    // WebSocket channels + callbacks encore routés vers un Notifier mort).
    ref.onDispose(_teardownSubscriptions);
    return const ChatState();
  }

  Future<void> loadMessages(String conversationId) async {
    // Si l'utilisateur rouvre le même chat (ou un autre dans la même session
    // du Notifier), on retombe dans `loadMessages` → sans teardown préalable,
    // `_subscribeRealtime` crée un SECOND channel sans unsubscribe du premier
    // → doublons d'`onInsert` + fuite. On nettoie systématiquement.
    _teardownSubscriptions();

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
          // Si le message vient de l'autre participant, on marque
          // immédiatement comme lu (on est sur la vue du chat, donc vu).
          // Cela reset le compteur serveur → la liste conversations et le
          // badge total recomputent via realtime `ConversationUpdated`.
          if (msg.senderId != repo.currentUserId) {
            repo.markRead(conversationId);
          }
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

  void _teardownSubscriptions() {
    _messagesChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _typingTimer?.cancel();
    _messagesChannel = null;
    _typingChannel = null;
    _typingTimer = null;
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
  isAutoDispose: true,
);

// ─── Unread message count ──────────────────────────────────
//
// Dérivé de `conversationsProvider` — une conversation compte dans le badge
// si `unreadCount > 0`. On évite ainsi toute divergence increment/decrement
// manuels (ancienne implémentation dérivait après chaque InboxMessageReceived
// mais ne décrémentait jamais sur markRead → badge qui gonflait à l'infini).
// La source de vérité est le serveur (`conversations.unread_count_{client,pro}`
// mis à jour par le trigger côté DB et remis à 0 par `mark_messages_read`).
// Chaque ConversationUpdated realtime fait recharger conversationsProvider,
// donc ce Provider recalcule automatiquement.
final unreadMessageCountProvider = Provider<int>((ref) {
  final state = ref.watch(conversationsProvider);
  return state.conversations.where((c) => c.unreadCount > 0).length;
});
