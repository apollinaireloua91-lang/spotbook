import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';

// ─── Model ──────────────────────────────────────────────

class _Attendee {
  const _Attendee({
    required this.ticketId,
    required this.userName,
    this.userAvatarUrl,
    required this.ticketTypeName,
    required this.purchasedAt,
    required this.isScanned,
    this.scannedAt,
  });

  final String ticketId;
  final String userName;
  final String? userAvatarUrl;
  final String ticketTypeName;
  final DateTime purchasedAt;
  final bool isScanned;
  final DateTime? scannedAt;
}

class _AttendeesData {
  const _AttendeesData({
    this.attendees = const [],
    this.totalSold = 0,
    this.totalScanned = 0,
    this.totalCapacity = 0,
  });
  final List<_Attendee> attendees;
  final int totalSold;
  final int totalScanned;
  final int totalCapacity;
}

// ─── Provider ───────────────────────────────────────────

final _attendeesProvider =
    FutureProvider.family<_AttendeesData, String>((ref, eventId) async {
  final supabase = Supabase.instance.client;

  final ticketsData = await supabase
      .from('tickets')
      .select('*, users(full_name, avatar_url), ticket_types(name, quantity)')
      .eq('event_id', eventId)
      .order('purchased_at', ascending: false);

  final attendees = <_Attendee>[];
  int totalScanned = 0;
  int totalCapacity = 0;
  final seenTypes = <String>{};

  for (final row in ticketsData as List) {
    final user = row['users'] as Map<String, dynamic>?;
    final ticketType = row['ticket_types'] as Map<String, dynamic>?;
    final isUsed = row['status'] == 'used';
    if (isUsed) totalScanned++;

    final typeId = row['ticket_type_id'] as String?;
    if (typeId != null && !seenTypes.contains(typeId)) {
      seenTypes.add(typeId);
      totalCapacity += (ticketType?['quantity'] as int?) ?? 0;
    }

    attendees.add(_Attendee(
      ticketId: row['id'] as String,
      userName: user?['full_name'] as String? ?? 'Inconnu',
      userAvatarUrl: user?['avatar_url'] as String?,
      ticketTypeName: ticketType?['name'] as String? ?? 'Standard',
      purchasedAt: DateTime.parse(row['purchased_at'] as String),
      isScanned: isUsed,
      scannedAt: row['scanned_at'] != null
          ? DateTime.parse(row['scanned_at'] as String)
          : null,
    ));
  }

  return _AttendeesData(
    attendees: attendees,
    totalSold: attendees.length,
    totalScanned: totalScanned,
    totalCapacity: totalCapacity,
  );
});

// ─── Screen ─────────────────────────────────────────────

/// Event attendee roster with search, stats, and scan badge.
/// Route: /pro/events/:eventId/attendees
class ProviderAttendeesListScreen extends ConsumerStatefulWidget {
  const ProviderAttendeesListScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ProviderAttendeesListScreen> createState() =>
      _ProviderAttendeesListScreenState();
}

class _ProviderAttendeesListScreenState
    extends ConsumerState<ProviderAttendeesListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(_attendeesProvider(widget.eventId));

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: const SpotbookAppBar(title: 'Participants'),
      body: dataAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
        error: (e, _) => Center(
          child: Text('$e',
              style: GoogleFonts.dmSans(color: AppColors.gris)),
        ),
        data: (data) {
          final filtered = _query.isEmpty
              ? data.attendees
              : data.attendees
                  .where((a) => a.userName
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                  .toList();

          return Column(
            children: [
              // Header stats
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      '${data.totalSold}/${data.totalCapacity}',
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('participants',
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                            label: 'Vendus',
                            value: '${data.totalSold}'),
                        _StatItem(
                            label: 'Scannés',
                            value: '${data.totalScanned}'),
                        _StatItem(
                            label: 'Restants',
                            value:
                                '${data.totalCapacity - data.totalSold}'),
                      ],
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.dmSans(
                      color: AppColors.blanc, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search attendee...',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppColors.gris.withAlpha(128)),
                    prefixIcon: Icon(Icons.search,
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
              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No attendees',
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris, fontSize: 15)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _AttendeeCard(
                              attendee: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.dmSans(
                color: AppColors.gris, fontSize: 12)),
      ],
    );
  }
}

class _AttendeeCard extends StatelessWidget {
  const _AttendeeCard({required this.attendee});
  final _Attendee attendee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SpotbookAvatar(
            imageUrl: attendee.userAvatarUrl,
            radius: 20,
            name: attendee.userName,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.userName,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${attendee.ticketTypeName} · ${DateFormat('dd/MM/yy').format(attendee.purchasedAt)}',
                  style: GoogleFonts.dmSans(
                      color: AppColors.gris, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: attendee.isScanned
                  ? AppColors.success.withAlpha(30)
                  : AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              attendee.isScanned ? Icons.check : Icons.circle_outlined,
              color: attendee.isScanned
                  ? AppColors.success
                  : AppColors.grisInactif,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
