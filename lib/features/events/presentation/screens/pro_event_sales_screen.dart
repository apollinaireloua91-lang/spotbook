import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/event_repository.dart';
import '../../domain/event_models.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _SalesData {
  const _SalesData({
    required this.event,
    required this.totalSold,
    required this.scanned,
  });
  final EventModel event;
  final int totalSold;
  final int scanned;

  double get revenue => event.ticketTypes.fold(
        0.0,
        (sum, t) => sum + t.price * t.soldCount,
      );

  int get totalCapacity =>
      event.ticketTypes.fold(0, (sum, t) => sum + t.quantity);

  double get progress =>
      totalCapacity > 0 ? (totalSold / totalCapacity).clamp(0.0, 1.0) : 0;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _eventSalesProvider =
    FutureProvider.autoDispose.family<_SalesData, String>(
  (ref, eventId) async {
    final repo = ref.read(eventRepositoryProvider);
    final results = await Future.wait([
      repo.getEvent(eventId),
      repo.getTotalTicketsSold(eventId),
      repo.getScannedCount(eventId),
    ]);
    return _SalesData(
      event: results[0] as EventModel,
      totalSold: results[1] as int,
      scanned: results[2] as int,
    );
  },
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProEventSalesScreen extends ConsumerWidget {
  const ProEventSalesScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_eventSalesProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
          onPressed: () => context.pop(),
        ),
        title: async.when(
          data: (d) => Text(
            d.event.title,
            style: const TextStyle(
                color: AppColors.blanc,
                fontWeight: FontWeight.bold,
                fontSize: 17),
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const Text('Chargement...',
              style: TextStyle(color: AppColors.gris)),
          error: (_, __) => const Text('Événement',
              style: TextStyle(color: AppColors.blanc)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.blanc),
            onPressed: () => context.push('/create-event'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.blanc)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur : $e',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center),
          ),
        ),
        data: (data) => _Body(
          data: data,
          eventId: eventId,
          onRefresh: () => ref.invalidate(_eventSalesProvider(eventId)),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.eventId,
    required this.onRefresh,
  });
  final _SalesData data;
  final String eventId;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final date = data.event.eventDate;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year} • '
            '${date.hour.toString().padLeft(2, '0')}h'
            '${date.minute.toString().padLeft(2, '0')}'
        : null;

    return RefreshIndicator(
      color: AppColors.blanc,
      backgroundColor: AppColors.surface,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date + status badge
            if (dateStr != null) ...[
              Text(dateStr,
                  style: const TextStyle(color: AppColors.gris, fontSize: 13)),
              const SizedBox(height: 8),
            ],
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: data.event.isActive
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: data.event.isActive
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: Text(
                data.event.isActive ? 'En ligne' : 'Inactif',
                style: TextStyle(
                  color: data.event.isActive
                      ? AppColors.success
                      : AppColors.gris,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Revenus',
                    value: '${data.revenue.toStringAsFixed(0)} CA\$',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Tickets sold',
                    value: '${data.totalSold} / ${data.totalCapacity}',
                    icon: Icons.confirmation_number_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress card
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sales progress',
                          style: TextStyle(
                              color: AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(
                          '${(data.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: data.progress,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.blanc),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data.totalCapacity - data.totalSold} spots remaining',
                    style: const TextStyle(
                        color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scanned
            _SectionCard(
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_outlined,
                      color: AppColors.gris, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Tickets scanned',
                        style: TextStyle(
                            color: AppColors.blanc, fontSize: 14)),
                  ),
                  Text('${data.scanned} / ${data.totalSold}',
                      style: const TextStyle(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ticket types breakdown
            if (data.event.ticketTypes.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Ticket types',
                  style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.event.ticketTypes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final tt = data.event.ticketTypes[i];
                  return _SectionCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tt.name,
                                  style: const TextStyle(
                                      color: AppColors.blanc,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                '${tt.price.toStringAsFixed(2)} CA\$',
                                style: const TextStyle(
                                    color: AppColors.gris,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text('${tt.soldCount} / ${tt.quantity}',
                            style: const TextStyle(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            SpotbookButton.primary(
              label: 'Scan tickets',
              icon: Icons.qr_code_scanner,
              onPressed: () => context.push('/scanner/$eventId'),
            ),
            const SizedBox(height: 10),
            SpotbookButton.secondary(
              label: 'Manage event',
              icon: Icons.settings_outlined,
              onPressed: () => context.push('/pro/events'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gris, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.gris, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}
