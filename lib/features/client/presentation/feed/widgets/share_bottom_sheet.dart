import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';

class ClientShareBottomSheet extends StatefulWidget {
  const ClientShareBottomSheet({super.key, required this.videoId});

  final String videoId;

  @override
  State<ClientShareBottomSheet> createState() => _ClientShareBottomSheetState();
}

class _ClientShareBottomSheetState extends State<ClientShareBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gris.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Share',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // Share grid with staggered animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _staggerCtrl,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOption(
                        index: 0,
                        icon: Icons.play_arrow_rounded,
                        label: 'TikTok',
                        bgColor: AppColors.brandTikTokDark,
                      ),
                      _buildOption(
                        index: 1,
                        icon: Icons.camera_alt_outlined,
                        label: 'Instagram',
                        bgColor: AppColors.brandInstagram,
                      ),
                      _buildOption(
                        index: 2,
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        bgColor: AppColors.brandWhatsApp,
                      ),
                      _buildOption(
                        index: 3,
                        icon: Icons.link_rounded,
                        label: 'Copy',
                        bgColor: AppColors.surface,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required int index,
    required IconData icon,
    required String label,
    required Color bgColor,
  }) {
    // Stagger: each item animates in sequence
    final delay = index * 0.15;
    final t = (_staggerCtrl.value - delay).clamp(0.0, 1.0 - delay) /
        (1.0 - delay).clamp(0.001, 1.0);
    final scale = Curves.elasticOut.transform(t.clamp(0.0, 1.0));

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (label == 'Copy') {
          Clipboard.setData(
            ClipboardData(text: 'https://spotbook.app/v/${widget.videoId}'),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link copied!'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        context.pop();
      },
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withAlpha(80)),
              ),
              child: Icon(icon, color: AppColors.blanc, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.gris,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
