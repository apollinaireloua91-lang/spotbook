import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/profile_repository.dart';

class PermissionLocationScreen extends ConsumerWidget {
  const PermissionLocationScreen({super.key});

  Future<void> _requestLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(profileRepositoryProvider).requestLocationAndSave();
    } catch (_) {
      // Continue even if location access is denied
    }
    if (context.mounted) context.go('/client/feed');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Illustration
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pin_drop_outlined,
                  color: AppColors.blanc,
                  size: 72,
                ),
              ),
              const Spacer(),
              const Text(
                'Enable your location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Discover the best professionals near you. Enable location for a personalised experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gris,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SpotbookButton.primary(
                label: 'Allow Location',
                icon: Icons.pin_drop,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _requestLocation(context, ref);
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.go('/client/feed'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.gris, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
