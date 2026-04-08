import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SpotbookAvatar extends StatelessWidget {
  const SpotbookAvatar({
    super.key,
    this.imageUrl,
    this.name,
    required this.radius,
    this.isOnline = false,
    this.isVerified = false,
    this.onTap,
  });

  final String? imageUrl;

  /// Used for initials fallback when [imageUrl] is null or fails.
  final String? name;
  final double radius;
  final bool isOnline;
  final bool isVerified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;
    final double badgeSize = radius * 0.45;
    final bool hasBadge = isOnline || isVerified;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (hasBadge ? 4 : 0),
        height: size + (hasBadge ? 4 : 0),
        child: Stack(
          children: [
            // Gradient ring for verified pros
            if (isVerified)
              Positioned(
                top: 0,
                left: 0,
                child: _GradientRing(radius: radius),
              )
            else
              Positioned(
                top: 0,
                left: 0,
                child: _AvatarCircle(
                  imageUrl: imageUrl,
                  name: name,
                  radius: radius,
                  size: size,
                ),
              ),

            // Avatar circle (inside ring for verified)
            if (isVerified)
              Positioned(
                top: 3,
                left: 3,
                child: _AvatarCircle(
                  imageUrl: imageUrl,
                  name: name,
                  radius: radius - 3,
                  size: size - 6,
                ),
              ),

            // Online badge (bottom-right green dot)
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.fond, width: 2),
                  ),
                ),
              ),

            // Verified badge (bottom-right checkmark)
            if (isVerified && !isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: badgeSize + 2,
                  height: badgeSize + 2,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.fond, width: 1.5),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: badgeSize - 2,
                    color: AppColors.blanc,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient ring (anneau dégradé animé pour les pros vérifiés) ──────────────

class _GradientRing extends StatefulWidget {
  const _GradientRing({required this.radius});

  final double radius;

  @override
  State<_GradientRing> createState() => _GradientRingState();
}

class _GradientRingState extends State<_GradientRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.rotate(
          angle: _ctrl.value * 2 * math.pi,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppColors.violet,
                  AppColors.rose,
                  AppColors.violetClair,
                  AppColors.violet,
                ],
                stops: const [0.0, 0.33, 0.66, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Avatar circle ────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.imageUrl,
    required this.name,
    required this.radius,
    required this.size,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final double size;

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _InitialsAvatar(
            initials: _initials,
            size: size,
          ),
          errorWidget: (_, __, ___) => _InitialsAvatar(
            initials: _initials,
            size: size,
          ),
        ),
      );
    }

    return _InitialsAvatar(initials: _initials, size: size);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.grisClair,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
