import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/profile_repository.dart';
import 'pro_profile_screen.dart';

/// Profil pro du compte connecté (onglet shell).
class ProShellProfileScreen extends ConsumerWidget {
  const ProShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(profileRepositoryProvider).currentUserId;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Text(
            'Non connecté',
            style: TextStyle(color: AppColors.gris),
          ),
        ),
      );
    }

    return ProProfileScreen(proId: uid);
  }
}
