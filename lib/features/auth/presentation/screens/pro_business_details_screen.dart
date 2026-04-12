import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../data/category_repository.dart';
import '../../data/profile_repository.dart';

class _BizState {
  const _BizState({
    this.isLoading = false,
    this.selectedCategory,
    this.placeDetails,
  });
  final bool isLoading;
  final String? selectedCategory;
  final PlaceDetails? placeDetails;

  _BizState copyWith({
    bool? isLoading,
    String? selectedCategory,
    PlaceDetails? placeDetails,
    bool clearCat = false,
    bool clearPlace = false,
  }) =>
      _BizState(
        isLoading: isLoading ?? this.isLoading,
        selectedCategory:
            clearCat ? null : (selectedCategory ?? this.selectedCategory),
        placeDetails:
            clearPlace ? null : (placeDetails ?? this.placeDetails),
      );
}

class _BizNotifier extends Notifier<_BizState> {
  @override
  _BizState build() => const _BizState();

  void setCategory(String? cat) =>
      state = state.copyWith(selectedCategory: cat);

  void setPlace(PlaceDetails place) =>
      state = state.copyWith(placeDetails: place);

  Future<void> submit({
    required String businessName,
  }) async {
    final cat = state.selectedCategory;
    final place = state.placeDetails;
    if (businessName.trim().isEmpty || cat == null) {
      throw Exception('Veuillez remplir les champs obligatoires');
    }
    if (place == null) {
      throw Exception('Veuillez sélectionner une adresse');
    }
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(profileRepositoryProvider).upsertProProfile(
            businessName: businessName.trim(),
            category: cat,
            city: place.city,
            address: place.address,
            latitude: place.latitude,
            longitude: place.longitude,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final _bizProvider = NotifierProvider<_BizNotifier, _BizState>(
  _BizNotifier.new,
  isAutoDispose: true,
);

class ProBusinessDetailsScreen extends ConsumerStatefulWidget {
  const ProBusinessDetailsScreen({super.key});
  @override
  ConsumerState<ProBusinessDetailsScreen> createState() =>
      _ProBusinessDetailsScreenState();
}

class _ProBusinessDetailsScreenState
    extends ConsumerState<ProBusinessDetailsScreen> {
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref.read(_bizProvider.notifier).submit(
            businessName: _businessNameCtrl.text,
          );
      if (!mounted) return;
      context.go('/pro/feed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(_bizProvider);
    final n = ref.read(_bizProvider.notifier);
    final categoriesAsync = ref.watch(proCategoriesProvider);
    final categoryLabels = categoriesAsync.when(
      data: (cats) => cats.map((c) => c.label).toList(),
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.a11yBack,
          child: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/pro/feed');
              }
            },
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.accent.withAlpha(26),
                ),
                child: Text(
                  l.bizConfigInProgress,
                  style: GoogleFonts.dmSans(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.bizYourBusiness,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.bizSubtitle,
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Nom d'entreprise
              _field(
                controller: _businessNameCtrl,
                label: l.bizBusinessName,
                hint: l.bizBusinessHint,
                icon: Icons.business,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: categoryLabels.contains(s.selectedCategory)
                    ? s.selectedCategory
                    : null,
                hint: Text(
                  l.bizCategoryHint,
                  style: TextStyle(color: AppColors.gris),
                ),
                dropdownColor: AppColors.surfaceAuth,
                style: TextStyle(color: AppColors.blanc),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.gris,
                ),
                decoration: InputDecoration(
                  labelText: l.bizCategoryLabel,
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

              // Adresse avec autocomplétion
              AddressAutocompleteField(
                controller: _addressCtrl,
                label: l.bizAddressLabel,
                hint: l.bizAddressHint,
                icon: Icons.pin_drop_outlined,
                fillColor: AppColors.surfaceAuth,
                onPlaceSelected: (place) {
                  n.setPlace(place);
                },
              ),
              if (s.placeDetails != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${s.placeDetails!.city}'
                        '${s.placeDetails!.province != null ? ', ${s.placeDetails!.province}' : ''}',
                        style: TextStyle(
                            color: AppColors.success, fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: s.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.fond,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: s.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.fond),
                        )
                      : Text(
                          '${l.buttonContinue} \u2192',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.blanc),
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
}
