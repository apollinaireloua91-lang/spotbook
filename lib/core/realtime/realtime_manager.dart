import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'realtime_events.dart';

/// Central service that manages ALL Supabase Realtime subscriptions.
///
/// Initialised once at login with [initialize] and torn down at logout
/// with [dispose]. Feature-level Notifiers subscribe to the typed streams
/// exposed here — they never create their own Postgres Changes channels.
///
/// Channels managed: feed, bookings (client & pro), notifications,
/// tickets, catering submissions, conversations/inbox, presence.
class RealtimeManager {
  RealtimeManager(this._supabase);

  final SupabaseClient _supabase;
  final List<RealtimeChannel> _channels = [];
  bool _initialised = false;

  // ─── Streams exposed to Notifiers ────────────────────────

  final _feedController = StreamController<RealtimeEvent>.broadcast();
  final _bookingController = StreamController<RealtimeEvent>.broadcast();
  final _notifController = StreamController<RealtimeEvent>.broadcast();
  final _ticketController = StreamController<RealtimeEvent>.broadcast();
  final _cateringController = StreamController<RealtimeEvent>.broadcast();
  final _conversationController = StreamController<RealtimeEvent>.broadcast();
  final _presenceController = StreamController<PresenceUpdated>.broadcast();

  Stream<RealtimeEvent> get feedStream => _feedController.stream;
  Stream<RealtimeEvent> get bookingStream => _bookingController.stream;
  Stream<RealtimeEvent> get notificationStream => _notifController.stream;
  Stream<RealtimeEvent> get ticketStream => _ticketController.stream;
  Stream<RealtimeEvent> get cateringStream => _cateringController.stream;
  Stream<RealtimeEvent> get conversationStream => _conversationController.stream;
  Stream<PresenceUpdated> get presenceStream => _presenceController.stream;

  // ─── Lifecycle ───────────────────────────────────────────

  /// Last-seen role, used to detect role changes and avoid redundant re-subs.
  String? _currentRole;
  String? _currentUserId;

  /// Call once after successful authentication.
  void initialize({required String userId, required String role}) {
    if (_initialised) return;
    _initialised = true;
    _currentRole = role;
    _currentUserId = userId;

    _subscribeFeed();
    _subscribeNotifications(userId);
    _subscribeConversations(userId);

    if (role == 'client') {
      _subscribeClientBookings(userId);
      _subscribeClientTickets(userId);
    } else if (role == 'pro') {
      _subscribeProBookings(userId);
      _subscribeProTicketSales(userId);
      _subscribeCateringSubmissions(userId);
      _subscribeProPresence(userId);
    }

    debugPrint('[RealtimeManager] initialised for $role ($userId) '
        '— ${_channels.length} channels');
  }

  /// Re-subscribe for a (possibly new) role WITHOUT closing the stream
  /// controllers. Used when the user's role changes mid-session (e.g. after
  /// RoleSelectionScreen completes on a Google sign-up that had no role yet).
  ///
  /// No-op if [role] matches the current role for the same user.
  void reinitializeForRole({required String userId, required String role}) {
    if (_initialised && _currentUserId == userId && _currentRole == role) {
      return; // nothing changed
    }

    // Tear down channels only — keep controllers alive so existing listeners
    // (BookingNotifier, etc.) stay connected to the typed streams.
    for (final ch in _channels) {
      _supabase.removeChannel(ch);
    }
    _channels.clear();
    _initialised = false;

    initialize(userId: userId, role: role);
    debugPrint('[RealtimeManager] reinitialised for role change → $role');
  }

  /// Current role the manager is subscribed for, or null if not initialised.
  String? get currentRole => _currentRole;

  /// Tear down et re-abonne tous les channels avec le rôle courant, sans
  /// fermer les StreamControllers.
  ///
  /// Utilisé quand on sait que la socket WebSocket est morte mais que
  /// l'utilisateur est toujours loggé — typiquement au retour de background
  /// sur iOS, où le système a suspendu la socket silencieusement pendant
  /// que l'app dormait. Supabase n'envoie pas toujours un `tokenRefreshed`
  /// dans ce cas → sans resubscribe explicite, l'user voit un feed / des
  /// notifs figés tant qu'il ne relance pas l'app.
  void reconnect() {
    final uid = _currentUserId;
    final role = _currentRole;
    if (uid == null || role == null || !_initialised) return;

    for (final ch in _channels) {
      _supabase.removeChannel(ch);
    }
    _channels.clear();
    _initialised = false;

    initialize(userId: uid, role: role);
    debugPrint('[RealtimeManager] reconnected ($role) after lifecycle resume');
  }

  /// Call on logout — tears down every channel and cleans up streams.
  void dispose() {
    for (final ch in _channels) {
      _supabase.removeChannel(ch);
    }
    _channels.clear();
    _initialised = false;
    _currentRole = null;
    _currentUserId = null;

    _feedController.close();
    _bookingController.close();
    _notifController.close();
    _ticketController.close();
    _cateringController.close();
    _conversationController.close();
    _presenceController.close();

    debugPrint('[RealtimeManager] disposed — all channels removed');
  }

  // ─── Feed (videos) ──────────────────────────────────────

