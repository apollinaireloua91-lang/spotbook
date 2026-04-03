/// Typed events emitted by [RealtimeManager] channels.
///
/// Each feature listens to a specific stream and reacts to these events
/// to update its state without polling.
library;

// ─── Base ──────────────────────────────────────────────────

sealed class RealtimeEvent {
  const RealtimeEvent();
}

// ─── Feed ──────────────────────────────────────────────────

/// A new video was approved and should appear in the feed.
final class FeedNewPost extends RealtimeEvent {
  const FeedNewPost({required this.videoId, required this.proId});
  final String videoId;
  final String proId;
}

/// A video's counters (likes, comments, views) changed.
final class FeedPostUpdated extends RealtimeEvent {
  const FeedPostUpdated({
    required this.videoId,
    this.likesCount,
    this.commentsCount,
    this.viewsCount,
    this.savesCount,
  });
  final String videoId;
  final int? likesCount;
  final int? commentsCount;
  final int? viewsCount;
  final int? savesCount;
}

// ─── Bookings ──────────────────────────────────────────────

/// A new booking was created (relevant for Pro).
final class BookingCreated extends RealtimeEvent {
  const BookingCreated({required this.bookingId, required this.raw});
  final String bookingId;
  final Map<String, dynamic> raw;
}

/// A booking's status changed (confirmed, cancelled, completed, etc.).
final class BookingStatusChanged extends RealtimeEvent {
  const BookingStatusChanged({
    required this.bookingId,
    required this.newStatus,
    required this.raw,
  });
  final String bookingId;
  final String newStatus;
  final Map<String, dynamic> raw;
}

// ─── Notifications ─────────────────────────────────────────

/// A new notification was inserted.
final class NotificationReceived extends RealtimeEvent {
  const NotificationReceived({required this.raw});
  final Map<String, dynamic> raw;
}

// ─── Tickets ───────────────────────────────────────────────

/// A ticket was sold (relevant for Pro).
final class TicketSold extends RealtimeEvent {
  const TicketSold({required this.raw});
  final Map<String, dynamic> raw;
}

/// A client's ticket status changed.
final class TicketUpdated extends RealtimeEvent {
  const TicketUpdated({required this.ticketId, required this.raw});
  final String ticketId;
  final Map<String, dynamic> raw;
}

// ─── Catering ──────────────────────────────────────────────

/// A new catering submission for a Pro.
final class CateringSubmissionReceived extends RealtimeEvent {
  const CateringSubmissionReceived({required this.raw});
  final Map<String, dynamic> raw;
}

// ─── Conversations ─────────────────────────────────────────

/// A conversation was updated (new last_message, reorder inbox).
final class ConversationUpdated extends RealtimeEvent {
  const ConversationUpdated({required this.conversationId, required this.raw});
  final String conversationId;
  final Map<String, dynamic> raw;
}

/// A new message arrived in any conversation (for unread badge).
final class InboxMessageReceived extends RealtimeEvent {
  const InboxMessageReceived({
    required this.conversationId,
    required this.senderId,
  });
  final String conversationId;
  final String senderId;
}

// ─── Presence ──────────────────────────────────────────────

/// Updated set of online Pro IDs.
final class PresenceUpdated extends RealtimeEvent {
  const PresenceUpdated({required this.onlineProIds});
  final Set<String> onlineProIds;
}
