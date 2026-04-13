import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';

class MusicTicker extends StatelessWidget {
  const MusicTicker({
    super.key,
    required this.trackTitle,
    required this.trackArtist,
  });

  final String trackTitle;
  final String trackArtist;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SpinningDisc(),
              const SizedBox(width: 8),
              Flexible(
                child: SizedBox(
                  height: 16,
                  child: _ScrollingText(text: '$trackTitle — $trackArtist'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollingText extends StatefulWidget {
  const _ScrollingText({required this.text});
  final String text;

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(_controller.value * max);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = '${widget.text}     ${widget.text}     ';
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.08, 0.92, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          display,
          style: GoogleFonts.dmSans(
            color: Colors.white.withAlpha(200),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 2 * pi,
        child: child,
      ),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          gradient: AppColors.gradientAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withAlpha(40),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
          ),
          child: const Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ),
    );
  }
}
