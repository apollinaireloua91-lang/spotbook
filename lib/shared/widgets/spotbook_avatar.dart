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

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (isOnline || isVerified ? 4 : 0),
        height: size + (isOnline || isVerified ? 4 : 0),
        child: Stack(
          children: [
            // Avatar circle
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

            // Verified badge (bottom-right checkmark) — takes priority over online
            if (isVerified && !isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: badgeSize + 2,
                  height: badgeSize + 2,
                  decoration: BoxDecoration(
                    color: AppColors.blanc,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.fond, width: 1.5),
                  ),
                  child: Icon(
                    Icons.check,
                    size: badgeSize - 2,
                    color: AppColors.fond,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
      decoration: const BoxDecoration(
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
