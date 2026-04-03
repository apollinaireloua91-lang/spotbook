import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';

/// Choisir un événement avant d’ouvrir le scanner QR, ou accès direct caméra s’il n’y en a qu’un.
class ProScannerEventPickerScreen extends ConsumerStatefulWidget {
  const ProScannerEventPickerScreen({super.key});

  @override
  ConsumerState<ProScannerEventPickerScreen> createState() =>
      _ProScannerEventPickerScreenState();
}

class _ProScannerEventPickerScreenState
    extends ConsumerState<ProScannerEventPickerScreen> {
  bool _autoRoutedSingleEvent = false;

  void _maybeOpenCameraForSingleEvent(List<EventModel> events) {
    if (_autoRoutedSingleEvent || events.length != 1) return;
    _autoRoutedSingleEvent = true;
    final id = events.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushReplacement('/scanner/$id');
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(proEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: const Text(
          'Scanner un billet',
          style: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: SpotbookLoadingShimmer.card(itemCount: 4),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gris),
            ),
          ),
        ),
        data: (events) {
          _maybeOpenCameraForSingleEvent(events);

          if (events.isEmpty) {
            return EmptyState.noEvents(
              onCta: () => context.push('/create-event'),
            );
          }

          if (events.length == 1) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.blanc),
                  SizedBox(height: 16),
                  Text(
                    'Ouverture de la caméra…',
                    style: TextStyle(color: AppColors.gris, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: events.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Choisis l’événement concerné, puis scanne les QR des billets avec la caméra.',
                    style: TextStyle(
                      color: AppColors.gris.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                );
              }
              final e = events[i - 1];
              final dateStr = e.eventDate != null
                  ? DateFormat('EEE d MMM · HH:mm').format(e.eventDate!.toLocal())
                  : 'Date à confirmer';

              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/scanner/${e.id}');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: e.coverUrl != null && e.coverUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: e.coverUrl!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.surfaceAlt,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.surfaceAlt,
                                    child: const Icon(Icons.event, color: AppColors.gris),
                                  ),
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: AppColors.surfaceAlt,
                                  child: const Icon(Icons.event, color: AppColors.gris),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.blanc,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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
                        const Icon(Icons.qr_code_scanner, color: AppColors.blanc, size: 26),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
