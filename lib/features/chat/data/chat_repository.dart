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
    String? tag,
  }) async {
    // Only allow chat if there's a confirmed booking
    if (bookingId != null) {
      final booking = await _supabase
          .from('bookings')
          .select('status')
          .eq('id', bookingId)
          .maybeSingle();

      if (booking == null || booking['status'] != 'confirmed') {
        throw Exception('Chat uniquement disponible avec un rendez-vous confirmé');
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

    // Create new conversation
    final data = await _supabase
        .from('conversations')
        .insert({
          'client_id': clientId,
          'pro_id': proId,
          if (bookingId != null) 'booking_id': bookingId,
          if (tag != null) 'tag': tag,
        })
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

    return MessageModel.fromJson(data);
  }

  Future<String> uploadChatImage(String conversationId, Uint8List bytes) async {
    final uid = currentUserId ?? 'anon';
    final path = '$conversationId/$uid-${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage
        .from('chat-images')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _supabase.storage.from('chat-images').getPublicUrl(path);
  }

  Future<void> markRead(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', uid)
        .eq('is_read', false);
  }

  /// Inbox : changements sur les conversations où l’utilisateur est client ou pro.
  RealtimeChannel subscribeInbox({
    required String userId,
    required void Function() onChange,
  }) {
    return _supabase
        .channel('inbox:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: userId,
          ),
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pro_id',
            value: userId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
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
