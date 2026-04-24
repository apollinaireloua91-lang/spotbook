import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../events/data/event_repository.dart';

// ── Scan result model ──────────────────────────────────────

enum ScanType { ticket, booking }

enum ScanStatus { valid, alreadyUsed, invalid, cancelled }

/// Mode de paiement du booking au moment du scan.
/// Null pour les tickets d'événement (pas de notion d'acompte).
enum PaymentMode { full, deposit }

class UnifiedScanResult {
  const UnifiedScanResult({
    required this.type,
    required this.status,
    this.reason,
    this.scannedAt,
    this.clientName,
    this.clientAvatar,
    this.serviceName,
    this.date,
    this.startTime,
    this.endTime,
    this.bookingCode,
    this.amountPaid,
    this.currency,
    this.serviceDuration,
    this.paymentMode,
    this.amountRemaining,
    this.totalAmount,
  });

  final ScanType type;
  final ScanStatus status;
  final String? reason;
  final String? scannedAt;
  final String? clientName;
  final String? clientAvatar;
  final String? serviceName;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? bookingCode;
  final double? amountPaid;
  final String? currency;
  final int? serviceDuration;

  // ── Bannière encaissement (bookings uniquement) ─────────────────────
  /// `full` → tout est payé d'avance. `deposit` → reste un solde à percevoir.
  final PaymentMode? paymentMode;

  /// Montant restant à encaisser au RDV (0 si paiement complet).
  /// Déjà clampé >= 0 côté serveur.
  final double? amountRemaining;

  /// Prix total du service — utile en mode acompte pour afficher les 3 lignes
  /// « acompte / solde / total ».
  final double? totalAmount;
}

// ── State ──────────────────────────────────────────────────

class _UnifiedScannerState {
  const _UnifiedScannerState({
    this.lastResult,
    this.isProcessing = false,
    this.scannedCount = 0,
    this.totalCount = 0,
    this.cooldown = false,
  });

  final UnifiedScanResult? lastResult;
  final bool isProcessing;
  final int scannedCount;
  final int totalCount;
  final bool cooldown;

  _UnifiedScannerState copyWith({
    UnifiedScanResult? lastResult,
    bool? isProcessing,
    int? scannedCount,
    int? totalCount,
    bool? cooldown,
  }) =>
      _UnifiedScannerState(
        lastResult: lastResult ?? this.lastResult,
        isProcessing: isProcessing ?? this.isProcessing,
        scannedCount: scannedCount ?? this.scannedCount,
        totalCount: totalCount ?? this.totalCount,
        cooldown: cooldown ?? this.cooldown,
      );
}

// ── Notifier ───────────────────────────────────────────────

class _UnifiedScannerNotifier extends Notifier<_UnifiedScannerState> {
  Timer? _cooldownTimer;

  @override
  _UnifiedScannerState build() => const _UnifiedScannerState();

  void setCounters({required int scanned, required int total}) {
    state = state.copyWith(scannedCount: scanned, totalCount: total);
  }

  Future<void> processQr(String raw, {String? eventId}) async {
    if (state.isProcessing || state.cooldown) return;
    state = state.copyWith(isProcessing: true);

    try {
      // Detect type by prefix: "B:{bookingId}|{hash}" vs "{ticketId}|{hash}"
      if (raw.startsWith('B:')) {
        await _processBookingQr(raw.substring(2));
      } else {
        await _processTicketQr(raw, eventId);
      }
    } catch (e) {
      state = state.copyWith(
        lastResult: UnifiedScanResult(
          type: ScanType.ticket,
          status: ScanStatus.invalid,
          reason: e.toString(),
        ),
        isProcessing: false,
      );
    }
    _startCooldown();
  }

  Future<void> _processBookingQr(String data) async {
    final parts = data.split('|');
    if (parts.length < 2) {
      state = state.copyWith(
        lastResult: const UnifiedScanResult(
          type: ScanType.booking,
          status: ScanStatus.invalid,
          reason: 'invalid_format',
        ),
        isProcessing: false,
      );
      return;
    }

    final bookingId = parts[0];
    final qrHash = parts[1];

    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.validateBookingQr(
      bookingId: bookingId,
      qrHash: qrHash,
    );

    final valid = result['valid'] == true;
    final reason = result['reason'] as String?;
    final details = result['bookingDetails'] as Map<String, dynamic>?;

    ScanStatus status;
    if (valid) {
      status = ScanStatus.valid;
    } else if (reason == 'already_scanned') {
      status = ScanStatus.alreadyUsed;
    } else if (reason == 'booking_cancelled') {
      status = ScanStatus.cancelled;
    } else {
      status = ScanStatus.invalid;
    }

    // Parser du paymentMode : 'full' par défaut (comportement safe — affiche
    // la bannière verte « payé en intégralité » si le backend omet le champ).
    final rawMode = details?['paymentMode'] as String?;
    final paymentMode = rawMode == 'deposit'
        ? PaymentMode.deposit
        : PaymentMode.full;

    state = state.copyWith(
      lastResult: UnifiedScanResult(
        type: ScanType.booking,
        status: status,
        reason: reason,
        scannedAt: result['scannedAt'] as String?,
        clientName: details?['clientName'] as String?,
        clientAvatar: details?['clientAvatar'] as String?,
        serviceName: details?['serviceName'] as String?,
        date: details?['date'] as String?,
        startTime: details?['startTime'] as String?,
        endTime: details?['endTime'] as String?,
        bookingCode: details?['bookingCode'] as String?,
        amountPaid: (details?['amountPaid'] as num?)?.toDouble(),
        currency: details?['currency'] as String?,
        serviceDuration: details?['serviceDuration'] as int?,
        paymentMode: details != null ? paymentMode : null,
        amountRemaining: (details?['amountRemaining'] as num?)?.toDouble(),
        totalAmount: (details?['totalAmount'] as num?)?.toDouble(),
      ),
      isProcessing: false,
      scannedCount: valid ? state.scannedCount + 1 : state.scannedCount,
    );
  }

