import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

// ─── Platform metadata ───────────────────────────────────────────────────────

class SocialPlatformInfo {
  const SocialPlatformInfo({
    required this.key,
    required this.label,
    required this.icon,
    this.hintUrl = 'https://',
    this.brandAssetPath,
  });

  final String key;
  final String label;
  final IconData icon;
  final String hintUrl;

  /// Logo officiel (PNG dans `assets/social/`), affiché à la place de [icon] quand défini.
  final String? brandAssetPath;
}

/// Icône réseau : image marque si [SocialPlatformInfo.brandAssetPath] est défini, sinon Material.
class SocialPlatformBrandIcon extends StatelessWidget {
  const SocialPlatformBrandIcon({
    super.key,
    required this.platform,
    this.size = 24,
    this.iconColor,
    this.brandAssetFit = BoxFit.contain,
  });

  final SocialPlatformInfo platform;
  final double size;
  final Color? iconColor;

  /// [BoxFit.cover] remplit tout le carré (profil pro) ; [BoxFit.contain] pour listes compactes.
  final BoxFit brandAssetFit;

  @override
  Widget build(BuildContext context) {
    final path = platform.brandAssetPath;
    if (path != null && path.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          path,
          fit: brandAssetFit,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => Icon(
            platform.icon,
            size: size,
            color: iconColor ?? AppColors.blanc,
          ),
        ),
      );
    }
    return Icon(
      platform.icon,
      size: size,
      color: iconColor ?? AppColors.blanc,
    );
  }
}

const kAllSocialPlatforms = <SocialPlatformInfo>[
  SocialPlatformInfo(
    key: 'tiktok',
    label: 'TikTok',
    icon: Icons.music_note_outlined,
    hintUrl: 'https://tiktok.com/@...',
    brandAssetPath: 'assets/social/tiktok.png',
  ),
  SocialPlatformInfo(
    key: 'instagram',
    label: 'Instagram',
    icon: Icons.camera_alt_outlined,
    hintUrl: 'https://instagram.com/...',
    brandAssetPath: 'assets/social/instagram.png',
  ),
  SocialPlatformInfo(
    key: 'snapchat',
    label: 'Snapchat',
    icon: Icons.chat_bubble_outline,
    hintUrl: 'https://snapchat.com/add/...',
    brandAssetPath: 'assets/social/snapchat.png',
  ),
  SocialPlatformInfo(
    key: 'youtube',
    label: 'YouTube',
    icon: Icons.play_circle_outline,
    hintUrl: 'https://youtube.com/@...',
  ),
  SocialPlatformInfo(
    key: 'facebook',
    label: 'Facebook',
    icon: Icons.facebook_outlined,
    hintUrl: 'https://facebook.com/...',
  ),
  SocialPlatformInfo(
    key: 'twitter',
    label: 'X / Twitter',
    icon: Icons.alternate_email,
    hintUrl: 'https://x.com/...',
    brandAssetPath: 'assets/social/twitter_x.png',
  ),
  SocialPlatformInfo(
    key: 'pinterest',
    label: 'Pinterest',
    icon: Icons.push_pin_outlined,
    hintUrl: 'https://pinterest.com/...',
  ),
];

SocialPlatformInfo? platformInfoFor(String key) {
  for (final p in kAllSocialPlatforms) {
    if (p.key == key) return p;
  }
  return null;
}

// ─── Link a specific platform ────────────────────────────────────────────────

/// Bottom sheet that lets the Pro paste the URL of a social profile.
///
/// Returns the URL string on save, or `null` on cancel.
class SocialLinkBottomSheet extends StatefulWidget {
  const SocialLinkBottomSheet({
    super.key,
    required this.platform,
    this.currentUrl,
  });

  final SocialPlatformInfo platform;
  final String? currentUrl;

  @override
  State<SocialLinkBottomSheet> createState() => _SocialLinkBottomSheetState();
}

class _SocialLinkBottomSheetState extends State<SocialLinkBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUrl ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.platform;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon + title
          SocialPlatformBrandIcon(platform: p, size: 32),
          const SizedBox(height: 12),
          Text(
            'Link ${p.label}',
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Paste your ${p.label} profile link',
            style: TextStyle(color: AppColors.gris, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // URL field
          TextField(
            controller: _controller,
            style: TextStyle(color: AppColors.blanc, fontSize: 14),
            decoration: InputDecoration(
              hintText: p.hintUrl,
              hintStyle: TextStyle(
                color: AppColors.gris.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.blanc),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.gris, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final url = _controller.text.trim();
                    if (url.isNotEmpty) {
                      Navigator.of(context).pop(url);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blanc,
                    foregroundColor: AppColors.fond,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add a new platform ──────────────────────────────────────────────────────

/// Bottom sheet that shows a grid of social platforms not yet added.
///
/// Returns the [SocialPlatformInfo] that was selected, or `null` on dismiss.
class AddSocialPlatformSheet extends StatelessWidget {
  const AddSocialPlatformSheet({
    super.key,
    required this.alreadyAdded,
  });

  /// Platform keys already present on the profile.
  final Set<String> alreadyAdded;

  @override
  Widget build(BuildContext context) {
    final available = kAllSocialPlatforms
        .where((p) => !alreadyAdded.contains(p.key))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ADD A NETWORK',
            style: TextStyle(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (available.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'All networks have been added.',
                style: TextStyle(color: AppColors.gris, fontSize: 13),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: available.map((p) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(p),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: SocialPlatformBrandIcon(platform: p, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.label,
                        style: TextStyle(
                          color: AppColors.grisClair,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
