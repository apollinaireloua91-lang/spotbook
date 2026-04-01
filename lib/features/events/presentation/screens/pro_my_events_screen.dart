import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
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
    final uid = ref.watch(profileRepositoryProvider).currentUserId;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Text('Non connecté', style: TextStyle(color: AppColors.gris)),
        ),
      );
    }

    final async = ref.watch(proEventsByProIdProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Mes événements',
          style: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.blanc),
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
                  const Text(
                    'Aucun événement',
                    style: TextStyle(color: AppColors.gris, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/create-event'),
                    child: const Text(
                      'Créer un événement',
                      style: TextStyle(color: AppColors.blanc),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blanc),
        ),
        error: (err, _) => Center(
          child: Text(
            'Erreur : $err',
            style: const TextStyle(color: AppColors.error),
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
        ? DateFormat.yMMMd('fr_FR').format(event.eventDate!)
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
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gris),
            ],
          ),
        ),
      ),
    );
  }
}
