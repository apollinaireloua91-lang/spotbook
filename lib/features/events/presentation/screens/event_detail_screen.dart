import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';
import '../widgets/buy_ticket_sheet.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.openPurchaseFlow = false,
  });

  final String eventId;
  final bool openPurchaseFlow;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _purchaseSheetOpened = false;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: eventAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => Center(
          child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (event) {
          if (widget.openPurchaseFlow &&
              !_purchaseSheetOpened &&
              event.ticketTypes.isNotEmpty) {
            TicketTypeModel? firstAvailable;
            for (final t in event.ticketTypes) {
              if (!t.isSoldOut) {
                firstAvailable = t;
                break;
              }
            }
            if (firstAvailable != null) {
              _purchaseSheetOpened = true;
              final type = firstAvailable;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                showBuyTicketSheet(
                  context,
                  ticketType: type,
                  event: event,
                );
              });
            }
          }
          return _EventDetailBody(event: event);
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: Column(
        children: [
          Container(height: 200, color: AppColors.surface),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 200, color: AppColors.surface),
                const SizedBox(height: 12),
                Container(height: 16, width: 150, color: AppColors.surface),
                const SizedBox(height: 12),
                Container(height: 60, color: AppColors.surface),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDetailBody extends StatelessWidget {
  const _EventDetailBody({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.fond,
          leading: Semantics(
            label: 'Retour',
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.pop();
              },
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: event.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: event.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.surface,
                      highlightColor: AppColors.surfaceAlt,
                      child: Container(color: AppColors.surface),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.event, color: AppColors.gris, size: 48),
                    ),
                  )
                : Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.event, color: AppColors.gris, size: 48),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                event.title,
                style: const TextStyle(color: AppColors.blanc, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (event.eventDate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.gris, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE d MMMM yyyy, HH:mm', 'fr_FR').format(event.eventDate!),
                      style: const TextStyle(color: AppColors.gris, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (event.location != null)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.gris, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${event.location}${event.address != null ? ' — ${event.address}' : ''}',
                        style: const TextStyle(color: AppColors.gris, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              // Pro info
              if (event.proName != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceAlt,
                      backgroundImage: event.proAvatarUrl != null
                          ? CachedNetworkImageProvider(event.proAvatarUrl!)
                          : null,
                      child: event.proAvatarUrl == null
                          ? const Icon(Icons.person, color: AppColors.gris, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      event.proName!,
                      style: const TextStyle(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              if (event.description != null) ...[
                const SizedBox(height: 20),
                Text(
                  event.description!,
                  style: const TextStyle(color: AppColors.grisClair, fontSize: 14, height: 1.5),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Billets', style: TextStyle(color: AppColors.blanc, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (event.ticketTypes.isEmpty)
                const Text('Aucun billet disponible', style: TextStyle(color: AppColors.gris, fontSize: 14))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: event.ticketTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final type = event.ticketTypes[index];
                    return _TicketTypeCard(type: type, event: event);
                  },
                ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TicketTypeCard extends StatelessWidget {
  const _TicketTypeCard({required this.type, required this.event});
  final TicketTypeModel type;
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.name, style: const TextStyle(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  type.isSoldOut ? 'Complet' : '${type.remaining} restant${type.remaining > 1 ? 's' : ''}',
                  style: TextStyle(color: type.isSoldOut ? AppColors.error : AppColors.gris, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${type.price.toStringAsFixed(2)} CA\$',
            style: const TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: type.isSoldOut
                  ? null
                  : () => showBuyTicketSheet(context, ticketType: type, event: event),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blanc,
                foregroundColor: AppColors.fond,
                disabledBackgroundColor: AppColors.surfaceAlt,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(type.isSoldOut ? 'Complet' : 'Acheter', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
