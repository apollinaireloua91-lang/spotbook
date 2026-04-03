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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withAlpha(40),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.violet, width: 2),
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: p.avatarUrl != null
                    ? CachedNetworkImageProvider(p.avatarUrl!)
                    : null,
                child: p.avatarUrl == null
                    ? ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.gradientAccent.createShader(bounds),
                        child: const Text(
                          '😎',
                          style: TextStyle(fontSize: 36),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Name
        Text(
          p.fullName,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        // Handle
        if (p.username != null && p.username!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@${p.username}',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

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
