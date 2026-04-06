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
        title: const Text('Notification preferences',
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
                const Text('APPOINTMENTS',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Reminders',
                  subtitle: '1 day and 2 hours before your appointments',
                  value: state.prefs.bookingReminder,
                  dbKey: 'booking_reminder_enabled',
                ),
                _ToggleTile(
                  title: 'Updates',
                  subtitle: 'Confirmations, cancellations, changes',
                  value: state.prefs.bookingUpdate,
                  dbKey: 'booking_update_enabled',
                ),
                const SizedBox(height: 24),
                const Text('COMMUNICATION',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Messages',
                  subtitle: 'New messages from your pros',
                  value: state.prefs.chat,
                  dbKey: 'chat_enabled',
                ),
                _ToggleTile(
                  title: 'Review requests',
                  subtitle: 'After your appointments',
                  value: state.prefs.reviewRequest,
                  dbKey: 'review_request_enabled',
                ),
                const SizedBox(height: 24),
                const Text('EVENTS',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Waitlist',
                  subtitle: 'A ticket becomes available for an event',
                  value: state.prefs.waitlist,
                  dbKey: 'waitlist_enabled',
                ),
                const SizedBox(height: 24),
                const Text('OTHER',
                    style: TextStyle(color: AppColors.gris, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Marketing',
                  subtitle: 'Spotbook promotions and updates',
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
