import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/favorite_notifier.dart';

class FavoriteHeartButton extends ConsumerStatefulWidget {
  const FavoriteHeartButton({
    super.key,
    required this.targetId,
    required this.targetType,
    this.targetName,
    this.targetImageUrl,
    this.targetSubtitle,
    this.size = 24,
  });

  final String targetId;
  final String targetType;
  final String? targetName;
  final String? targetImageUrl;
  final String? targetSubtitle;
  final double size;

  @override
  ConsumerState<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends ConsumerState<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(favoriteIdsProvider);
    final isFav = ids.contains(widget.targetId);

    return Semantics(
      label: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _animCtrl.forward(from: 0);
          ref.read(favoriteIdsProvider.notifier).toggle(
                targetId: widget.targetId,
                targetType: widget.targetType,
                targetName: widget.targetName,
                targetImageUrl: widget.targetImageUrl,
                targetSubtitle: widget.targetSubtitle,
              );
        },
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            );
          },
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.error : AppColors.gris,
                size: widget.size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
