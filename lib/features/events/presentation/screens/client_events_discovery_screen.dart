import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';

enum _DateFilter { all, tonight, weekend, month }

/// Client-facing events discovery: date filters, category chips, event cards.
class ClientEventsDiscoveryScreen extends ConsumerStatefulWidget {
  const ClientEventsDiscoveryScreen({super.key});

  @override
  ConsumerState<ClientEventsDiscoveryScreen> createState() =>
      _ClientEventsDiscoveryScreenState();
}

class _ClientEventsDiscoveryScreenState
    extends ConsumerState<ClientEventsDiscoveryScreen> {
  _DateFilter _dateFilter = _DateFilter.all;
  String? _categoryFilter;

  static const _categories = [
    'Musique',
    'Art',
    'Sport',
    'Beauté',
    'Food',
    'Mode',
    'Tech',
    'Autre',
  ];

  List<EventModel> _applyFilters(List<EventModel> events) {
    var filtered = events.where((e) => e.isActive).toList();

    final now = DateTime.now();
    switch (_dateFilter) {
      case _DateFilter.tonight:
        filtered = filtered.where((e) {
          if (e.eventDate == null) return false;
          return e.eventDate!.year == now.year &&
              e.eventDate!.month == now.month &&
              e.eventDate!.day == now.day;
        }).toList();
      case _DateFilter.weekend:
        final saturday = now.add(Duration(days: 6 - now.weekday));
        final sunday = saturday.add(const Duration(days: 1));
        filtered = filtered.where((e) {
          if (e.eventDate == null) return false;
          final d = e.eventDate!;
          return (d.year == saturday.year &&
                  d.month == saturday.month &&
                  d.day == saturday.day) ||
              (d.year == sunday.year &&
                  d.month == sunday.month &&
                  d.day == sunday.day);
        }).toList();
      case _DateFilter.month:
        filtered = filtered.where((e) {
          if (e.eventDate == null) return false;
          return e.eventDate!.year == now.year &&
              e.eventDate!.month == now.month;
        }).toList();
      case _DateFilter.all:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: SpotbookAppBar(
        title: l.eventsTitle,
        showBack: true,
      ),
      body: Column(
        children: [
          // Date filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: l.allLabel,
                  selected: _dateFilter == _DateFilter.all,
                  onTap: () =>
                      setState(() => _dateFilter = _DateFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l.tonight,
                  selected: _dateFilter == _DateFilter.tonight,
                  onTap: () => setState(
                      () => _dateFilter = _DateFilter.tonight),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l.thisWeekend,
                  selected: _dateFilter == _DateFilter.weekend,
                  onTap: () => setState(
                      () => _dateFilter = _DateFilter.weekend),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l.thisMonth,
                  selected: _dateFilter == _DateFilter.month,
                  onTap: () =>
                      setState(() => _dateFilter = _DateFilter.month),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _FilterChip(
                  label: cat,
                  selected: _categoryFilter == cat,
                  onTap: () {
                    setState(() {
                      _categoryFilter =
                          _categoryFilter == cat ? null : cat;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Events list
          Expanded(
            child: eventsState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppColors.violet))
                : Builder(builder: (context) {
                    final filtered =
                        _applyFilters(eventsState.events);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy,
                                color: AppColors.gris, size: 48),
                            const SizedBox(height: 12),
                            Text(l.noEventsFound,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.gris,
                                    fontSize: 15)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.blanc,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => ref
                          .read(eventsProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _EventCard(
                              event: filtered[index]);
                        },
                      ),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blanc : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.blanc : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: selected ? AppColors.fond : AppColors.blanc,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dateFmt = event.eventDate != null
        ? DateFormat('dd MMM yyyy · HH:mm', 'fr_FR')
            .format(event.eventDate!)
        : null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/event/${event.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: event.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceAlt),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceAlt,
                        child: Icon(Icons.event,
                            color: AppColors.gris, size: 40),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceAlt,
                      child: Icon(Icons.event,
                          color: AppColors.gris, size: 40),
                    ),
                  // Price badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.fond.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.minPrice > 0
                            ? l.fromPrice(event.minPrice.toStringAsFixed(0))
                            : l.freeLabel,
                        style: GoogleFonts.dmSans(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  // Selling fast badge
                  if (_isSellingFast(event))
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withAlpha(200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department,
                                color: AppColors.blanc, size: 14),
                            const SizedBox(width: 4),
                            Text(l.sellingFast,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.blanc,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateFmt != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: AppColors.gris, size: 14),
                        const SizedBox(width: 6),
                        Text(dateFmt,
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 13)),
                      ],
                    ),
                  ],
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: AppColors.gris, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.isSoldOut) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(l.soldOut,
                          style: GoogleFonts.dmSans(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSellingFast(EventModel event) {
    if (event.ticketTypes.isEmpty) return false;
    final totalQty =
        event.ticketTypes.fold<int>(0, (a, t) => a + t.quantity);
    final totalSold =
        event.ticketTypes.fold<int>(0, (a, t) => a + t.soldCount);
    if (totalQty == 0) return false;
    return totalSold / totalQty > 0.75 && !event.isSoldOut;
  }
}
