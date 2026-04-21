import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_config_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/booking_notifier.dart';
import '../../data/service_addon_repository.dart';
import '../widgets/booking_step_indicator.dart';
import '../widgets/booking_step_footer.dart';
import 'booking_steps/step1_services.dart';
import 'booking_steps/step2_date.dart';
import 'booking_steps/step3_time.dart';
import 'booking_steps/step4_summary.dart';
import 'booking_steps/step5_payment.dart';
import 'booking_steps/step6_confirmation.dart';

/// Full-screen 6-step booking flow (priority #1 — Squire-style).
/// Replaces the legacy bottom sheet for multi-service + add-ons support.
///
/// Steps:
///   0 — Service(s) selection (multi-select + add-ons)
///   1 — Date picker
///   2 — Time slot picker
///   3 — Summary + extras (promo code, etc.)
///   4 — Payment (Stripe)
///   5 — Confirmation
class BookingFlowV2Screen extends ConsumerStatefulWidget {
  const BookingFlowV2Screen({
    super.key,
    required this.providerId,
    this.initialServiceId,
  });

  final String providerId;
  final String? initialServiceId;

  @override
  ConsumerState<BookingFlowV2Screen> createState() =>
      _BookingFlowV2ScreenState();
}

class _BookingFlowV2ScreenState extends ConsumerState<BookingFlowV2Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(bookingFlowProvider.notifier);
      notifier.init(widget.providerId);
    });
  }

  void _onNext() {
    final state = ref.read(bookingFlowProvider);
    if (!_canProceed(state)) return;
    HapticFeedback.lightImpact();
    ref.read(bookingFlowProvider.notifier).nextStep();
  }

  void _onBack() {
    final state = ref.read(bookingFlowProvider);
    if (state.step == 0) {
      _confirmExit();
      return;
    }
    HapticFeedback.lightImpact();
    ref.read(bookingFlowProvider.notifier).previousStep();
  }

  Future<void> _confirmExit() async {
    final state = ref.read(bookingFlowProvider);
    // If nothing in cart, exit silently
    if (state.cart.isEmpty) {
      if (mounted) context.pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Quitter la réservation ?',
          style: GoogleFonts.sora(
              color: AppColors.blanc, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tes sélections seront perdues.',
          style: GoogleFonts.dmSans(color: AppColors.grisClair),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Rester',
                style: GoogleFonts.dmSans(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Quitter',
                style: GoogleFonts.dmSans(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(bookingFlowProvider.notifier).clearCart();
      context.pop();
    }
  }

  bool _canProceed(BookingFlowState state) {
    switch (state.step) {
      case 0:
        return state.cart.items.isNotEmpty;
      case 1:
        return state.selectedDate != null;
      case 2:
        return state.selectedSlot != null;
      case 3:
        return true;
      case 4:
        return state.clientSecret != null;
      default:
        return false;
    }
  }

  String _nextLabel(int step) {
    switch (step) {
      case 0:
        return 'Suivant';
      case 1:
        return 'Choisir l\'heure';
      case 2:
        return 'Vérifier';
      case 3:
        return 'Payer maintenant';
      case 4:
        return 'Confirmer le paiement';
      default:
        return 'Terminer';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final state = ref.watch(bookingFlowProvider);

    // Auto-add initial service from URL (first build only)
    ref.listen(bookingFlowProvider, (prev, next) {
      if (widget.initialServiceId != null &&
          (prev?.services.isEmpty ?? true) &&
          next.services.isNotEmpty &&
          next.cart.isEmpty) {
        final initial = next.services
            .where((s) => s.id == widget.initialServiceId)
            .toList();
        if (initial.isNotEmpty) {
          ref.read(bookingFlowProvider.notifier).addToCart(initial.first);
        }
      }
    });

    final isConfirmation = state.step == 5;
    // Step 5 (payment) has its own in-body Pay button, so we hide the footer.
    final hideFooter = isConfirmation || state.step == 4;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (state.step == 5) {
          context.pop();
          return;
        }
        _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: isConfirmation
              ? null
              : IconButton(
                  onPressed: _onBack,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Icon(
                      state.step == 0
                          ? Icons.close
                          : Icons.arrow_back_ios_new,
                      color: AppColors.blanc,
                      size: 16,
                    ),
                  ),
                ),
          title: Text(
            isConfirmation ? 'Réservation confirmée' : 'Réservation',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: state.isLoading && state.services.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: SpotbookLoadingShimmer.card(itemCount: 4),
              )
            : Column(
                children: [
                  if (!isConfirmation)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: BookingStepIndicator(
                        currentStep: state.step,
                        totalSteps: 5, // 6 steps (0-5), but we hide step indicator on success
                      ),
                    ),
                  Expanded(child: _buildStepBody(state)),
                  if (!hideFooter)
                    Builder(
                      builder: (_) {
                        final isSummary = state.step == 3;
                        double? amountOverride;
                        String? amountLabel;
                        if (isSummary) {
                          final cfg = ref.watch(appConfigProvider).value ??
                              AppConfig.fallback;
                          final deposit =
                              state.selectedService
                                      ?.computeDeposit(state.totalPrice) ??
                                  (state.totalPrice * 0.30 * 100)
                                          .roundToDouble() /
                                      100;
                          amountOverride = deposit + cfg.serviceFeeClient;
                          amountLabel = 'À payer maintenant';
                        }
                        return BookingStepFooter(
                          cartSubtotal: state.cartSubtotal,
                          cartServiceCount: state.cart.serviceCount,
                          cartDurationMinutes: state.cartTotalDurationMinutes,
                          currency: _currency(state),
                          canProceed: _canProceed(state),
                          nextLabel: _nextLabel(state.step),
                          onNext: _onNext,
                          amountOverride: amountOverride,
                          amountLabelOverride: amountLabel,
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  String _currency(BookingFlowState state) {
    if (state.cart.items.isNotEmpty && state.services.isNotEmpty) {
      final first = state.services.firstWhere(
        (s) => s.id == state.cart.items.first.serviceId,
        orElse: () => state.services.first,
      );
      return first.currency;
    }
    return 'CAD';
  }

  Widget _buildStepBody(BookingFlowState state) {
    switch (state.step) {
      case 0:
        return Step1Services(
          services: state.services,
          cart: state.cart,
          onToggleService: (svc) {
            final notifier = ref.read(bookingFlowProvider.notifier);
            final idx = state.cart.items
                .indexWhere((it) => it.serviceId == svc.id);
            if (idx >= 0) {
              notifier.removeFromCart(idx);
            } else {
              notifier.addToCart(svc);
            }
          },
          onToggleAddon: (serviceId, addon) {
            final notifier = ref.read(bookingFlowProvider.notifier);
            final idx = state.cart.items
                .indexWhere((it) => it.serviceId == serviceId);
            if (idx >= 0) {
              notifier.toggleCartAddon(idx, addon);
            }
          },
          loadAddonsForService: (serviceId) async {
            return ref
                .read(serviceAddonRepositoryProvider)
                .listForService(serviceId);
          },
        );
      case 1:
        return Step2Date(
          notifier: ref.read(bookingFlowProvider.notifier),
          state: state,
        );
      case 2:
        return Step3Time(
          notifier: ref.read(bookingFlowProvider.notifier),
          state: state,
          totalDurationMinutes: state.cartTotalDurationMinutes,
        );
      case 3:
        return Step4Summary(
          state: state,
          currency: _currency(state),
        );
      case 4:
        return Step5Payment(
          state: state,
          notifier: ref.read(bookingFlowProvider.notifier),
          currency: _currency(state),
        );
      case 5:
        return Step6Confirmation(state: state);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Helper extension used by step widgets for consistent currency formatting.
extension BookingFlowCurrency on double {
  String fmt(String currency) =>
      CurrencyFormatter.formatAmount(this, currency: currency);
}
