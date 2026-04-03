import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/notification_notifier.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notifPrefsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text('Préférences de notification',
            style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppColors.blanc, strokeWidth: 2),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const Text('RENDEZ-VOUS',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Rappels',
                  subtitle: 'J-1 et H-2 avant vos rendez-vous',
                  value: state.prefs.bookingReminder,
                  dbKey: 'booking_reminder_enabled',
                ),
                _ToggleTile(
                  title: 'Mises à jour',
                  subtitle: 'Confirmations, annulations, modifications',
                  value: state.prefs.bookingUpdate,
                  dbKey: 'booking_update_enabled',
                ),
                const SizedBox(height: 24),
                const Text('COMMUNICATION',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Messages',
                  subtitle: 'Nouveaux messages de vos pros',
                  value: state.prefs.chat,
                  dbKey: 'chat_enabled',
                ),
                _ToggleTile(
                  title: 'Demandes d\'avis',
                  subtitle: 'Après vos rendez-vous',
                  value: state.prefs.reviewRequest,
                  dbKey: 'review_request_enabled',
                ),
                const SizedBox(height: 24),
                const Text('ÉVÉNEMENTS',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Liste d\'attente',
                  subtitle: 'Un billet se libère pour un événement',
                  value: state.prefs.waitlist,
                  dbKey: 'waitlist_enabled',
                ),
                const SizedBox(height: 24),
                const Text('AUTRES',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Marketing',
                  subtitle: 'Promotions et nouveautés Spotbook',
                  value: state.prefs.marketing,
                  dbKey: 'marketing_enabled',
                ),
              ],
            ),
    );
  }
}

class _ToggleTile extends ConsumerWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.dbKey,
  });

  final String title;
  final String subtitle;
  final bool value;
  final String dbKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title,
            style: const TextStyle(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.gris, fontSize: 13)),
        value: value,
        activeTrackColor: AppColors.blanc,
        inactiveTrackColor: AppColors.surfaceAlt,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.fond;
          return AppColors.gris;
        }),
        onChanged: (v) {
          HapticFeedback.mediumImpact();
          ref.read(notifPrefsProvider.notifier).updatePreference(dbKey, v);
        },
      ),
    );
  }
}
