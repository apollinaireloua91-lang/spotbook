import 'package:flutter/material.dart';

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
    return Row(
      children: [
        _SpinningDisc(),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 16,
            child: _ScrollingText(text: '$trackTitle — $trackArtist'),
          ),
        ),
      ],
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
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        display,
        style: TextStyle(
          color: AppColors.blanc.withAlpha(179),
          fontSize: 10,
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
        angle: _controller.value * 2 * 3.14159,
        child: child,
      ),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Center(
          child: Icon(
            Icons.music_note,
            color: AppColors.blanc,
            size: 14,
          ),
        ),
      ),
    );
  }
}
