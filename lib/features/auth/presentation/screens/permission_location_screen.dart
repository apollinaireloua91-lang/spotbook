import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/profile_repository.dart';

class PermissionLocationScreen extends ConsumerWidget {
  const PermissionLocationScreen({super.key});

  Future<void> _requestLocation(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(profileRepositoryProvider).requestLocationAndSave();
    } catch (_) {
      // Continue even if location fails
    }
    if (context.mounted) context.go('/client/feed');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/client/goals'),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.blanc,
            size: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Step indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.violet.withAlpha(25),
                    ),
                    child: const Text(
                      'STEP 3/3',
                      style: TextStyle(
                        color: AppColors.violet,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
                  minHeight: 4,
                ),
              ),

              const Spacer(flex: 2),

              // Location illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.violet.withAlpha(50),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.violet.withAlpha(20),
                      ),
                    ),
                    const Icon(
                      Icons.pin_drop,
                      color: AppColors.violet,
                      size: 40,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Title
              const Text(
                'Enable your location',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Discover the best professionals near you by enabling location services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gris,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // Allow location button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppColors.gradientAccent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(30),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _requestLocation(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.blanc,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.pin_drop, size: 20),
                    label: const Text(
                      'Allow location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => context.go('/client/feed'),
                  child: const Text(
                    'Not now',
                    style: TextStyle(color: AppColors.gris, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Security note
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: AppColors.violet, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Your data is secure and private',
                      style: TextStyle(color: AppColors.gris, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bottomPadding + 24),
            ],
          ),
        ),
      ),
    );
  }
}
