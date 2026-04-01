import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';

// ─── Model ──────────────────────────────────────────────

class _ClientEntry {
  const _ClientEntry({
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    required this.totalBookings,
    required this.lastBookingDate,
    required this.totalSpent,
  });

  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final int totalBookings;
  final DateTime lastBookingDate;
  final double totalSpent;
}

enum _SortBy { mostBookings, mostRecent, highestSpend }

// ─── Provider ───────────────────────────────────────────

final _proClientsProvider =
    FutureProvider<List<_ClientEntry>>((ref) async {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];

  final data = await supabase
      .from('bookings')
      .select(
          'client_id, deposit_amount, created_at, client_user:users!bookings_client_id_fkey(full_name, avatar_url)')
      .eq('pro_id', uid)
      .inFilter('status', ['confirmed', 'completed']);

  // Aggregate by client
  final map = <String, _ClientAgg>{};
  for (final row in data as List) {
    final clientId = row['client_id'] as String;
    final user = row['client_user'] as Map<String, dynamic>?;
    final amount = (row['deposit_amount'] as num?)?.toDouble() ?? 0;
    final date = DateTime.parse(row['created_at'] as String);

    final existing = map[clientId];
    if (existing == null) {
      map[clientId] = _ClientAgg(
        clientId: clientId,
        clientName: user?['full_name'] as String? ?? 'Client',
        clientAvatarUrl: user?['avatar_url'] as String?,
        totalBookings: 1,
        lastBookingDate: date,
        totalSpent: amount,
      );
    } else {
      map[clientId] = _ClientAgg(
        clientId: clientId,
        clientName: existing.clientName,
        clientAvatarUrl: existing.clientAvatarUrl,
        totalBookings: existing.totalBookings + 1,
        lastBookingDate:
            date.isAfter(existing.lastBookingDate) ? date : existing.lastBookingDate,
        totalSpent: existing.totalSpent + amount,
      );
    }
  }

  return map.values
      .map((a) => _ClientEntry(
            clientId: a.clientId,
            clientName: a.clientName,
            clientAvatarUrl: a.clientAvatarUrl,
            totalBookings: a.totalBookings,
            lastBookingDate: a.lastBookingDate,
            totalSpent: a.totalSpent,
          ))
      .toList();
});

class _ClientAgg {
  _ClientAgg({
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    required this.totalBookings,
    required this.lastBookingDate,
    required this.totalSpent,
  });
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  int totalBookings;
  DateTime lastBookingDate;
  double totalSpent;
}

// ─── Screen ─────────────────────────────────────────────

/// Client CRM list for providers with search, sort, and message button.
/// Route: /pro/clients
class ProviderClientsListScreen extends ConsumerStatefulWidget {
  const ProviderClientsListScreen({super.key});

  @override
  ConsumerState<ProviderClientsListScreen> createState() =>
      _ProviderClientsListScreenState();
}

class _ProviderClientsListScreenState
    extends ConsumerState<ProviderClientsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SortBy _sort = _SortBy.mostRecent;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_ClientEntry> _sortAndFilter(List<_ClientEntry> clients) {
    var filtered = _query.isEmpty
        ? clients
        : clients
            .where((c) =>
                c.clientName.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    switch (_sort) {
      case _SortBy.mostBookings:
        filtered.sort((a, b) => b.totalBookings.compareTo(a.totalBookings));
      case _SortBy.mostRecent:
        filtered.sort(
            (a, b) => b.lastBookingDate.compareTo(a.lastBookingDate));
      case _SortBy.highestSpend:
        filtered.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(_proClientsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: const SpotbookAppBar(title: 'Mes clients'),
      body: clientsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
        error: (e, _) => Center(
          child: Text('$e',
              style: const TextStyle(color: AppColors.gris)),
        ),
        data: (clients) {
          final filtered = _sortAndFilter(clients);

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                      color: AppColors.blanc, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client…',
                    hintStyle: TextStyle(
                        color: AppColors.gris.withAlpha(128)),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.gris, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              // Sort chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _SortChip(
                      label: 'Plus récent',
                      selected: _sort == _SortBy.mostRecent,
                      onTap: () => setState(
                          () => _sort = _SortBy.mostRecent),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Plus de RDV',
                      selected: _sort == _SortBy.mostBookings,
                      onTap: () => setState(
                          () => _sort = _SortBy.mostBookings),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Plus dépensé',
                      selected: _sort == _SortBy.highestSpend,
                      onTap: () => setState(
                          () => _sort = _SortBy.highestSpend),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                color: AppColors.gris, size: 48),
                            SizedBox(height: 12),
                            Text('Aucun client',
                                style: TextStyle(
                                    color: AppColors.gris,
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.blanc,
                        backgroundColor: AppColors.surface,
                        onRefresh: () async =>
                            ref.invalidate(_proClientsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _ClientCard(
                                client: filtered[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
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
          style: TextStyle(
            color: selected ? AppColors.fond : AppColors.blanc,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client});
  final _ClientEntry client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SpotbookAvatar(
            imageUrl: client.clientAvatarUrl,
            radius: 22,
            name: client.clientName,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.clientName,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: _MiniStat(
                          icon: Icons.calendar_today,
                          value: '${client.totalBookings} RDV'),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _MiniStat(
                          icon: Icons.attach_money,
                          value:
                              '${client.totalSpent.toStringAsFixed(0)} \$'),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Dernier : ${DateFormat('dd/MM/yy').format(client.lastBookingDate)}',
                  style: const TextStyle(
                      color: AppColors.grisInactif, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/pro/messages');
            },
            icon: const Icon(Icons.chat_bubble_outline,
                color: AppColors.violet, size: 22),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.gris, size: 12),
        const SizedBox(width: 4),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.gris, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
