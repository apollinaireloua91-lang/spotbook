import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    required String bio,
  }) async {
    final cat = state.selectedCategory;
    final place = state.placeDetails;
    if (businessName.trim().isEmpty || cat == null) {
      throw Exception('Veuillez remplir les champs obligatoires');
    }
    if (place == null) {
      throw Exception('Please select an address');
    }
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(profileRepositoryProvider).upsertProProfile(
            businessName: businessName.trim(),
            category: cat,
            city: place.city,
            bio: bio.trim(),
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
  final _bioCtrl = TextEditingController();

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref.read(_bizProvider.notifier).submit(
            businessName: _businessNameCtrl.text,
            bio: _bioCtrl.text,
          );
      if (!mounted) return;
      context.go('/pro/verification');
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
      appBar: AppBar(backgroundColor: AppColors.fond, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _dot(active: true),
                const SizedBox(width: 6),
                _dot(active: false),
                const SizedBox(width: 6),
                _dot(active: false),
              ]),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.accent.withAlpha(26),
                ),
                child: const Text(
                  '● CONFIGURATION EN COURS',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Business details',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 1: Tell us about your services so clients can easily find you.',
                style: TextStyle(color: AppColors.gris, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Business name
              _field(
                controller: _businessNameCtrl,
                label: 'Business name',
                hint: 'ex. Luxe Hair Studio',
                icon: Icons.business,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: categoryLabels.contains(s.selectedCategory)
                    ? s.selectedCategory
                    : null,
                hint: const Text(
                  'Select your category',
                  style: TextStyle(color: AppColors.gris),
                ),
                dropdownColor: AppColors.surfaceAuth,
                style: const TextStyle(color: AppColors.blanc),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.gris,
                ),
                decoration: InputDecoration(
                  labelText: 'Service category',
                  labelStyle: const TextStyle(color: AppColors.gris),
                  prefixIcon: const Icon(Icons.star_outline,
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

              // Address autocomplete with lat/lng extraction
              AddressAutocompleteField(
                controller: _addressCtrl,
                label: 'Business address',
                hint: 'Start typing your address...',
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
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${s.placeDetails!.city}'
                        '${s.placeDetails!.province != null ? ', ${s.placeDetails!.province}' : ''}',
                        style: const TextStyle(
                            color: AppColors.success, fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),

              // Bio
              TextField(
                controller: _bioCtrl,
                style: const TextStyle(color: AppColors.blanc),
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'Professional bio',
                  hintText:
                      'Briefly describe your experience and what makes your services unique...',
                  labelStyle: const TextStyle(color: AppColors.gris),
                  hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)),
                  prefixIcon: const Icon(Icons.text_fields,
                      color: AppColors.gris, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceAuth,
                  counterStyle: const TextStyle(color: AppColors.gris),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.fond),
                        )
                      : const Text(
                          'Continue \u2192',
                          style: TextStyle(
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

  Widget _dot({required bool active}) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.accent : AppColors.gris.withAlpha(77),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.blanc),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.gris),
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
