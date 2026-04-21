import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/review_repository.dart';
import '../../domain/review_model.dart';

/// Lists the client's completed bookings that haven't been reviewed yet.
/// Tapping a row opens the existing `/review` route which writes a row
/// into `reviews`; the DB trigger `tr_review_update_rating` then
/// recomputes the pro's average rating + review count automatically.
final clientReviewableBookingsProvider = FutureProvider.autoDispose<
    List<ReviewableBookingItem>>((ref) async {
  final repo = ref.read(reviewRepositoryProvider);
  return repo.getReviewableBookings();
});

class ClientReviewsInboxScreen extends ConsumerWidget {
  const ClientReviewsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(clientReviewableBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l.reviewsLabel,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) return const _EmptyReviews();
          return RefreshIndicator(
            color: AppColors.violet,
            backgroundColor: AppColors.surface,
            onRefresh: () async =>
                ref.invalidate(clientReviewableBookingsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == 0) return const _InboxHeader();
                return _ReviewableCard(item: items[i - 1]);
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.violet),
        ),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(clientReviewableBookingsProvider),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER — sets the tone: "Your past bookings, ready to be rated"
// ═════════════════════════════════════════════════════════════════════════════

class _InboxHeader extends StatelessWidget {
  const _InboxHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notez vos pros',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Votre avis les aide à grandir. Chaque note est synchronisée '
            'instantanément avec leur profil.',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD — one reviewable booking
// ═════════════════════════════════════════════════════════════════════════════

class _ReviewableCard extends StatelessWidget {
  const _ReviewableCard({required this.item});
  final ReviewableBookingItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/review', extra: <String, String>{
          'bookingId': item.bookingId,
          'proId': item.proId,
          if (item.serviceName != null) 'serviceName': item.serviceName!,
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProAvatar(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.proDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.serviceName ??
                            item.proCategory ??
                            'Prestation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event_available_rounded,
                              color: AppColors.grisInactif, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yyyy', 'fr')
                                .format(item.completedAt.toLocal()),
                            style: GoogleFonts.dmSans(
                              color: AppColors.grisInactif,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _EmptyStarsPreview(),
              ],
            ),
            const SizedBox(height: 12),
            const _RatePill(),
          ],
        ),
      ),
    );
  }
}

class _ProAvatar extends StatelessWidget {
  const _ProAvatar({required this.item});
  final ReviewableBookingItem item;

  @override
  Widget build(BuildContext context) {
    // Gradient ring feels purposeful — hints that this card is an action,
    // not just a record.
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientAccent,
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.fond,
        ),
        padding: const EdgeInsets.all(1.5),
        child: CircleAvatar(
          backgroundColor: AppColors.surfaceAlt,
          backgroundImage: item.proAvatarUrl != null
              ? CachedNetworkImageProvider(item.proAvatarUrl!)
              : null,
          child: item.proAvatarUrl == null
              ? Text(
                  item.proDisplayName.isNotEmpty
                      ? item.proDisplayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _EmptyStarsPreview extends StatelessWidget {
  const _EmptyStarsPreview();

  @override
  Widget build(BuildContext context) {
    // A row of 5 outlined stars — communicates "not yet rated" at a glance.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (_) {
        return Padding(
          padding: const EdgeInsets.only(left: 1),
          child: Icon(
            Icons.star_rounded,
            size: 13,
            color: AppColors.grisInactif.withAlpha(120),
          ),
        );
      }),
    );
  }
}

class _RatePill extends StatelessWidget {
  const _RatePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradientAccent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withAlpha(48),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded,
              color: AppColors.textOnPrimary, size: 16),
          const SizedBox(width: 6),
          Text(
            'Laisser un avis',
            style: GoogleFonts.dmSans(
              color: AppColors.textOnPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded,
              color: AppColors.textOnPrimary, size: 14),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY / ERROR
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violet.withAlpha(20),
              border: Border.all(
                color: AppColors.violet.withAlpha(50),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Icon(Icons.star_border_rounded,
                  color: AppColors.violetClair, size: 38),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Aucun avis à laisser',
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les pros que vous aurez réservés apparaîtront ici '
            'une fois votre rendez-vous terminé.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.dmSans(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
