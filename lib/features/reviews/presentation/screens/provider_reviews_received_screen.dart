import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';

// ─── Model ──────────────────────────────────────────────

class _Review {
  const _Review({
    required this.id,
    required this.clientName,
    this.clientAvatarUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.serviceName,
  });

  final String id;
  final String clientName;
  final String? clientAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? serviceName;
}

class _ReviewsData {
  const _ReviewsData({
    this.reviews = const [],
    this.averageRating = 0,
    this.distribution = const [0, 0, 0, 0, 0],
  });
  final List<_Review> reviews;
  final double averageRating;
  final List<int> distribution; // index 0 = 5 stars, index 4 = 1 star
}

// ─── Provider ───────────────────────────────────────────

final _reviewsProvider = FutureProvider<_ReviewsData>((ref) async {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return const _ReviewsData();

  final data = await supabase
      .from('reviews')
      .select('*, users!reviews_client_id_fkey(full_name, avatar_url), services(name)')
      .eq('pro_id', uid)
      .order('created_at', ascending: false);

  final reviews = <_Review>[];
  final dist = <int>[0, 0, 0, 0, 0]; // 5, 4, 3, 2, 1
  double total = 0;

  for (final row in data as List) {
    final user = row['users'] as Map<String, dynamic>?;
    final service = row['services'] as Map<String, dynamic>?;
    final rating = (row['rating'] as num?)?.toInt() ?? 5;
    total += rating;
    if (rating >= 1 && rating <= 5) {
      dist[5 - rating]++;
    }
    reviews.add(_Review(
      id: row['id'] as String,
      clientName: user?['full_name'] as String? ?? 'Client',
      clientAvatarUrl: user?['avatar_url'] as String?,
      rating: rating,
      comment: row['comment'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      serviceName: service?['name'] as String?,
    ));
  }

  return _ReviewsData(
    reviews: reviews,
    averageRating: reviews.isEmpty ? 0 : total / reviews.length,
    distribution: dist,
  );
});

// ─── Screen ─────────────────────────────────────────────

/// Reviews list for provider: overall rating, distribution bars, review cards.
/// Route: /pro/profile/reviews
class ProviderReviewsReceivedScreen extends ConsumerStatefulWidget {
  const ProviderReviewsReceivedScreen({super.key});

  @override
  ConsumerState<ProviderReviewsReceivedScreen> createState() =>
      _ProviderReviewsReceivedScreenState();
}

class _ProviderReviewsReceivedScreenState
    extends ConsumerState<ProviderReviewsReceivedScreen> {
  int? _filterRating;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(_reviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: const SpotbookAppBar(title: 'Avis reçus'),
      body: dataAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
        error: (e, _) => Center(
          child: Text('$e',
              style: TextStyle(color: AppColors.gris)),
        ),
        data: (data) {
          final filtered = _filterRating == null
              ? data.reviews
              : data.reviews
                  .where((r) => r.rating == _filterRating)
                  .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            children: [
              // Overall rating header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Big rating
                    Column(
                      children: [
                        Text(
                          data.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < data.averageRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppColors.warning,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.reviews.length} avis',
                          style: GoogleFonts.dmSans(
                              color: AppColors.gris, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Distribution bars
                    Expanded(
                      child: Column(
                        children: List.generate(5, (i) {
                          final stars = 5 - i;
                          final count = data.distribution[i];
                          final maxCount = data.reviews.isEmpty
                              ? 1
                              : data.reviews.length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2),
                            child: Row(
                              children: [
                                Text('$stars',
                                    style: TextStyle(
                                        color: AppColors.gris,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                Icon(Icons.star,
                                    color: AppColors.warning,
                                    size: 12),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: count / maxCount,
                                      backgroundColor:
                                          AppColors.surfaceAlt,
                                      valueColor:
                                          AlwaysStoppedAnimation(
                                              AppColors.warning),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                        color: AppColors.gris,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Filter chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _RatingFilterChip(
                      label: 'Tous',
                      selected: _filterRating == null,
                      onTap: () =>
                          setState(() => _filterRating = null),
                    ),
                    ...List.generate(5, (i) {
                      final stars = 5 - i;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _RatingFilterChip(
                          label: '$stars ★',
                          selected: _filterRating == stars,
                          onTap: () => setState(
                              () => _filterRating = stars),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Review cards
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('Aucun avis',
                        style: TextStyle(
                            color: AppColors.gris, fontSize: 15)),
                  ),
                )
              else
                ...filtered.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(review: r),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _RatingFilterChip extends StatelessWidget {
  const _RatingFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blanc : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.blanc : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: selected ? AppColors.fond : AppColors.blanc,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SpotbookAvatar(
                imageUrl: review.clientAvatarUrl,
                radius: 18,
                name: review.clientName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName,
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy', 'en_US')
                          .format(review.createdAt),
                      style: TextStyle(
                          color: AppColors.gris, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (review.serviceName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                review.serviceName!,
                style: TextStyle(
                    color: AppColors.gris, fontSize: 11),
              ),
            ),
          ],
          if (review.comment != null &&
              review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 13,
                  height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
