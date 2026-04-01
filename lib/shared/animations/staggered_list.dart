import 'package:flutter/material.dart';

/// Anime chaque enfant avec un décalage progressif (stagger).
///
/// Utilisation :
/// ```dart
/// StaggeredList(
///   children: items.map((i) => MyCard(item: i)).toList(),
/// )
/// ```
class StaggeredList extends StatefulWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.animationDuration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 24),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
    this.padding,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Offset offset;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final EdgeInsetsGeometry? padding;

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.animationDuration +
        widget.staggerDelay * widget.children.length;
    _controller = AnimationController(vsync: this, duration: totalDuration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    final count = widget.children.length;

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: List.generate(count, (i) {
          final startMs = widget.staggerDelay.inMilliseconds * i;
          final endMs = startMs + widget.animationDuration.inMilliseconds;
          final begin = startMs / total;
          final end = (endMs / total).clamp(0.0, 1.0);

          final animation = CurvedAnimation(
            parent: _controller,
            curve: Interval(begin, end, curve: Curves.easeOutCubic),
          );

          return _StaggeredChild(
            animation: animation,
            offset: widget.offset,
            child: widget.children[i],
          );
        }),
      ),
    );
  }
}

/// Anime un seul enfant dans un stagger (slide + fade).
class _StaggeredChild extends StatelessWidget {
  const _StaggeredChild({
    required this.animation,
    required this.offset,
    required this.child,
  });

  final Animation<double> animation;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(offset.dx / 100, offset.dy / 100),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Version pour ListView.builder — anime chaque item individuellement.
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.delay = const Duration(milliseconds: 60),
  });

  final int index;
  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(curve);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
