import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/profile_models.dart';

/// Hero section with breathing avatar animation, name, handle, and bio.
class ProfileHero extends StatefulWidget {
  const ProfileHero({super.key, required this.profile});

  final ClientProfile profile;

  @override
  State<ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<ProfileHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Column(
      children: [
        const SizedBox(height: 16),

        // Breathing avatar
        AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _breathAnimation.value),
              child: child,
            );
          },
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientAccent,
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withAlpha(60),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.rose.withAlpha(30),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.fond,
                ),
                padding: const EdgeInsets.all(2),
                child: p.avatarUrl != null
                    ? CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.surfaceAlt,
                        backgroundImage:
                            CachedNetworkImageProvider(p.avatarUrl!),
                      )
                    : Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.gradientAccent,
                        ),
                        child: Center(
                          child: Text(
                            p.fullName.isNotEmpty
                                ? p.fullName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blanc,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Name — Clash Display substitute (DM Sans bold)
        Text(
          p.fullName,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),

        // Handle — from username or email prefix
        Builder(builder: (_) {
          final handle = (p.username != null && p.username!.isNotEmpty)
              ? p.username!
              : p.email.contains('@')
                  ? p.email.split('@').first
                  : null;
          if (handle == null) return const SizedBox(height: 4);
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '@$handle',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),

        // Bio
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
          child: (p.bio != null && p.bio!.trim().isNotEmpty)
              ? Text(
                  p.bio!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc.withAlpha(153),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Text(
                  'Tap to add a bio',
                  style: GoogleFonts.dmSans(
                    color: AppColors.grisInactif,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),

        // City
        if (p.city != null && p.city!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.gris, size: 14),
              const SizedBox(width: 4),
              Text(
                p.city!,
                style: const TextStyle(
                  color: AppColors.gris,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}
