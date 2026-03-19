import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

class AccountTypeSelectionScreen extends StatelessWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios,
                        color: AppColors.blanc, size: 20),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Support',
                      style: TextStyle(color: AppColors.gris, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Experience section (Client)
                  _ImmersiveSection(
                    gradientColors: const [
                      Color(0xFF1A2A1A),
                      Color(0xFF0D0D14),
                    ],
                    badge: 'EXPERIENCE',
                    badgeColor: AppColors.accent,
                    titlePrefix: 'Discover the\n',
                    titleHighlight: 'Extraordinary.',
                    highlightColor: AppColors.accent,
                    subtitle:
                        'Access exclusive events, world-class talent, and immersive content.',
                    buttonLabel: 'Start Exploring →',
                    onPressed: () => context.go('/signup', extra: 'client'),
                  ),
                  // Legacy section (Pro)
                  _ImmersiveSection(
                    gradientColors: const [
                      Color(0xFF0D0D14),
                      Color(0xFF0D1A0D),
                    ],
                    badge: 'LEGACY',
                    badgeColor: AppColors.accentGreen,
                    titlePrefix: 'Build Your\n',
                    titleHighlight: 'Empire.',
                    highlightColor: AppColors.accentGreen,
                    subtitle:
                        'Scale your professional reach and monetize your unique vision.',
                    buttonLabel: 'Launch Your Brand 🚀',
                    onPressed: () => context.go('/signup', extra: 'pro'),
                  ),
                ],
              ),
            ),
            // Bottom link
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              child: GestureDetector(
                onTap: () {},
                child: const Text(
                  'NEED GUIDANCE? COMPARE ROLES',
                  style: TextStyle(
                    color: AppColors.gris,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImmersiveSection extends StatelessWidget {
  const _ImmersiveSection({
    required this.gradientColors,
    required this.badge,
    required this.badgeColor,
    required this.titlePrefix,
    required this.titleHighlight,
    required this.highlightColor,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final List<Color> gradientColors;
  final String badge;
  final Color badgeColor;
  final String titlePrefix;
  final String titleHighlight;
  final Color highlightColor;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withAlpha(128)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: titlePrefix,
                  style: const TextStyle(color: AppColors.blanc),
                ),
                TextSpan(
                  text: titleHighlight,
                  style: TextStyle(color: highlightColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.gris,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blanc,
                foregroundColor: AppColors.fondDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
