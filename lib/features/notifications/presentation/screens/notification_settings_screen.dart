import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/notification_notifier.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(notifPrefsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.retourLabel,
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
          l.notifications,
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
                _SectionLabel(label: l.notifSectionAppointments),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: l.notifReminders,
                  subtitle: l.notifRemindersSubtitle,
                  value: state.prefs.bookingReminder,
                  dbKey: 'booking_reminder_enabled',
                ),
                _ToggleTile(
                  title: l.notifUpdates,
                  subtitle: l.notifUpdatesSubtitle,
                  value: state.prefs.bookingUpdate,
                  dbKey: 'booking_update_enabled',
                ),
                const SizedBox(height: 24),
                _SectionLabel(label: l.notifSectionCommunication),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: l.notifMessages,
                  subtitle: l.notifMessagesSubtitle,
                  value: state.prefs.chat,
                  dbKey: 'chat_enabled',
                ),
                _ToggleTile(
                  title: l.notifReviewRequests,
                  subtitle: l.notifReviewRequestsSubtitle,
                  value: state.prefs.reviewRequest,
                  dbKey: 'review_request_enabled',
                ),
                const SizedBox(height: 24),
                _SectionLabel(label: l.notifSectionEvents),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: l.notifWaitlist,
                  subtitle: l.notifWaitlistSubtitle,
                  value: state.prefs.waitlist,
                  dbKey: 'waitlist_enabled',
                ),
                const SizedBox(height: 24),
                _SectionLabel(label: l.notifSectionOther),
                const SizedBox(height: 8),
                _ToggleTile(
                  title: l.notifMarketing,
                  subtitle: l.notifMarketingSubtitle,
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
