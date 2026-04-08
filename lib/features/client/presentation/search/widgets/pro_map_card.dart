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
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Avatar + Name + Category ──
              Row(
                children: [
                  // Circular avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [catColor, catColor.withAlpha(153)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: pro.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: pro.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                            ),
                          )
                        : Center(
                            child: Text(
                              pro.name.isNotEmpty
                                  ? pro.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blanc,
                                ),
                              ),
                            ),
                            if (pro.online) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pro.category} \u00b7 ${pro.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.gris,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Rating + Distance ──
              Row(
                children: [
                  // Rating or "New" badge
                  if (pro.rating > 0) ...[
                    const Text('\u2B50', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      pro.rating.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ratingAmber,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'New',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.violetClair,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Distance
                  Icon(
                    Icons.near_me_outlined,
                    size: 12,
                    color: AppColors.gris,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${pro.distKm} km',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gris,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
