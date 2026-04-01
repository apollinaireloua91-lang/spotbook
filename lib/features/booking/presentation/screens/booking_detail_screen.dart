import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../moderation/presentation/screens/booking_report_sheet.dart';
import '../../data/booking_notifier.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';

/// Détail d\'un RDV — vue unifiée (client ou pro) selon `auth.uid()`.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _actionBusy = false;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    final supabase = Supabase.instance.client;
    _realtimeChannel = supabase
        .channel('booking-detail:${widget.bookingId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.bookingId,
          ),
          callback: (_) {
            if (mounted) {
              ref.invalidate(bookingDetailProvider(widget.bookingId));
              ref.invalidate(proBookingsProvider);
              ref.invalidate(clientBookingsProvider);
            }
          },
        )
        .subscribe();
  }

  void _reschedule(BookingModel booking) {
    HapticFeedback.mediumImpact();
    context.push(
      '/reschedule/${booking.id}',
      extra: {
        'proId': booking.proId,
        'oldSlotId': booking.timeSlotId,
      },
    );
  }

  Future<void> _openChat(BookingModel booking, {required bool isProViewer}) async {
    HapticFeedback.mediumImpact();
    setState(() => _actionBusy = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conv = await repo.getOrCreateConversation(
        clientId: booking.clientId,
        proId: booking.proId,
        bookingId: booking.status == 'confirmed' ? booking.id : null,
      );
      if (!mounted) return;
      final base = isProViewer ? '/pro/messages' : '/client/messages';
      final otherName = isProViewer
          ? (booking.clientName ?? 'Client')
          : (booking.proName ?? 'Pro');
      context.push(
        '$base/${conv.id}',
        extra: {'otherUserName': otherName},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _markCompleted(BookingModel booking) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Marquer comme terminé ?',
          style: TextStyle(color: AppColors.blanc),
        ),
        content: const Text(
          'Le client pourra laisser un avis. Cette action confirme que la prestation a eu lieu.',
          style: TextStyle(color: AppColors.gris, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer', style: TextStyle(color: AppColors.blanc)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _actionBusy = true);
    try {
      await ref.read(bookingRepositoryProvider).markBookingCompleted(booking.id);
      ref.invalidate(bookingDetailProvider(booking.id));
      ref.invalidate(proBookingsProvider);
      ref.invalidate(clientBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: const Text(
              'Rendez-vous marqué terminé',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _markRemainingPaid(BookingModel booking) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmer le paiement du solde ?',
          style: TextStyle(color: AppColors.blanc),
        ),
        content: Text(
          'Vous confirmez avoir reçu ${booking.remainingAmount.toStringAsFixed(2)} ${booking.currency} sur place.',
          style: const TextStyle(color: AppColors.gris, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer', style: TextStyle(color: AppColors.blanc)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _actionBusy = true);
    try {
      await ref.read(bookingRepositoryProvider).markRemainingPaid(booking.id);
      ref.invalidate(bookingDetailProvider(booking.id));
      ref.invalidate(proBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Solde marqué comme payé',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _proAcceptBooking(BookingModel booking) async {
    HapticFeedback.mediumImpact();
    setState(() => _actionBusy = true);
    try {
      await ref.read(bookingRepositoryProvider).proConfirmBooking(booking.id);
      ref.invalidate(bookingDetailProvider(booking.id));
      ref.invalidate(proBookingsProvider);
      ref.invalidate(clientBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Réservation acceptée',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  void _proDeclineBooking(BookingModel booking) {
    HapticFeedback.lightImpact();
    context.push('/cancel-booking/${booking.id}');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingDetailProvider(widget.bookingId));
    final uid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: async.when(
        loading: () => const Center(child: SpotbookLoadingShimmer.profile()),
        error: (e, _) => _ErrorScaffold(
          message: e.toString(),
          onBack: () => context.pop(),
        ),
        data: (booking) {
          if (booking == null) {
            return _ErrorScaffold(
              message: 'Réservation introuvable',
              onBack: () => context.pop(),
            );
          }
          final isProViewer = uid == booking.proId;
          final isClientViewer = uid == booking.clientId;
          if (!isProViewer && !isClientViewer) {
            return _ErrorScaffold(
              message: 'Accès non autorisé',
              onBack: () => context.pop(),
            );
          }
          return _DetailBody(
            booking: booking,
            isProViewer: isProViewer,
            actionBusy: _actionBusy,
            onChat: () => _openChat(booking, isProViewer: isProViewer),
            onMarkCompleted: () => _markCompleted(booking),
            onReport: () => showBookingReportSheet(
                  context,
                  ref: ref,
                  bookingId: booking.id,
                ),
            onReschedule: isClientViewer && booking.status == 'confirmed'
                ? () => _reschedule(booking)
                : null,
            onProAccept: isProViewer && booking.status == 'pending_payment'
                ? () => _proAcceptBooking(booking)
                : null,
            onProDecline: isProViewer && booking.status == 'pending_payment'
                ? () => _proDeclineBooking(booking)
                : null,
            onMarkRemainingPaid: isProViewer &&
                    booking.status == 'completed' &&
                    booking.isDepositMode &&
                    booking.hasRemainingPayment &&
                    !booking.isRemainingPaid
                ? () => _markRemainingPaid(booking)
                : null,
          );
        },
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gris),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.booking,
    required this.isProViewer,
    required this.actionBusy,
    required this.onChat,
    required this.onMarkCompleted,
    required this.onReport,
    this.onReschedule,
    this.onProAccept,
    this.onProDecline,
    this.onMarkRemainingPaid,
  });

  final BookingModel booking;
  final bool isProViewer;
  final bool actionBusy;
  final VoidCallback onChat;
  final VoidCallback onMarkCompleted;
  final VoidCallback onReport;
  final VoidCallback? onReschedule;
  final VoidCallback? onProAccept;
  final VoidCallback? onProDecline;
  final VoidCallback? onMarkRemainingPaid;

  @override
  Widget build(BuildContext context) {
    final banner = _StatusBanner(status: booking.status);
    final name = isProViewer
        ? (booking.clientName ?? 'Client')
        : (booking.proName ?? 'Prestataire');
    final avatarUrl =
        isProViewer ? booking.clientAvatarUrl : booking.proAvatarUrl;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.fond,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          title: const Text(
            'Détail du RDV',
            style: TextStyle(
              color: AppColors.blanc,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.blanc),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'report') {
                  HapticFeedback.lightImpact();
                  onReport();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Text(
                    'Signaler ce RDV',
                    style: TextStyle(color: AppColors.blanc),
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(child: banner),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _PersonCard(name: name, avatarUrl: avatarUrl),
              const SizedBox(height: 20),
              _InfoSection(booking: booking, isProViewer: isProViewer),
              const SizedBox(height: 24),
              _StatusTimeline(booking: booking),
              const SizedBox(height: 28),
              _Actions(
                booking: booking,
                isProViewer: isProViewer,
                busy: actionBusy,
                onChat: onChat,
                onMarkCompleted: onMarkCompleted,
                onReschedule: onReschedule,
                onProAccept: onProAccept,
                onProDecline: onProDecline,
                onMarkRemainingPaid: onMarkRemainingPaid,
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'confirmed' => (
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success,
          'Confirmé',
        ),
      'pending_payment' => (
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning,
          'En attente de paiement',
        ),
      'completed' => (
          AppColors.gris.withValues(alpha: 0.15),
          AppColors.grisClair,
          'Terminé',
        ),
      'cancelled_full_refund' => (
          AppColors.error.withValues(alpha: 0.12),
          AppColors.error,
          'Annulé — remboursé',
        ),
      'cancelled_no_refund' => (
          AppColors.error.withValues(alpha: 0.12),
          AppColors.error,
          'Annulé',
        ),
      _ => (
          AppColors.surfaceAlt,
          AppColors.gris,
          status,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: bg,
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surfaceAlt,
                    ),
                    errorWidget: (_, __, ___) => _fallbackAvatar(name),
                  )
                : _fallbackAvatar(name),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(String n) {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: Text(
        n.isNotEmpty ? n[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.blanc,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.booking, required this.isProViewer});

  final BookingModel booking;
  final bool isProViewer;

  @override
  Widget build(BuildContext context) {
    final start = booking.slotStartTime != null && booking.slotStartTime!.length >= 5
        ? booking.slotStartTime!.substring(0, 5)
        : '—';
    final end = booking.slotEndTime != null && booking.slotEndTime!.length >= 5
        ? booking.slotEndTime!.substring(0, 5)
        : null;
    final timeLine = end != null ? '$start — $end' : start;

    final commission = booking.depositAmount * 0.12;
    final netEst = booking.depositAmount - commission;

    final remainingStatusLabel = switch (booking.remainingPaymentStatus) {
      'paid_on_site' => 'Payé',
      'waived' => 'Annulé',
      _ => 'En attente',
    };
    final remainingStatusColor = switch (booking.remainingPaymentStatus) {
      'paid_on_site' => AppColors.success,
      'waived' => AppColors.gris,
      _ => AppColors.warning,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(Icons.spa_outlined, 'Prestation', booking.serviceName ?? '—'),
        if (booking.serviceDurationMinutes != null)
          _row(
            Icons.timer_outlined,
            'Durée',
            '${booking.serviceDurationMinutes} min',
          ),
        _row(Icons.calendar_today_outlined, 'Date', booking.slotDate ?? '—'),
        _row(Icons.schedule, 'Horaire', timeLine),

        // ─── Payment breakdown ───────────────────────────────
        _row(
          Icons.payments_outlined,
          'Total',
          '${booking.totalAmount.toStringAsFixed(2)} ${booking.currency}',
        ),
        if (booking.isDepositMode) ...[
          _rowWithBadge(
            Icons.account_balance_wallet_outlined,
            isProViewer
                ? 'Acompte reçu en ligne'
                : 'Acompte payé en ligne',
            '${booking.depositAmount.toStringAsFixed(2)} ${booking.currency}',
            badgeLabel: 'Payé',
            badgeColor: AppColors.success,
          ),
          _rowWithBadge(
            Icons.storefront_outlined,
            isProViewer
                ? 'Reste à recevoir sur place'
                : 'Reste à payer sur place',
            '${booking.remainingAmount.toStringAsFixed(2)} ${booking.currency}',
            badgeLabel: remainingStatusLabel,
            badgeColor: remainingStatusColor,
          ),
          if (isProViewer && (booking.status == 'confirmed' || booking.status == 'completed')) ...[
            const SizedBox(height: 8),
            Text(
              'Est. commission 12 % sur l\'acompte : ${commission.toStringAsFixed(2)} ${booking.currency} · Net approx. : ${netEst.toStringAsFixed(2)} ${booking.currency}',
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            Text(
              'Reste sur place : ${booking.remainingAmount.toStringAsFixed(2)} ${booking.currency} (pas de commission)',
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ] else ...[
          _rowWithBadge(
            Icons.account_balance_wallet_outlined,
            'Paiement en ligne',
            '${booking.depositAmount.toStringAsFixed(2)} ${booking.currency}',
            badgeLabel: 'Payé',
            badgeColor: AppColors.success,
          ),
          if (isProViewer && (booking.status == 'confirmed' || booking.status == 'completed')) ...[
            const SizedBox(height: 8),
            Text(
              'Est. commission 12 % : ${commission.toStringAsFixed(2)} ${booking.currency} · Net approx. : ${netEst.toStringAsFixed(2)} ${booking.currency}',
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],

        if (booking.bookingCode != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Code réservation',
            style: TextStyle(
              color: AppColors.gris,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            booking.bookingCode!,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gris, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.gris, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowWithBadge(
    IconData icon,
    String label,
    String value, {
    required String badgeLabel,
    required Color badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gris, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.gris, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.booking,
    required this.isProViewer,
    required this.busy,
    required this.onChat,
    required this.onMarkCompleted,
    this.onReschedule,
    this.onProAccept,
    this.onProDecline,
    this.onMarkRemainingPaid,
  });

  final BookingModel booking;
  final bool isProViewer;
  final bool busy;
  final VoidCallback onChat;
  final VoidCallback onMarkCompleted;
  final VoidCallback? onReschedule;
  final VoidCallback? onProAccept;
  final VoidCallback? onProDecline;
  final VoidCallback? onMarkRemainingPaid;

  @override
  Widget build(BuildContext context) {
    final canChat = booking.status == 'confirmed' ||
        booking.status == 'completed';

    if (isProViewer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (booking.status == 'pending_payment' &&
              onProAccept != null &&
              onProDecline != null) ...[
            SpotbookButton.primary(
              label: 'Accepter le RDV',
              isLoading: busy,
              onPressed: busy ? null : onProAccept,
            ),
            const SizedBox(height: 12),
            SpotbookButton.outlined(
              label: 'Refuser',
              isLoading: busy,
              onPressed: busy ? null : onProDecline,
            ),
            const SizedBox(height: 12),
          ],
          if (booking.status == 'confirmed') ...[
            SpotbookButton.primary(
              label: 'Marquer terminé',
              isLoading: busy,
              onPressed: busy ? null : onMarkCompleted,
            ),
            const SizedBox(height: 12),
          ],
          if (onMarkRemainingPaid != null) ...[
            SpotbookButton.primary(
              label: 'Marquer le reste comme payé',
              isLoading: busy,
              onPressed: busy ? null : onMarkRemainingPaid,
            ),
            const SizedBox(height: 12),
          ],
          if (canChat)
            SpotbookButton.outlined(
              label: 'Message',
              isLoading: busy,
              onPressed: busy ? null : onChat,
            ),
          if (booking.status == 'confirmed') ...[
            const SizedBox(height: 12),
            SpotbookButton.destructive(
              label: 'Annuler le RDV',
              onPressed: busy
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      context.push('/cancel-booking/${booking.id}');
                    },
            ),
          ],
        ],
      );
    }

    // Client
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canChat)
          SpotbookButton.outlined(
            label: 'Contacter',
            isLoading: busy,
            onPressed: busy ? null : onChat,
          ),
        if (onReschedule != null) ...[
          const SizedBox(height: 12),
          SpotbookButton.secondary(
            label: 'Reprogrammer',
            onPressed: busy ? null : onReschedule,
          ),
        ],
        if (booking.isUpcoming) ...[
          const SizedBox(height: 12),
          SpotbookButton.destructive(
            label: 'Annuler le RDV',
            onPressed: busy
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    context.push('/cancel-booking/${booking.id}');
                  },
          ),
        ],
        if (booking.status == 'completed') ...[
          const SizedBox(height: 12),
          SpotbookButton.primary(
            label: 'Laisser un avis',
            onPressed: busy
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    context.push(
                      '/review',
                      extra: {
                        'bookingId': booking.id,
                        'proId': booking.proId,
                        'serviceName': booking.serviceName ?? '',
                      },
                    );
                  },
          ),
          const SizedBox(height: 12),
          SpotbookButton.secondary(
            label: 'Réserver à nouveau',
            onPressed: busy
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    context.push('/client/booking-flow/${booking.proId}');
                  },
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status timeline
// ─────────────────────────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.booking});
  final BookingModel booking;

  static const _steps = [
    ('pending_payment', 'Créé', Icons.receipt_long_outlined),
    ('pending', 'Payé', Icons.payments_outlined),
    ('confirmed', 'Confirmé', Icons.check_circle_outline),
    ('completed', 'Terminé', Icons.done_all),
  ];

  int _currentIndex() {
    final s = booking.status;
    if (s == 'completed') return 3;
    if (s == 'confirmed') return 2;
    if (s == 'pending') return 1;
    if (s == 'pending_payment') return 0;
    // Cancelled / other — show up to where it got
    if (s.startsWith('cancelled')) return -1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex();
    final isCancelled = booking.status.startsWith('cancelled');

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
          const Text(
            'Suivi',
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_steps.length, (i) {
            final (_, label, icon) = _steps[i];
            final isReached = !isCancelled && i <= current;
            final isActive = !isCancelled && i == current;
            final isLast = i == _steps.length - 1;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.success.withValues(alpha: 0.15)
                            : isReached
                                ? AppColors.success.withValues(alpha: 0.08)
                                : AppColors.surfaceAlt,
                        border: isActive
                            ? Border.all(color: AppColors.success, width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isReached ? AppColors.success : AppColors.gris,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isReached ? AppColors.blanc : AppColors.gris,
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Actuel',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: isReached && i < current
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
              ],
            );
          }),
          if (isCancelled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.error, width: 1.5),
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.error),
                ),
                const SizedBox(width: 12),
                Text(
                  booking.status == 'cancelled_full_refund'
                      ? 'Annulé — remboursé'
                      : 'Annulé',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
