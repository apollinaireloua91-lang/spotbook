import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../events/data/event_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';

/// Données agrégées pour l’écran profil client (équivalent d’un état « Cubit » chargé une fois).
class ClientProfileScreenData {
  const ClientProfileScreenData({
    required this.profile,
    required this.reviewsCount,
    required this.socialUrls,
    required this.favoritePros,
    required this.favoriteVideos,
    required this.completedBookings,
    required this.tickets,
    required this.isOwnProfile,
    required this.viewerUserId,
    this.viewerRole,
  });

  final ClientProfile profile;
  final int reviewsCount;
  final Map<String, String> socialUrls;
  final List<ClientFavoriteProItem> favoritePros;
  final List<ClientFavoriteVideoItem> favoriteVideos;
  final List<BookingModel> completedBookings;
  final List<TicketModel> tickets;
  final bool isOwnProfile;
  final String viewerUserId;
  final String? viewerRole;
}

/// `profileKey` vide = profil du client connecté ; sinon UUID du profil affiché.
final clientProfileScreenDataProvider = FutureProvider.autoDispose
    .family<ClientProfileScreenData, String>((ref, profileKey) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);

  final sessionUid = profileRepo.currentUserId;
  if (sessionUid == null) {
    throw StateError('not_authenticated');
  }

  final profileUserId = profileKey.isEmpty ? sessionUid : profileKey;
  final profile = await profileRepo.getClientProfile(profileUserId);

  int reviewsCount = 0;
  try {
    reviewsCount = await profileRepo.countReviewsLeftByClient(profileUserId);
  } catch (_) {}

  final socialUrls = await profileRepo.getClientSocialLinkUrls(profileUserId);

  final isOwnProfile = profileUserId == sessionUid;

  var favoritePros = <ClientFavoriteProItem>[];
  var favoriteVideos = <ClientFavoriteVideoItem>[];
  var completedBookings = <BookingModel>[];
  var tickets = <TicketModel>[];

  if (isOwnProfile) {
    try {
      favoritePros = await profileRepo.getClientFavoritePros(sessionUid);
    } catch (_) {}
    try {
      favoriteVideos = await profileRepo.getClientFavoriteVideos(sessionUid);
    } catch (_) {}
    try {
      final allBookings = await bookingRepo.getClientBookings();
      completedBookings =
          allBookings.where((b) => b.status == 'completed').toList();
    } catch (_) {}
    try {
      tickets = await eventRepo.getUserTickets();
    } catch (_) {}
  }

  return ClientProfileScreenData(
    profile: profile,
    reviewsCount: reviewsCount,
    socialUrls: socialUrls,
    favoritePros: favoritePros,
    favoriteVideos: favoriteVideos,
    completedBookings: completedBookings,
    tickets: tickets,
    isOwnProfile: isOwnProfile,
    viewerUserId: sessionUid,
    viewerRole: profileRepo.currentUserRole,
  );
});
