import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';

class MusicTicker extends StatefulWidget {
  const MusicTicker({
    super.key,
    required this.trackTitle,
    required this.trackArtist,
  });

  final String trackTitle;
  final String? trackArtist;

  @override
  State<MusicTicker> createState() => _MusicTickerState();
}

class _MusicTickerState extends State<MusicTicker>
    with TickerProviderStateMixin {
  late final AnimationController _discRotation;
  late final AnimationController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _discRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scrollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _discRotation.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.trackArtist != null
        ? '${widget.trackTitle} — ${widget.trackArtist}'
        : widget.trackTitle;

    return Row(
      children: [
        // Rotating disc
        AnimatedBuilder(
          animation: _discRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _discRotation.value * 6.2832, // 2π
              child: child,
            );
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Icon(
              Icons.music_note,
              color: AppColors.blanc,
              size: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Scrolling text (marquee effect)
        Expanded(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _scrollCtrl,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.05, 0.9, 1.0],
                      ).createShader(bounds),
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Transform.translate(
                          offset: Offset(
                            constraints.maxWidth -
                                (constraints.maxWidth + 200) *
                                    _scrollCtrl.value,
                            0,
                          ),
                          child: Text(
                            '$text    $text',
                            style: TextStyle(
                              color: AppColors.textOnVideo.withAlpha(153),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
