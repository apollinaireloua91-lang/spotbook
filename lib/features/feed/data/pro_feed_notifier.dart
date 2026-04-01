import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pro_feed_repository.dart';

class ProFeedBadges {
  const ProFeedBadges({
    this.notifications = 0,
    this.bookings = 0,
    this.tickets = 0,
    this.messages = 0,
  });

  final int notifications;
  final int bookings;
  final int tickets;
  final int messages;
}

class ProFeedBadgesNotifier extends Notifier<ProFeedBadges> {
  @override
  ProFeedBadges build() {
    _load();
    return const ProFeedBadges();
  }

  Future<void> _load() async {
    final repo = ref.read(proFeedRepositoryProvider);
    final results = await Future.wait([
      repo.countUnreadNotifications(),
      repo.countPendingBookings(),
      repo.countTicketSales(),
      repo.countUnreadMessages(),
    ]);
    state = ProFeedBadges(
      notifications: results[0],
      bookings: results[1],
      tickets: results[2],
      messages: results[3],
    );
  }

  Future<void> refresh() => _load();
}

final proFeedBadgesProvider =
    NotifierProvider<ProFeedBadgesNotifier, ProFeedBadges>(
  ProFeedBadgesNotifier.new,
  isAutoDispose: true,
);
