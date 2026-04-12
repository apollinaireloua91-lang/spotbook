import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';

/// Bottom-left overlay for the Client feed.
/// Layout (bottom → top): caption → @proName bold 16px → "Book" violet pill with glow.
class ClientBottomInfo extends StatelessWidget {
  const ClientBottomInfo({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── @proName + verified badge ──
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '@${video.proName ?? 'Pro'}',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(
                        color: Color(0xCC000000),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
              const SizedBox(width: 10),
              // ── "Book" violet pill ──
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/pro/${video.proId}');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.violet,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(100),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Book',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Caption ──
        if (video.title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            video.title,
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(220),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
              shadows: const [
                Shadow(color: Color(0x99000000), blurRadius: 6),
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
