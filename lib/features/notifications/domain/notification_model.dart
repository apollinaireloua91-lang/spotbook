class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.bookingReminder = true,
    this.bookingUpdate = true,
    this.chat = true,
    this.reviewRequest = true,
    this.marketing = false,
    this.waitlist = true,
  });

  final bool bookingReminder;
  final bool bookingUpdate;
  final bool chat;
  final bool reviewRequest;
  final bool marketing;
  final bool waitlist;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      bookingReminder: json['booking_reminder_enabled'] as bool? ?? true,
      bookingUpdate: json['booking_update_enabled'] as bool? ?? true,
      chat: json['chat_enabled'] as bool? ?? true,
      reviewRequest: json['review_request_enabled'] as bool? ?? true,
      marketing: json['marketing_enabled'] as bool? ?? false,
      waitlist: json['waitlist_enabled'] as bool? ?? true,
    );
  }
}
