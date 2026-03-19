import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/profile_repository.dart';

class PermissionLocationScreen extends ConsumerWidget {
  const PermissionLocationScreen({super.key});

  Future<void> _requestLocation(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileRepositoryProvider).requestLocationAndSave();
    } catch (_) {
      // Continue even if location fails
    }
    if (context.mounted) context.go('/client/feed');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.fondDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const Spacer(flex: 2),
            Container(width: 220, height: 220, decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(24)),
              child: Stack(alignment: Alignment.center, children: [
                Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accent.withAlpha(77), width: 2))),
                Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withAlpha(26))),
                const Icon(Icons.pin_drop, color: AppColors.accent, size: 40),
              ])),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gris.withAlpha(77))),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
            ]),
            const Spacer(),
            const Text('Activez votre position', style: TextStyle(color: AppColors.blanc, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Découvrez les meilleurs professionnels à proximité de chez vous en activant la géolocalisation pour une expérience personnalisée.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gris, fontSize: 14, height: 1.5)),
            const Spacer(),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
              onPressed: () => _requestLocation(context, ref),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.fondDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.pin_drop, size: 20),
              label: const Text('Autoriser la localisation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 52, child: TextButton(
              onPressed: () => context.go('/client/feed'),
              child: const Text('Pas maintenant', style: TextStyle(color: AppColors.gris, fontSize: 15)),
            )),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock, color: AppColors.accent, size: 16), SizedBox(width: 8), Text('Vos données sont sécurisées et privées', style: TextStyle(color: AppColors.gris, fontSize: 12))])),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
