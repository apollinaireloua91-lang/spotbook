import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../models/search_models.dart';
import 'card_3d_tilt.dart';

class ProMapCard extends StatelessWidget {
  const ProMapCard({
    super.key,
    required this.pro,
    required this.isSelected,
    required this.onTap,
    required this.onBook,
    required this.onViewProfile,
  });

  final ProSearchResult pro;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final catColor = categoryColor(pro.category);

    return Card3DTilt(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt.withAlpha(242),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.violet.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Avatar + Name + Category ──
                  Row(
                    children: [
                      // Avatar with category gradient
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [catColor, catColor.withValues(alpha: 0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: pro.avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: pro.avatarUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  pro.name.isNotEmpty
                                      ? pro.name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blanc,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    pro.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.blanc,
                                    ),
                                  ),
                                ),
                                if (pro.online) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${categoryEmoji(pro.category)} ${pro.category} · ${pro.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: AppColors.gris,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Tags: rating · reviews · distance · price ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _tag('\u2B50 ${pro.rating}', AppColors.ratingAmber),
                      _tag('${pro.reviews} avis', AppColors.grisInactif),
                      _tag(
                        '\uD83D\uDCCD ${pro.distKm} km',
                        AppColors.violet,
                      ),
                      _tag(
                        '\uD83D\uDCB0 ${pro.priceRange}\$',
                        AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onViewProfile,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Voir profil',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blanc,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: onBook,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.violet,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '\uD83D\uDCC5 Réserver',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blanc,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