  void _subscribeFeed() {
    final channel = _supabase
        .channel('rt:videos')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'videos',
          callback: (payload) {
            final r = payload.newRecord;
            // Only surface approved videos
            if (r['status'] == 'approved') {
              _feedController.add(FeedNewPost(
                videoId: r['id'] as String,
                proId: r['pro_id'] as String,
              ));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'videos',
          callback: (payload) {
            final r = payload.newRecord;
            final old = payload.oldRecord;

            // Video just got approved → treat as new post
            if (old['status'] != 'approved' && r['status'] == 'approved') {
              _feedController.add(FeedNewPost(
                videoId: r['id'] as String,
                proId: r['pro_id'] as String,
              ));
              return;
            }

            // Counters changed
            if (r['status'] == 'approved') {
              _feedController.add(FeedPostUpdated(
                videoId: r['id'] as String,
                likesCount: r['likes_count'] as int?,
                commentsCount: r['comments_count'] as int?,
                viewsCount: r['views_count'] as int?,
                savesCount: r['saves_count'] as int?,
              ));
            }
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Notifications ──────────────────────────────────────

  void _subscribeNotifications(String userId) {
    final channel = _supabase
        .channel('rt:notifs:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _notifController.add(NotificationReceived(raw: payload.newRecord));
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Client bookings ───────────────────────────────────

  void _subscribeClientBookings(String clientId) {
    final channel = _supabase
        .channel('rt:bookings:client:$clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: clientId,
          ),
          callback: (payload) {
            final r = payload.newRecord;
            _bookingController.add(BookingStatusChanged(
              bookingId: r['id'] as String,
              newStatus: r['status'] as String? ?? '',
              raw: r,
            ));
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Pro bookings ──────────────────────────────────────

  void _subscribeProBookings(String proId) {
    final channel = _supabase
        .channel('rt:bookings:pro:$proId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pro_id',
            value: proId,
          ),
          callback: (payload) {
            final r = payload.newRecord;
            _bookingController.add(BookingCreated(
              bookingId: r['id'] as String,
              raw: r,
            ));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pro_id',
            value: proId,
          ),
          callback: (payload) {
            final r = payload.newRecord;
            _bookingController.add(BookingStatusChanged(
              bookingId: r['id'] as String,
              newStatus: r['status'] as String? ?? '',
              raw: r,
            ));
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Client tickets ────────────────────────────────────

  void _subscribeClientTickets(String clientId) {
    final channel = _supabase
        .channel('rt:tickets:client:$clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: clientId,
          ),
          callback: (payload) {
            final r = payload.newRecord;
            _ticketController.add(TicketUpdated(
              ticketId: r['id'] as String,
              raw: r,
            ));
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Pro ticket sales ──────────────────────────────────

  void _subscribeProTicketSales(String proId) {
    // Listen globally for new tickets; the Pro's events are filtered
    // in the notifier by matching event_id.
    final channel = _supabase
        .channel('rt:tickets:pro:$proId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            _ticketController.add(TicketSold(raw: payload.newRecord));
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Catering submissions ──────────────────────────────

  void _subscribeCateringSubmissions(String proId) {
    final channel = _supabase
        .channel('rt:catering:$proId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'catering_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pro_id',
            value: proId,
          ),
          callback: (payload) {
            _cateringController
                .add(CateringSubmissionReceived(raw: payload.newRecord));
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Conversations / Inbox ─────────────────────────────

  void _subscribeConversations(String userId) {
    // Listen for conversation updates (last_message_at changed → reorder inbox).
    final channel = _supabase
        .channel('rt:conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            final r = payload.newRecord;
            // Only surface if this user is part of the conversation
            if (r['client_id'] == userId || r['pro_id'] == userId) {
              _conversationController.add(ConversationUpdated(
                conversationId: r['id'] as String,
                raw: r,
              ));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final r = payload.newRecord;
            final senderId = r['sender_id'] as String?;
            // Only fire for messages sent by other people
            if (senderId != null && senderId != userId) {
              _conversationController.add(InboxMessageReceived(
                conversationId: r['conversation_id'] as String,
                senderId: senderId,
              ));
            }
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  // ─── Presence (Pro online/offline) ─────────────────────

  void _subscribeProPresence(String proId) {
    final channel = _supabase.channel('pro-presence');
    channel
        .onPresenceSync((_) {
          final presenceList = channel.presenceState();
          final onlineIds = <String>{};
          for (final singleState in presenceList) {
            for (final p in singleState.presences) {
              final id = p.payload['pro_id'] as String?;
              if (id != null) onlineIds.add(id);
            }
          }
          _presenceController.add(PresenceUpdated(onlineProIds: onlineIds));
        })
        .subscribe((status, _) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await channel.track({
              'pro_id': proId,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });
    _channels.add(channel);
  }
}

// ─── Riverpod Provider ─────────────────────────────────────

/// Singleton provider — created once, survives until explicitly disposed.
///
/// Usage:
/// ```dart
/// final rtManager = ref.read(realtimeManagerProvider);
/// rtManager.initialize(userId: uid, role: 'client');
/// ```
final realtimeManagerProvider = Provider<RealtimeManager>((ref) {
  final manager = RealtimeManager(Supabase.instance.client);
  ref.onDispose(manager.dispose);
  return manager;
});
