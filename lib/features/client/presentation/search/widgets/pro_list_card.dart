import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../models/search_models.dart';
import 'card_3d_tilt.dart';

class ProListCard extends StatelessWidget {
  const ProListCard({
    super.key,
    required this.pro,
    required this.onTap,
  });

  final ProSearchResult pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final catColor = categoryColor(pro.category);

    return Card3DTilt(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              // ── Avatar ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: pro.avatarUrl == null
                      ? LinearGradient(
                          colors: [catColor, catColor.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: pro.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
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
                          style: GoogleFonts.sora(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // ── Info ──
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
                              fontSize: 14,
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
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${categoryEmoji(pro.category)} ${pro.category} · ${pro.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.gris,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\u2B50 ${pro.rating}',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ratingAmber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\uD83D\uDCCD ${pro.distKm} km',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.violet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Price ──
              Text(
                '${pro.priceRange}\$',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.violet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
