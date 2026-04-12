import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../data/auth_repository.dart';
import '../../data/category_repository.dart';
import '../../data/profile_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class _BecomeProState {
  const _BecomeProState({
    this.step = 0,
    this.isLoading = false,
    this.selectedCategory,
    this.placeDetails,
  });

  final int step;
  final bool isLoading;
  final String? selectedCategory;
  final PlaceDetails? placeDetails;

  _BecomeProState copyWith({
    int? step,
    bool? isLoading,
    String? selectedCategory,
    PlaceDetails? placeDetails,
    bool clearCat = false,
    bool clearPlace = false,
  }) =>
      _BecomeProState(
        step: step ?? this.step,
        isLoading: isLoading ?? this.isLoading,
        selectedCategory:
            clearCat ? null : (selectedCategory ?? this.selectedCategory),
        placeDetails:
            clearPlace ? null : (placeDetails ?? this.placeDetails),
      );
}

class _BecomeProNotifier extends Notifier<_BecomeProState> {
  @override
  _BecomeProState build() => const _BecomeProState();

  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  void setCategory(String? cat) =>
      state = state.copyWith(selectedCategory: cat);

  void setPlace(PlaceDetails place) =>
      state = state.copyWith(placeDetails: place);

  Future<void> submit({
    required String businessName,
    required String phone,
  }) async {
    final cat = state.selectedCategory;
    final place = state.placeDetails;
    if (businessName.trim().isEmpty || cat == null) {
      throw Exception('Veuillez remplir tous les champs obligatoires');
    }
    if (place == null) {
      throw Exception('Veuillez sélectionner une adresse');
    }

    state = state.copyWith(isLoading: true);
    try {
      // 1. Create profiles_pro row
      await ref.read(profileRepositoryProvider).upsertProProfile(
            businessName: businessName.trim(),
            category: cat,
            city: place.city,
            address: place.address,
            latitude: place.latitude,
            longitude: place.longitude,
          );

      // 2. Save phone to profiles_pro
      if (phone.trim().isNotEmpty) {
        await ref.read(profileRepositoryProvider).submitKycVerification(phone.trim());
      }

      // 3. Update role to 'pro' in users table + auth metadata
      await ref.read(authRepositoryProvider).updateUserRole('pro');

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final _becomeProProvider =
    NotifierProvider<_BecomeProNotifier, _BecomeProState>(
  _BecomeProNotifier.new,
  isAutoDispose: true,
);

// ─── Screen ─────────────────────────────────────────────────────────────────

class BecomeProSetupScreen extends ConsumerStatefulWidget {
  const BecomeProSetupScreen({super.key});

  @override
  ConsumerState<BecomeProSetupScreen> createState() =>
      _BecomeProSetupScreenState();
}

class _BecomeProSetupScreenState extends ConsumerState<BecomeProSetupScreen> {
  final _pageController = PageController();
  final _businessNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  static const _totalSteps = 3;

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextStep() {
    final s = ref.read(_becomeProProvider);

    // Validate current step before advancing
    if (s.step == 0) {
      if (_businessNameCtrl.text.trim().isEmpty) {
        _showError('Veuillez entrer le nom de votre entreprise');
        return;
      }
      if (s.selectedCategory == null) {
        _showError('Veuillez choisir une catégorie');
        return;
      }
    } else if (s.step == 1) {
      if (s.placeDetails == null) {
        _showError('Veuillez sélectionner votre adresse');
        return;
      }
    }

    ref.read(_becomeProProvider.notifier).nextStep();
    _goToStep(s.step + 1);
  }

  void _prevStep() {
    final s = ref.read(_becomeProProvider);
    if (s.step > 0) {
      ref.read(_becomeProProvider.notifier).prevStep();
      _goToStep(s.step - 1);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    try {
      await ref.read(_becomeProProvider.notifier).submit(
            businessName: _businessNameCtrl.text,
            phone: _phoneCtrl.text,
          );
      if (!mounted) return;
      context.go('/pro/feed');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_becomeProProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            onPressed: _prevStep,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
          ),
        ),
        title: Text(
          'Devenir Pro',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= s.step
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepBusinessInfo(
                    businessNameCtrl: _businessNameCtrl,
                    phoneCtrl: _phoneCtrl,
                    onNext: _nextStep,
                  ),
                  _StepAddress(
                    addressCtrl: _addressCtrl,
                    onNext: _nextStep,
                  ),
                  _StepConfirm(
                    businessName: _businessNameCtrl,
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Business Info ──────────────────────────────────────────────────

class _StepBusinessInfo extends ConsumerWidget {
  const _StepBusinessInfo({
    required this.businessNameCtrl,
    required this.phoneCtrl,
    required this.onNext,
  });

  final TextEditingController businessNameCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_becomeProProvider);
    final n = ref.read(_becomeProProvider.notifier);
    final categoriesAsync = ref.watch(proCategoriesProvider);
    final categoryLabels = categoriesAsync.when(
      data: (cats) => cats.map((c) => c.label).toList(),
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Votre entreprise',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Parlez-nous de vos services pour que les clients puissent vous trouver.',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Business name
          _field(
            controller: businessNameCtrl,
            label: 'Nom de l\'entreprise',
            hint: 'ex. Luxe Hair Studio',
            icon: Icons.business,
          ),
          const SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<String>(
            initialValue: categoryLabels.contains(s.selectedCategory)
                ? s.selectedCategory
                : null,
            hint: Text(
              'Choisir une catégorie',
              style: TextStyle(color: AppColors.gris.withAlpha(180)),
            ),
            dropdownColor: AppColors.surfaceAuth,
            style: TextStyle(color: AppColors.blanc),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.gris,
            ),
            decoration: InputDecoration(
              labelText: 'Catégorie de service',
              labelStyle: TextStyle(color: AppColors.gris),
              prefixIcon: Icon(Icons.star_outline,
                  color: AppColors.gris, size: 20),
              filled: true,
              fillColor: AppColors.surfaceAuth,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: categoryLabels
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => n.setCategory(v),
          ),
          const SizedBox(height: 16),

          // Phone
          _field(
            controller: phoneCtrl,
            label: 'Numéro de téléphone',
            hint: '+1 514 000 0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),

          // Next button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Continuer',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Step 2: Address ────────────────────────────────────────────────────────

class _StepAddress extends ConsumerWidget {
  const _StepAddress({
    required this.addressCtrl,
    required this.onNext,
  });

  final TextEditingController addressCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_becomeProProvider);
    final n = ref.read(_becomeProProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Adresse de l\'entreprise',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Où êtes-vous situé ? Les clients à proximité vous trouveront plus facilement.',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          AddressAutocompleteField(
            controller: addressCtrl,
            label: 'Adresse de l\'entreprise',
            hint: 'Commencez à taper votre adresse...',
            icon: Icons.pin_drop_outlined,
            fillColor: AppColors.surfaceAuth,
            onPlaceSelected: (place) => n.setPlace(place),
          ),

          if (s.placeDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${s.placeDetails!.city}'
                        '${s.placeDetails!.province != null ? ', ${s.placeDetails!.province}' : ''}',
                        style: GoogleFonts.dmSans(
                          color: AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Continuer',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Step 3: Confirm ────────────────────────────────────────────────────────

class _StepConfirm extends ConsumerWidget {
  const _StepConfirm({
    required this.businessName,
    required this.onSubmit,
  });

  final TextEditingController businessName;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_becomeProProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Presque terminé !',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez vos informations avant d\'activer votre compte Pro.',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAuth,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre profil Pro',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow(Icons.business, businessName.text),
                if (s.selectedCategory != null)
                  _summaryRow(Icons.star_outline, s.selectedCategory!),
                if (s.placeDetails != null)
                  _summaryRow(Icons.pin_drop_outlined, s.placeDetails!.city),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vos réservations et favoris existants seront conservés. Vous pourrez configurer vos services et disponibilités depuis votre tableau de bord Pro.',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris.withAlpha(204),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppColors.gradientAccent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: s.isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: AppColors.textOnPrimary.withAlpha(100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: s.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Text(
                        'Activer mon compte Pro',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared field helper ────────────────────────────────────────────────────

Widget _field({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: controller,
    style: TextStyle(color: AppColors.blanc),
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.gris),
      hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)),
      prefixIcon: Icon(icon, color: AppColors.gris, size: 20),
      filled: true,
      fillColor: AppColors.surfaceAuth,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
