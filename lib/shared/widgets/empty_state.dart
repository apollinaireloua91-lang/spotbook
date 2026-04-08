import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.emoji,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  factory EmptyState.noMessages({VoidCallback? onCta}) {
    return EmptyState(
      emoji: '\uD83D\uDCAC',
      title: 'No messages',
      subtitle: 'Your conversations with pros will appear here.',
      ctaLabel: onCta != null ? 'Discover pros' : null,
      onCta: onCta,
    );
  }

  factory EmptyState.noEvents({VoidCallback? onCta}) {
    return EmptyState(
      emoji: '\uD83C\uDFAB',
      title: 'No events',
      subtitle:
          'Create your first event to start selling tickets.',
      ctaLabel: onCta != null ? 'Create an event' : null,
      onCta: onCta,
    );
  }

  factory EmptyState.noBookings() {
    return const EmptyState(
      emoji: '\uD83D\uDCC5',
      title: 'No bookings',
      subtitle: 'Your upcoming bookings will appear here.',
    );
  }

  factory EmptyState.noVideos() {
    return const EmptyState(
      emoji: '\uD83C\uDFAC',
      title: 'No videos',
      subtitle: 'Videos from professionals will appear here.',
    );
  }

  factory EmptyState.noFavorites() {
    return const EmptyState(
      emoji: '\u2764\uFE0F',
      title: 'No favorites',
      subtitle: 'Your favorite pros and saved posts will appear here.',
    );
  }

  final IconData? icon;
  final String? emoji;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _float,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _float.value),
                  child: child,
                );
              },
              child: widget.emoji != null
                  ? Text(
                      widget.emoji!,
                      style: const TextStyle(fontSize: 56),
                    )
                  : Icon(
                      widget.icon ?? Icons.inbox_outlined,
                      size: 64,
                      color: AppColors.gris,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gris,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (widget.ctaLabel != null && widget.onCta != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: widget.onCta,
                child: Text(
                  widget.ctaLabel!,
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