  Future<void> _processTicketQr(String data, String? eventId) async {
    final parts = data.split('|');
    if (parts.length < 2) {
      state = state.copyWith(
        lastResult: const UnifiedScanResult(
          type: ScanType.ticket,
          status: ScanStatus.invalid,
          reason: 'invalid_format',
        ),
        isProcessing: false,
      );
      return;
    }

    final ticketId = parts[0];
    final qrHash = parts[1];

    final repo = ref.read(eventRepositoryProvider);
    final result = await repo.validateTicket(ticketId: ticketId, qrHash: qrHash);

    final valid = result['valid'] == true;
    final reason = result['reason'] as String?;

    ScanStatus status;
    if (valid) {
      status = ScanStatus.valid;
    } else if (reason == 'already_used') {
      status = ScanStatus.alreadyUsed;
    } else {
      status = ScanStatus.invalid;
    }

    state = state.copyWith(
      lastResult: UnifiedScanResult(
        type: ScanType.ticket,
        status: status,
        reason: reason,
        scannedAt: result['scannedAt'] as String?,
      ),
      isProcessing: false,
      scannedCount: valid ? state.scannedCount + 1 : state.scannedCount,
    );
  }

  void clearResult() {
    state = state.copyWith(lastResult: null);
  }

  void _startCooldown() {
    state = state.copyWith(cooldown: true);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 3), () {
      state = state.copyWith(cooldown: false, lastResult: null);
    });
  }
}

final _unifiedScannerProvider =
    NotifierProvider<_UnifiedScannerNotifier, _UnifiedScannerState>(
  _UnifiedScannerNotifier.new,
  isAutoDispose: true,
);

// ── Screen ─────────────────────────────────────────────────

class UnifiedScannerScreen extends ConsumerStatefulWidget {
  const UnifiedScannerScreen({super.key, this.eventId});

  /// If provided, limits ticket scanning to this event.
  final String? eventId;

  @override
  ConsumerState<UnifiedScannerScreen> createState() =>
      _UnifiedScannerScreenState();
}

class _UnifiedScannerScreenState extends ConsumerState<UnifiedScannerScreen> {
  late final MobileScannerController _cameraCtrl;

  @override
  void initState() {
    super.initState();
    _cameraCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    if (widget.eventId != null) {
      _loadEventCounters();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<_UnifiedScannerState>(_unifiedScannerProvider, (prev, next) {
        if (next.lastResult != null && prev?.lastResult == null) {
          HapticFeedback.heavyImpact();
          // Navigate to result screen for rich display
          if (next.lastResult != null) {
            context.push(
              '/pro/scanner/result',
              extra: next.lastResult,
            );
          }
        }
      });
    });
  }

  Future<void> _loadEventCounters() async {
    final repo = ref.read(eventRepositoryProvider);
    final scanned = await repo.getScannedCount(widget.eventId!);
    final total = await repo.getTotalTicketsSold(widget.eventId!);
    ref
        .read(_unifiedScannerProvider.notifier)
        .setCounters(scanned: scanned, total: total);
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(_unifiedScannerProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          label: l.a11yBack,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          l.scannerQr,
          style: GoogleFonts.sora(
              color: AppColors.blanc, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Counter bar (only for event mode)
          if (widget.eventId != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number,
                      color: AppColors.blanc, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l.scannedProgress(
                        state.scannedCount, state.totalCount),
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Mode indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppColors.surfaceAlt,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner,
                    color: AppColors.violetClair, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.eventId != null
                      ? l.scanTicketMode
                      : l.scanAllMode,
                  style: GoogleFonts.dmSans(
                    color: AppColors.violetClair,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraCtrl,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      ref
                          .read(_unifiedScannerProvider.notifier)
                          .processQr(
                            barcode!.rawValue!,
                            eventId: widget.eventId,
                          );
                    }
                  },
                ),
                // Processing indicator
                if (state.isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                // QR targeting frame
                if (!state.isProcessing)
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.blanc.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
