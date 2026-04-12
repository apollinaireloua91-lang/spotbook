import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';

/// Bottom sheet presenting Pro advantages with a gradient CTA.
class BecomeProSheet extends StatefulWidget {
  const BecomeProSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BecomeProSheet(),
    );
  }

  @override
  State<BecomeProSheet> createState() => _BecomeProSheetState();
}

class _BecomeProSheetState extends State<BecomeProSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _advantages = [
    (icon: '🎬', title: 'Publish videos', desc: 'Showcase your services worldwide'),
    (icon: '📅', title: 'Manage your services', desc: 'Slots, pricing, availability'),
    (icon: '🎟️', title: 'Sell tickets', desc: 'Organize and monetize your events'),
    (icon: '💰', title: 'Receive payments', desc: 'Integrated, secure Stripe Connect'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBecomePro() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
    if (mounted) context.push('/become-pro');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.gris.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.gradientAccent.createShader(bounds),
            child: Text(
              'Become Pro',
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grow your business on Spotbook',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          // Advantages list with staggered animation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(_advantages.length, (index) {
                final advantage = _advantages[index];
                final delay = index * 0.15;

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = ((_controller.value - delay) / (1 - delay))
                        .clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.8 + 0.2 * Curves.easeOutBack.transform(t),
                      child: Opacity(
                        opacity: t,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.violet.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              advantage.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                advantage.title,
                                style: TextStyle(
                                  color: AppColors.blanc,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                advantage.desc,
                                style: TextStyle(
                                  color: AppColors.gris,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // CTA button with gradient
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: GestureDetector(
              onTap: _onBecomePro,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Create a Pro account',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
