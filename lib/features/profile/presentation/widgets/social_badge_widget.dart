import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_colors.dart';

class SocialBadgeWidget extends StatelessWidget {
  const SocialBadgeWidget({
    super.key,
    required this.platform,
    required this.followersCount,
    this.handle,
    this.compact = false,
  });

  final String platform;
  final int followersCount;
  final String? handle;
  final bool compact;

  static String formatReach(int count) {
    if (count >= 1000000) {
      final v = count / 1000000;
      return v >= 10 ? '${v.round()}M' : '${v.toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      final v = count / 1000;
      return v >= 100 ? '${v.round()}K' : '${v.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _openLink() {
    if (handle == null || handle!.isEmpty) return;
    final url = handle!.startsWith('http') ? handle! : 'https://$handle';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (followersCount < 10000 && compact) return const SizedBox.shrink();

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SocialIcon.small(platform: platform),
          const SizedBox(width: 6),
          Text(
            formatReach(followersCount),
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _openLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SocialIcon.small(platform: platform),
            if (followersCount >= 10000) ...[
              const SizedBox(width: 4),
              Text(
                formatReach(followersCount),
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row of tappable social icons for the public profile.
class SocialLinksRow extends StatelessWidget {
  const SocialLinksRow({super.key, required this.connections});

  final List<dynamic> connections;

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: connections.map((conn) {
        final platform = conn.platform as String;
        final handle = conn.handle as String;

        return GestureDetector(
          onTap: () {
            final url =
                handle.startsWith('http') ? handle : 'https://$handle';
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
          child: SocialIcon(platform: platform),
        );
      }).toList(),
    );
  }
}

// ─── Social Icon with real brand SVGs ───────────────────────────────────

class SocialIcon extends StatelessWidget {
  const SocialIcon({super.key, required this.platform, this.size = 40});

  const SocialIcon.small({super.key, required this.platform}) : size = 20;

  final String platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isSmall = size <= 20;
    if (isSmall) {
      return SvgPicture.string(
        _svgFor(platform),
        width: size,
        height: size,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColorFor(platform),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.string(
          _svgFor(platform),
          width: size * 0.5,
          height: size * 0.5,
        ),
      ),
    );
  }

  static Color _bgColorFor(String platform) {
    return switch (platform.toLowerCase()) {
      'instagram' => AppColors.brandInstagram,
      'tiktok' => AppColors.brandTikTokDark,
      'snapchat' => AppColors.brandSnapchat,
      'twitter' || 'x' => AppColors.fond,
      'youtube' => AppColors.brandYouTube,
      'facebook' => AppColors.brandFacebook,
      'pinterest' => AppColors.brandPinterest,
      'spotify' => AppColors.spotifyGreen,
      _ => AppColors.surfaceAlt,
    };
  }

  static String _svgFor(String platform) {
    return switch (platform.toLowerCase()) {
      'instagram' => _instagramSvg,
      'tiktok' => _tiktokSvg,
      'snapchat' => _snapchatSvg,
      'twitter' || 'x' => _xSvg,
      'youtube' => _youtubeSvg,
      'facebook' => _facebookSvg,
      'pinterest' => _pinterestSvg,
      'spotify' => _spotifySvg,
      _ => _linkSvg,
    };
  }

  static const _instagramSvg = '''
<svg viewBox="0 0 24 24" fill="white">
  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
</svg>''';

  static const _tiktokSvg = '''
<svg viewBox="0 0 24 24" fill="white">
  <path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-2.88 2.5 2.89 2.89 0 01-2.89-2.89 2.89 2.89 0 012.89-2.89c.28 0 .54.04.79.1v-3.5a6.37 6.37 0 00-.79-.05A6.34 6.34 0 003.15 15a6.34 6.34 0 006.34 6.34 6.34 6.34 0 006.34-6.34V8.75a8.18 8.18 0 004.77 1.52V6.82a4.83 4.83 0 01-1.01-.13z"/>
</svg>''';

  static const _snapchatSvg = '''
<svg viewBox="0 0 24 24" fill="black">
  <path d="M12.206.793c.99 0 4.347.276 5.93 3.821.529 1.193.403 3.219.299 4.847l-.003.06c-.012.18-.022.345-.03.51.075.045.203.09.401.09.3-.016.659-.12.922-.256.14-.072.28-.12.411-.12.221 0 .391.1.476.208.098.141.105.313.02.494-.15.304-.59.543-.928.639-.18.06-.34.1-.43.14a.96.96 0 00-.27.18c-.076.09-.09.21-.03.36.22.58.52 1.11.9 1.59.58.72 1.32 1.29 2.2 1.71.18.09.33.17.41.25.12.12.12.28.06.4-.12.24-.48.43-.78.53-.36.12-.78.18-1.11.18-.17 0-.27-.01-.34-.02h-.05c-.24.01-.48.04-.69.1-.19.05-.38.15-.55.29-.2.18-.35.43-.52.78-.19.4-.45.83-.86 1.17-.4.33-.9.54-1.42.65-.35.08-.71.12-1.07.14-.15.01-.33.02-.52.03-.71.05-1.6.1-2.62.74-.4.24-.79.52-1.22.86-1.16.88-2.46 1.07-3.65.54-.22-.1-.39-.22-.52-.36-.13-.14-.27-.29-.58-.29h-.02c-.16 0-.35.09-.56.2-.3.16-.67.37-1.11.37-.5 0-.84-.27-.97-.4-.49-.49-.65-1.12-.73-1.69a3.4 3.4 0 00-.04-.3l-.01-.03c-.03-.09-.12-.22-.32-.32-.2-.1-.43-.16-.67-.2-.12-.02-.3-.03-.49-.03a7.36 7.36 0 00-.7.03c-.15.01-.32.03-.49.03-.27 0-.62-.04-.97-.18-.44-.17-.83-.48-.87-.94-.02-.21.05-.4.22-.56.07-.07.2-.14.37-.22.92-.42 1.66-1 2.22-1.72.38-.48.68-.99.89-1.58.06-.15.05-.27-.03-.36a.96.96 0 00-.27-.18c-.09-.04-.25-.08-.43-.14-.34-.1-.78-.34-.93-.64-.08-.18-.08-.39.02-.49.08-.11.25-.21.48-.21.13 0 .27.05.41.12.26.14.62.24.92.26.2 0 .33-.05.4-.09a21.13 21.13 0 01-.03-.51l-.004-.06c-.1-1.63-.23-3.65.3-4.86C7.39 1.08 10.77.78 11.76.78l.46.01z"/>
</svg>''';

  static const _xSvg = '''
<svg viewBox="0 0 24 24" fill="white">
  <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
</svg>''';

  static const _youtubeSvg = '''
<svg viewBox="0 0 24 24" fill="white">
  <path d="M23.498 6.186a3.016 3.016 0 00-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 00.502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 002.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 002.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
</svg>''';

  static const _facebookSvg = '''
<svg viewBox="0 0 24 24" fill="white">
  <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
</svg>''';

  static const _pinterestSvg = '''
<svg viewBox="0 0 24 24" fill="white">
  <path d="M12.017 0C5.396 0 .029 5.367.029 11.987c0 5.079 3.158 9.417 7.618 11.162-.105-.949-.199-2.403.041-3.439.219-.937 1.406-5.957 1.406-5.957s-.359-.72-.359-1.781c0-1.668.967-2.914 2.171-2.914 1.023 0 1.518.769 1.518 1.69 0 1.029-.655 2.568-.994 3.995-.283 1.194.599 2.169 1.777 2.169 2.133 0 3.772-2.249 3.772-5.495 0-2.873-2.064-4.882-5.012-4.882-3.414 0-5.418 2.561-5.418 5.207 0 1.031.397 2.138.893 2.738a.36.36 0 01.083.345l-.333 1.36c-.053.22-.174.267-.402.161-1.499-.698-2.436-2.889-2.436-4.649 0-3.785 2.75-7.262 7.929-7.262 4.163 0 7.398 2.967 7.398 6.931 0 4.136-2.607 7.464-6.227 7.464-1.216 0-2.359-.631-2.75-1.378l-.748 2.853c-.271 1.043-1.002 2.35-1.492 3.146C9.57 23.812 10.763 24 12.017 24c6.624 0 11.99-5.367 11.99-11.988C24.007 5.367 18.641 0 12.017 0z"/>
</svg>''';

  static const _spotifySvg = '''
<svg viewBox="0 0 24 24" fill="#1ED760">
  <path d="M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z"/>
</svg>''';

  static const _linkSvg = '''
<svg viewBox="0 0 24 24" fill="white">
  <path d="M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z"/>
</svg>''';
}
