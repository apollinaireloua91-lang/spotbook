import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

enum ShimmerVariant { card, list, profile, feed }

class SpotbookLoadingShimmer extends StatelessWidget {
  const SpotbookLoadingShimmer({
    super.key,
    this.variant = ShimmerVariant.list,
    this.itemCount = 5,
  });

  const SpotbookLoadingShimmer.card({super.key, this.itemCount = 3})
      : variant = ShimmerVariant.card;

  const SpotbookLoadingShimmer.list({super.key, this.itemCount = 5})
      : variant = ShimmerVariant.list;

  const SpotbookLoadingShimmer.profile({super.key})
      : variant = ShimmerVariant.profile,
        itemCount = 1;

  const SpotbookLoadingShimmer.feed({super.key})
      : variant = ShimmerVariant.feed,
        itemCount = 1;

  final ShimmerVariant variant;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (variant) {
      case ShimmerVariant.list:
        return _ListShimmer(itemCount: itemCount);
      case ShimmerVariant.card:
        return _CardShimmer(itemCount: itemCount);
      case ShimmerVariant.profile:
        return const _ProfileShimmer();
      case ShimmerVariant.feed:
        return const _FeedShimmer();
    }
  }
}

// ─── List shimmer ─────────────────────────────────────────────────────────────

class _ListShimmer extends StatelessWidget {
  const _ListShimmer({required this.itemCount});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            _Box(width: 48, height: 48, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Box(width: double.infinity, height: 14, radius: 7),
                  const SizedBox(height: 8),
                  _Box(width: 140, height: 12, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card shimmer ─────────────────────────────────────────────────────────────

class _CardShimmer extends StatelessWidget {
  const _CardShimmer({required this.itemCount});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: _Box(width: double.infinity, height: 120, radius: 16),
      ),
    );
  }
}

// ─── Profile shimmer ──────────────────────────────────────────────────────────

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cover
          _Box(width: double.infinity, height: 140, radius: 0),
          const SizedBox(height: 8),
          // Avatar
          Center(child: _Box(width: 80, height: 80, radius: 40)),
          const SizedBox(height: 16),
          // Name
          Center(child: _Box(width: 160, height: 18, radius: 9)),
          const SizedBox(height: 8),
          // Username
          Center(child: _Box(width: 100, height: 14, radius: 7)),
          const SizedBox(height: 16),
          // Bio lines
          _Box(width: double.infinity, height: 13, radius: 6),
          const SizedBox(height: 6),
          _Box(width: 240, height: 13, radius: 6),
          const SizedBox(height: 24),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Box(width: 60, height: 40, radius: 8),
              _Box(width: 60, height: 40, radius: 8),
              _Box(width: 60, height: 40, radius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Feed shimmer ─────────────────────────────────────────────────────────────

class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height,
      child: Stack(
        children: [
          // Full screen video placeholder
          _Box(width: double.infinity, height: double.infinity, radius: 0),
          // Right side action buttons
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                _Box(width: 40, height: 40, radius: 20),
                const SizedBox(height: 20),
                _Box(width: 40, height: 40, radius: 20),
                const SizedBox(height: 20),
                _Box(width: 40, height: 40, radius: 20),
                const SizedBox(height: 20),
                _Box(width: 40, height: 40, radius: 20),
              ],
            ),
          ),
          // Bottom info
          Positioned(
            left: 16,
            bottom: 80,
            right: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 120, height: 14, radius: 7),
                const SizedBox(height: 8),
                _Box(width: 200, height: 13, radius: 6),
                const SizedBox(height: 6),
                _Box(width: 160, height: 13, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable shimmer box ─────────────────────────────────────────────────────

class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
