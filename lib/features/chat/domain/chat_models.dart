class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.clientId,
    required this.proId,
    this.bookingId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUserName,
    this.otherUserAvatar,
  });

  final String id;
  final String clientId;
  final String proId;
  final String? bookingId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? otherUserName;
  final String? otherUserAvatar;

  factory ConversationModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final isClient = json['client_id'] == currentUserId;
    final otherUser = isClient
        ? json['pro_user'] as Map<String, dynamic>?
        : json['client_user'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      bookingId: json['booking_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      otherUserName: otherUser?['full_name'] as String?,
      otherUserAvatar: otherUser?['avatar_url'] as String?,
    );
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
