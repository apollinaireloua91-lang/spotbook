import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/catering_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CATERING SECTION WIDGETS — shared between Pro and Client views
// ═════════════════════════════════════════════════════════════════════════════

// ─── Banner ──────────────────────────────────────────────────────────────────

class CateringBanner extends StatelessWidget {
  const CateringBanner({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(0.5, 0.5),
          colors: [AppColors.catering, AppColors.cateringDark],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blanc.withAlpha(26),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Catering Section',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.blanc.withAlpha(204),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Menu Grid (2x2) ────────────────────────────────────────────────────────

class CateringMenuGrid extends StatelessWidget {
  const CateringMenuGrid({
    super.key,
    required this.items,
    this.onAddTap,
  });

  final List<CateringMenuItem> items;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && onAddTap != null) {
      return _AddButton(label: '+ Add dish', onTap: onAddTap!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length > 4 ? 4 : items.length,
          itemBuilder: (context, i) => _MenuItemCard(item: items[i]),
        ),
        if (onAddTap != null) ...[
          const SizedBox(height: 8),
          _AddButton(label: '+ Add dish', onTap: onAddTap!),
        ],
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});

  final CateringMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — emoji or photo
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.catering.withAlpha(35),
                  AppColors.cateringDark.withAlpha(25),
                ],
              ),
            ),
            child: Stack(
              children: [
                if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: item.photoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Center(
                    child: Text(
                      item.displayEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                // Bestseller badge
                if (item.isBestseller)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.catering,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Best',
                        style: GoogleFonts.dmSans(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blanc,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.pricePerPerson != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${item.pricePerPerson!.toStringAsFixed(0)}/person',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.catering,
                      ),
                    ),
                  ],
                  if (item.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!,
                      style: GoogleFonts.dmSans(
                        fontSize: 8,
                        color: AppColors.grisInactif,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Forfait / Package Cards ─────────────────────────────────────────────────

class CateringForfaitList extends StatelessWidget {
  const CateringForfaitList({
    super.key,
    required this.forfaits,
    this.onAddTap,
  });

  final List<CateringForfait> forfaits;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    if (forfaits.isEmpty && onAddTap != null) {
      return _AddButton(label: '+ Add package', onTap: onAddTap!);
    }

    return Column(
      children: [
        for (final f in forfaits) _ForfaitCard(forfait: f),
        if (onAddTap != null) ...[
          const SizedBox(height: 8),
          _AddButton(label: '+ Add package', onTap: onAddTap!),
        ],
      ],
    );
  }
}

class _ForfaitCard extends StatelessWidget {
  const _ForfaitCard({required this.forfait});

  final CateringForfait forfait;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      forfait.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blanc,
                      ),
                    ),
                    if (forfait.isPopular) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.catering.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.catering.withAlpha(60),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Popular',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.catering,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '\$${forfait.pricePerPerson.toStringAsFixed(0)} /pers.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.catering,
                ),
              ),
            ],
          ),
          if (forfait.description != null) ...[
            const SizedBox(height: 4),
            Text(
              forfait.description!,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: AppColors.grisInactif,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (forfait.guestRange.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              forfait.guestRange,
              style: GoogleFonts.dmSans(
                fontSize: 8,
                color: AppColors.grisInactif,
              ),
            ),
          ],
          if (forfait.inclusions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: forfait.inclusions.take(6).map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.catering.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.catering.withAlpha(38),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      color: AppColors.cateringLight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Gallery (horizontal scroll) ─────────────────────────────────────────────

class CateringGalleryRow extends StatelessWidget {
  const CateringGalleryRow({super.key, required this.items});

  final List<CateringGalleryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceAlt),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceAlt),
                  ),
                  if (item.caption != null && item.caption!.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(180),
                            ],
                          ),
                        ),
                        child: Text(
                          item.caption!,
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            color: AppColors.blanc,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Request Quote CTA ───────────────────────────────────────────────────────

class CateringRequestQuoteCTA extends StatelessWidget {
  const CateringRequestQuoteCTA({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.5, -0.5),
            end: Alignment(0.5, 0.5),
            colors: [AppColors.catering, AppColors.cateringDark],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blanc.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.description_outlined,
                    color: AppColors.blanc, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request a Quote',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                  ),
                  Text(
                    'Response in 24-48h · 30% deposit',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: AppColors.blanc.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.blanc, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class CateringSectionHeader extends StatelessWidget {
  const CateringSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        color: AppColors.gris,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─── Add Button (Pro only) ───────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.catering.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.catering.withAlpha(40),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.catering,
            ),
          ),
        ),
      ),
    );
  }
}
