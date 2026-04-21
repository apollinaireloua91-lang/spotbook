import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(supabase: Supabase.instance.client);
});

class ChatRepository {
  ChatRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<ConversationModel> getOrCreateConversation({
    required String clientId,
    required String proId,
    String? bookingId,
  }) async {
    // Only allow chat if there's a confirmed booking
    if (bookingId != null) {
      final booking = await _supabase
          .from('bookings')
          .select('status')
          .eq('id', bookingId)
          .maybeSingle();

      if (booking == null || booking['status'] != 'confirmed') {
        throw Exception('Chat is only available with a confirmed booking');
      }
    }

    // Check existing conversation
    final existing = await _supabase
        .from('conversations')
        .select('*, client_user:client_id(full_name, avatar_url), pro_user:pro_id(full_name, avatar_url)')
        .eq('client_id', clientId)
        .eq('pro_id', proId)
        .maybeSingle();

    if (existing != null) {
      return ConversationModel.fromJson(existing, currentUserId ?? '');
    }

    // Create new conversation (upsert to handle race condition)
    final data = await _supabase
        .from('conversations')
        .upsert({
          'client_id': clientId,
          'pro_id': proId,
          'booking_id': bookingId,
        }, onConflict: 'client_id,pro_id')
        .select('*, client_user:client_id(full_name, avatar_url), pro_user:pro_id(full_name, avatar_url)')
        .single();

    return ConversationModel.fromJson(data, currentUserId ?? '');
  }

  Future<List<ConversationModel>> getConversations() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final data = await _supabase
        .from('conversations')
        .select('*, client_user:client_id(full_name, avatar_url), pro_user:pro_id(full_name, avatar_url)')
        .or('client_id.eq.$uid,pro_id.eq.$uid')
        .order('last_message_at', ascending: false);

    return (data as List)
        .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>, uid))
        .toList();
  }

  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 50}) async {
    final data = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    String? content,
    String? imageUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final data = await _supabase
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': uid,
          'content': content,
          'image_url': imageUrl,
        })
        .select()
        .single();

    // Update conversation last_message
    await _supabase.from('conversations').update({
      'last_message': content ?? '📷 Image',
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    // Notify recipient (fire-and-forget)
    _notifyRecipient(conversationId, uid, content ?? '📷 Image');

    return MessageModel.fromJson(data);
  }

  /// Insert a notification for the other user in the conversation.
  Future<void> _notifyRecipient(
    String conversationId,
    String senderId,
    String preview,
  ) async {
    try {
      final conv = await _supabase
          .from('conversations')
          .select('client_id, pro_id')
          .eq('id', conversationId)
          .maybeSingle();
      if (conv == null) return;

      final recipientId = conv['client_id'] == senderId
          ? conv['pro_id'] as String
          : conv['client_id'] as String;

      // Bump unread count for the recipient
      final isRecipientClient = conv['client_id'] == recipientId;
      final unreadCol =
          isRecipientClient ? 'unread_count_client' : 'unread_count_pro';
      await _supabase.rpc('increment_field', params: {
        'table_name': 'conversations',
        'field_name': unreadCol,
        'row_id': conversationId,
      }).catchError((_) {
        // Fallback: plain update if RPC doesn't exist
        return null;
      });

      // Get sender name
      final sender = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', senderId)
          .maybeSingle();
      final senderName = sender?['full_name'] as String? ?? 'Someone';

      final body = preview.length > 80
          ? '${preview.substring(0, 80)}...'
          : preview;

      await _supabase.from('notifications').insert({
        'user_id': recipientId,
        'type': 'new_message',
        'title': 'New message from $senderName',
        'body': body,
        'data': {'conversation_id': conversationId},
        'is_read': false,
      });
    } catch (_) {
      // Non-critical — message was already sent successfully
    }
  }

  Future<String> uploadChatImage(String conversationId, Uint8List bytes) async {
    final uid = currentUserId ?? 'anon';
    final path = '$conversationId/$uid-${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage
        .from('chat-images')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _supabase.storage.from('chat-images').getPublicUrl(path);
  }

  /// Marque comme lus tous les messages non envoyés par le user courant
  /// dans la conversation, via le RPC `mark_messages_read`.
  ///
  /// Avantages vs l'UPDATE direct précédent :
  ///   - enforce `auth.uid() == client_id || pro_id` côté serveur,
  ///   - reset `unread_count_client` / `unread_count_pro` sur la conversation
  ///     (le compteur affiché dans la liste),
  ///   - set `read_at = now()` pour les receipts.
  Future<void> markRead(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _supabase.rpc(
      'mark_messages_read',
      params: {'p_conversation_id': conversationId},
    );
  }

  RealtimeChannel subscribeMessages(
    String conversationId, {
    required void Function(MessageModel message) onInsert,
  }) {
    return _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onInsert(MessageModel.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeTyping(
    String conversationId, {
    required void Function(String userId) onTyping,
  }) {
    return _supabase.channel('typing:$conversationId').onBroadcast(
      event: 'typing',
      callback: (payload) {
        final uid = payload['user_id'] as String?;
        if (uid != null) onTyping(uid);
      },
    ).subscribe();
  }

  void sendTypingIndicator(String conversationId) {
    final uid = currentUserId;
    if (uid == null) return;

    _supabase.channel('typing:$conversationId').sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': uid},
    );
  }
}
