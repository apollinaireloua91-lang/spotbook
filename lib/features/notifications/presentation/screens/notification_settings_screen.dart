import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppColors.violet, strokeWidth: 2),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _SectionLabel(label: 'RENDEZ-VOUS'),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Rappels',
                  subtitle: '1 jour et 2 heures avant vos rendez-vous',
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
                _SectionLabel(label: 'COMMUNICATION'),
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
                _SectionLabel(label: 'ÉVÉNEMENTS'),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: 'Liste d\'attente',
                  subtitle: 'Un billet devient disponible pour un événement',
                  value: state.prefs.waitlist,
                  dbKey: 'waitlist_enabled',
                ),
                const SizedBox(height: 24),
                _SectionLabel(label: 'AUTRE'),
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

// ═════════════════════════════════════════════════════════════════════════════
// SECTION LABEL
// ═════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        color: AppColors.gris,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOGGLE TILE
// ═════════════════════════════════════════════════════════════════════════════

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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 13,
          ),
        ),
        value: value,
        activeTrackColor: AppColors.violet,
        inactiveTrackColor: AppColors.surfaceAlt,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textOnPrimary;
          }
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
