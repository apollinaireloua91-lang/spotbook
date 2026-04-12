import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../data/event_notifier.dart';
import '../../domain/event_models.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProEventsListScreen extends ConsumerStatefulWidget {
  const ProEventsListScreen({super.key});

  @override
  ConsumerState<ProEventsListScreen> createState() =>
      _ProEventsListScreenState();
}

class _ProEventsListScreenState extends ConsumerState<ProEventsListScreen> {
  _Filter _filter = _Filter.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _filterLabel(_Filter f, AppLocalizations l) => switch (f) {
        _Filter.all => l.allEventsFilter,
        _Filter.published => l.publishedEventsFilter,
        _Filter.draft => l.draftsEventsFilter,
        _Filter.past => l.pastEventsFilter,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(proEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.fond,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 0,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.myEventsLabel,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune, color: _filter != _Filter.all ? AppColors.violet : AppColors.blanc, size: 26),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gris, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 16),
                              Text(l.filterByStatus, style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              ..._Filter.values.map((f) => ListTile(
                                leading: Icon(
                                  _filter == f ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: _filter == f ? AppColors.violet : AppColors.gris,
                                ),
                                title: Text(_filterLabel(f, l), style: GoogleFonts.dmSans(color: AppColors.blanc)),
                                onTap: () {
                                  setState(() => _filter = f);
                                  Navigator.pop(context);
                                },
                              )),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(106),
              child: Column(
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.search, color: AppColors.gris, size: 20),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: l.searchEventHint,
                                hintStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) => setState(() => _query = v.toLowerCase()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Filter chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20, right: 8, bottom: 4),
                      children: _Filter.values
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: _filterLabel(f, l),
                                  selected: _filter == f,
                                  onTap: () => setState(() => _filter = f),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: async.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.blanc),
          ),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: GoogleFonts.dmSans(color: AppColors.error)),
          ),
          data: (events) {
            final filtered = events.where((e) {
              final matchQuery = _query.isEmpty ||
                  e.title.toLowerCase().contains(_query);
              final now = DateTime.now();
              final matchFilter = switch (_filter) {
                _Filter.all => true,
                _Filter.published => e.isActive,
                _Filter.draft => !e.isActive,
                _Filter.past =>
                    e.eventDate != null && e.eventDate!.isBefore(now),
              };
              return matchQuery && matchFilter;
            }).toList();

            if (filtered.isEmpty) {
              return _EmptyState(filter: _filter);
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _EventCard(event: filtered[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.fond,
        onPressed: () => context.go('/create-event'),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// ─── Event card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final EventModel event;

  String _statusLabel(AppLocalizations l) => event.isActive ? l.publishedLabel : l.draftLabel;

  Color _statusColor() =>
      event.isActive ? AppColors.success : AppColors.gris;

  int _ticketsSold() => event.ticketTypes.fold<int>(
        0,
        (a, t) => a + t.soldCount,
      );

  int _totalCapacity() => event.ticketTypes.fold<int>(
        0,
        (a, t) => a + t.quantity,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sold = _ticketsSold();
    final cap = _totalCapacity();

    return SpotbookCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/event/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.coverUrl != null && event.coverUrl!.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: event.coverUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 140,
                      color: AppColors.surfaceAlt,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _StatusBadge(
                    label: _statusLabel(l),
                    color: _statusColor(),
                    live: false,
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.coverUrl == null || event.coverUrl!.isEmpty)
                  Row(
                    children: [
                      _StatusBadge(
                        label: _statusLabel(l),
                        color: _statusColor(),
                        live: false,
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLine(event),
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
                ),
                if (cap > 0) ...[
                  const SizedBox(height: 12),
                  _StatsRow(
                    ticketsSold: sold,
                    totalTickets: cap,
                    revenue: null,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      label: l.editAction,
                      onTap: () => context.push('/event/${event.id}'),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.visibility_outlined,
                      label: l.pageAction,
                      onTap: () => context.go('/event/${event.id}'),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.bar_chart_outlined,
                      label: l.salesAction,
                      onTap: () => context.push('/event/${event.id}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLine(EventModel e) {
    if (e.eventDate == null) return '—';
    final d = e.eventDate!.toLocal();
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({this.ticketsSold, this.totalTickets, this.revenue});
  final int? ticketsSold;
  final int? totalTickets;
  final double? revenue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pct = (totalTickets != null && totalTickets! > 0)
        ? (ticketsSold ?? 0) / totalTickets!
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          if (ticketsSold != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$ticketsSold${totalTickets != null ? ' / $totalTickets' : ''}',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l.ticketsSold,
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: AppColors.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.blanc),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),
            Container(
              width: 1, height: 32, color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ],
          if (revenue != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${revenue!.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l.revenueLabel,
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.live,
  });
  final String label;
  final Color color;
  final bool live;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.gris, size: 18),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final _Filter filter;

  String _filterLabel(_Filter f, AppLocalizations l) => switch (f) {
        _Filter.all => l.allEventsFilter,
        _Filter.published => l.publishedEventsFilter,
        _Filter.draft => l.draftsEventsFilter,
        _Filter.past => l.pastEventsFilter,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.gris,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              filter == _Filter.all
                  ? l.noEventsCreated
                  : l.noEventsWithFilter(_filterLabel(filter, l).toLowerCase()),
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.createFirstEventHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go('/create-event'),
              child: Text(
                l.createEvent,
                style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
              ),
            ),
          ],
        ),
      );
  }
}

// ─── Filter enum ──────────────────────────────────────────────────────────────

enum _Filter { all, published, draft, past }

// ─── Filter chip ──────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.blanc : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.blanc : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: selected ? AppColors.fond : AppColors.gris,
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
}
