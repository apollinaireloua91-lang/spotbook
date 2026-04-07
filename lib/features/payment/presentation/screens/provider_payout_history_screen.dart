import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';

// ─── Model ──────────────────────────────────────────────

class _Payout {
  const _Payout({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.bankReference,
  });

  final String id;
  final double amount;
  final String currency;
  final String status; // processing, completed, failed
  final DateTime createdAt;
  final String? bankReference;
}

// ─── Provider ───────────────────────────────────────────

final _payoutsProvider = FutureProvider<List<_Payout>>((ref) async {
  final supabase = Supabase.instance.client;
  final res = await supabase.functions.invoke('process-payout', body: {
    'action': 'list',
  });
  if (res.status != 200) {
    // Fallback: fetch from bookings with transfer_id
    return _fallbackPayouts(supabase);
  }
  final data = res.data;
  if (data is! Map || data['payouts'] is! List) {
    return _fallbackPayouts(supabase);
  }
  return (data['payouts'] as List).map((p) {
    final m = p as Map<String, dynamic>;
    return _Payout(
      id: m['id'] as String? ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      currency: m['currency'] as String? ?? 'CAD',
      status: m['status'] as String? ?? 'processing',
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
          DateTime.now(),
      bankReference: m['bank_reference'] as String?,
    );
  }).toList();
});

Future<List<_Payout>> _fallbackPayouts(SupabaseClient supabase) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];

  final data = await supabase
      .from('bookings')
      .select('id, deposit_amount, currency, status, created_at, transfer_id')
      .eq('pro_id', uid)
      .not('transfer_id', 'is', null)
      .order('created_at', ascending: false)
      .limit(50);

  return (data as List).map((row) {
    final status = row['status'] as String? ?? '';
    String payoutStatus;
    if (status == 'completed') {
      payoutStatus = 'completed';
    } else if (status == 'cancelled_full_refund' ||
        status == 'cancelled_no_refund') {
      payoutStatus = 'failed';
    } else {
      payoutStatus = 'processing';
    }

    return _Payout(
      id: row['id'] as String,
      amount: (row['deposit_amount'] as num?)?.toDouble() ?? 0,
      currency: row['currency'] as String? ?? 'CAD',
      status: payoutStatus,
      createdAt: DateTime.parse(row['created_at'] as String),
      bankReference: row['transfer_id'] as String?,
    );
  }).toList();
}

// ─── Screen ─────────────────────────────────────────────

/// Stripe payout history: chronological list with amount/date/status.
/// Route: /pro/payouts
class ProviderPayoutHistoryScreen extends ConsumerWidget {
  const ProviderPayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(_payoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: SpotbookAppBar(
        title: 'Payout history',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.blanc, size: 22),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/pro/stripe-setup');
            },
          ),
        ],
      ),
      body: payoutsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
        error: (e, _) => Center(
          child: Text('$e',
              style: const TextStyle(color: AppColors.gris)),
        ),
        data: (payouts) {
          if (payouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.gris, size: 48),
                  const SizedBox(height: 12),
                  Text('No payouts',
                      style: GoogleFonts.sora(
                          color: AppColors.gris, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                      'Les versements apparaîtront après vos premières réservations.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          color: AppColors.grisInactif,
                          fontSize: 13)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.blanc,
            backgroundColor: AppColors.surface,
            onRefresh: () async =>
                ref.invalidate(_payoutsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payouts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _PayoutCard(payout: payouts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout});
  final _Payout payout;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (payout.status) {
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Completed';
        statusIcon = Icons.check_circle;
      case 'failed':
        statusColor = AppColors.error;
        statusLabel = 'Failed';
        statusIcon = Icons.cancel;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'Pending';
        statusIcon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payout.amount.toStringAsFixed(2)} ${payout.currency}',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy', 'fr_FR')
                      .format(payout.createdAt),
                  style: GoogleFonts.dmSans(
                      color: AppColors.gris, fontSize: 12),
                ),
                if (payout.bankReference != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Réf: ${payout.bankReference!.substring(0, payout.bankReference!.length.clamp(0, 16))}…',
                    style: const TextStyle(
                        color: AppColors.grisInactif,
                        fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.dmSans(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
