import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/auth_required_redirect.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/event_repository.dart';
import '../../domain/event_models.dart';

final proEventsByProIdProvider =
    FutureProvider.family<List<EventModel>, String>((ref, proId) async {
  return ref.read(eventRepositoryProvider).getEventsByProId(proId);
});

class ProMyEventsScreen extends ConsumerWidget {
  const ProMyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final uid = ref.watch(profileRepositoryProvider).currentUserId;

    if (uid == null) {
      // Ancien fallback : Text(l.notSignedIn). On évite l'écran fantôme
      // dead-end en anglais et on pousse vers /login (cf. widget partagé).
      return const AuthRequiredRedirect();
    }

    final async = ref.watch(proEventsByProIdProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          l.myEventsLabel,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.blanc),
            onPressed: () => context.push('/create-event'),
          ),
        ],
      ),
      body: async.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.noEvents,
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/create-event'),
                    child: Text(
                      l.createEvent,
                      style: GoogleFonts.dmSans(color: AppColors.blanc),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = events[i];
              return _ProEventRow(
                event: e,
                onTap: () => context.push('/event/${e.id}'),
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.blanc),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: GoogleFonts.dmSans(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _ProEventRow extends StatelessWidget {
  const _ProEventRow({required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.eventDate != null
        ? DateFormat.yMMMd('en_US').format(event.eventDate!)
        : '—';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.gris),
            ],
          ),
        ),
      ),
    );
  }
}
