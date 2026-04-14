import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';

/// Left column + bottom overlay for ProFeedScreen.
///
/// Layout: Book CTA (gradient pill) → Pro name + verified badge → title.
class PostLeftColumnPro extends StatelessWidget {
  const PostLeftColumnPro({
    super.key,
    required this.video,
    this.onBook,
  });

  final VideoModel video;

  /// When non-null, the "Réserver" CTA pill is shown (hidden on own posts).
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final v = video;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Réserver CTA — premium gradient pill with glow ──
        if (onBook != null) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBook!();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                gradient: AppColors.gradientAccent,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withAlpha(100),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: AppColors.violet.withAlpha(30),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Réserver',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Pro name + verified badge ──
        GestureDetector(
          onTap: () => context.push('/pro/${v.proId}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  v.proName ?? 'Pro',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              // Verified badge — gradient circle with check
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withAlpha(60),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 11),
              ),
              const SizedBox(width: 6),
              // PRO badge — frosted glass pill
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: Text(
                      'PRO',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Video title ──
        if (v.title.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            v.title,
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 6),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

      ],
    );
  }
}
