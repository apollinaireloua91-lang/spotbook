import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/event_repository.dart';

class _ScannerState {
  const _ScannerState({
    this.lastResult,
    this.isProcessing = false,
    this.scannedCount = 0,
    this.totalSold = 0,
    this.cooldown = false,
  });
  final ScanResult? lastResult;
  final bool isProcessing;
  final int scannedCount;
  final int totalSold;
  final bool cooldown;

  _ScannerState copyWith({
    ScanResult? lastResult,
    bool? isProcessing,
    int? scannedCount,
    int? totalSold,
    bool? cooldown,
  }) =>
      _ScannerState(
        lastResult: lastResult ?? this.lastResult,
        isProcessing: isProcessing ?? this.isProcessing,
        scannedCount: scannedCount ?? this.scannedCount,
        totalSold: totalSold ?? this.totalSold,
        cooldown: cooldown ?? this.cooldown,
      );
}

class ScanResult {
  const ScanResult({required this.valid, this.reason, this.scannedAt});
  final bool valid;
  final String? reason;
  final String? scannedAt;
}

class _ScannerNotifier extends Notifier<_ScannerState> {
  Timer? _cooldownTimer;

  @override
  _ScannerState build() => const _ScannerState();

  void setCounters({required int scanned, required int total}) {
    state = state.copyWith(scannedCount: scanned, totalSold: total);
  }

  Future<void> processQr(String raw, String eventId) async {
    if (state.isProcessing || state.cooldown) return;

    state = state.copyWith(isProcessing: true);
    try {
      final parts = raw.split('|');
      if (parts.length < 2) {
        state = state.copyWith(
          lastResult: const ScanResult(valid: false, reason: 'invalid_format'),
          isProcessing: false,
        );
        _startCooldown();
        return;
      }

      final ticketId = parts[0];
      final qrHash = parts[1];

      final repo = ref.read(eventRepositoryProvider);
      final result = await repo.validateTicket(ticketId: ticketId, qrHash: qrHash);

      final valid = result['valid'] == true;
      state = state.copyWith(
        lastResult: ScanResult(
          valid: valid,
          reason: result['reason'] as String?,
          scannedAt: result['scannedAt'] as String?,
        ),
        isProcessing: false,
        scannedCount: valid ? state.scannedCount + 1 : state.scannedCount,
      );
    } catch (e) {
      state = state.copyWith(
        lastResult: ScanResult(valid: false, reason: e.toString()),
        isProcessing: false,
      );
    }
    _startCooldown();
  }

  void _startCooldown() {
    state = state.copyWith(cooldown: true);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 2), () {
      state = state.copyWith(cooldown: false, lastResult: null);
    });
  }
}

final _scannerProvider = NotifierProvider<_ScannerNotifier, _ScannerState>(
  _ScannerNotifier.new,
  isAutoDispose: true,
);

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final MobileScannerController _cameraCtrl;

  @override
  void initState() {
    super.initState();
    _cameraCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _loadCounters();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<_ScannerState>(_scannerProvider, (prev, next) {
        if (next.lastResult != null && prev?.lastResult == null) {
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  Future<void> _loadCounters() async {
    final repo = ref.read(eventRepositoryProvider);
    final scanned = await repo.getScannedCount(widget.eventId);
    final total = await repo.getTotalTicketsSold(widget.eventId);
    ref.read(_scannerProvider.notifier).setCounters(scanned: scanned, total: total);
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(_scannerProvider);
    final result = state.lastResult;

    Color overlayColor = Colors.transparent;
    String overlayText = '';
    IconData overlayIcon = Icons.qr_code_scanner;

    if (result != null) {
      if (result.valid) {
        overlayColor = AppColors.success.withValues(alpha: 0.3);
        overlayText = l.ticketValidated;
        overlayIcon = Icons.check_circle;
      } else if (result.reason == 'already_used') {
        overlayColor = AppColors.warning.withValues(alpha: 0.3);
        overlayText = result.scannedAt != null ? l.alreadyScannedAt(result.scannedAt!) : l.alreadyScanned;
        overlayIcon = Icons.warning_amber;
      } else {
        overlayColor = AppColors.error.withValues(alpha: 0.3);
        overlayText = l.invalidTicket;
        overlayIcon = Icons.cancel;
      }
    }

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
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(l.scannerQr,
            style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Counter bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.confirmation_number, color: AppColors.blanc, size: 18),
                const SizedBox(width: 8),
                Text(
                  l.scannedProgress(state.scannedCount, state.totalSold),
                  style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600),
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
                          .read(_scannerProvider.notifier)
                          .processQr(barcode!.rawValue!, widget.eventId);
                    }
                  },
                ),
                // Overlay for scan result
                if (result != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: overlayColor,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(overlayIcon, color: AppColors.blanc, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            overlayText,
                            style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                // QR targeting frame
                if (result == null)
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.blanc.withValues(alpha: 0.5), width: 2),
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
