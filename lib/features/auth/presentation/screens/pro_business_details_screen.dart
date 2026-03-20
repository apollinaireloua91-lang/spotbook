import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../data/profile_repository.dart';

const _serviceCategories = [
  'Coiffure', 'Barbier', 'Esthétique', 'Massage', 'Fitness',
  'Photographie', 'Musique', 'Design graphique', 'Cuisine',
  'Coaching', 'Tatouage', 'Événementiel',
];

class _BizState {
  const _BizState({this.isLoading = false, this.selectedCategory});
  final bool isLoading;
  final String? selectedCategory;
  _BizState copyWith({bool? isLoading, String? selectedCategory, bool clearCat = false}) =>
      _BizState(isLoading: isLoading ?? this.isLoading, selectedCategory: clearCat ? null : (selectedCategory ?? this.selectedCategory));
}

class _BizNotifier extends Notifier<_BizState> {
  @override
  _BizState build() => const _BizState();
  void setCategory(String? cat) => state = state.copyWith(selectedCategory: cat);

  Future<void> submit({required String businessName, required String city, required String bio}) async {
    final cat = state.selectedCategory;
    if (businessName.trim().isEmpty || cat == null) throw Exception('Please fill in required fields');
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(profileRepositoryProvider).upsertProProfile(businessName: businessName.trim(), category: cat, city: city.trim(), bio: bio.trim());
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final _bizProvider = NotifierProvider<_BizNotifier, _BizState>(_BizNotifier.new, isAutoDispose: true);

class ProBusinessDetailsScreen extends ConsumerStatefulWidget {
  const ProBusinessDetailsScreen({super.key});
  @override
  ConsumerState<ProBusinessDetailsScreen> createState() => _ProBusinessDetailsScreenState();
}

class _ProBusinessDetailsScreenState extends ConsumerState<ProBusinessDetailsScreen> {
  final _businessNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void dispose() { _businessNameCtrl.dispose(); _cityCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    try {
      await ref.read(_bizProvider.notifier).submit(businessName: _businessNameCtrl.text, city: _cityCtrl.text, bio: _bioCtrl.text);
      if (!mounted) return;
      context.go('/pro/verification');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_bizProvider);
    final n = ref.read(_bizProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        leading: GoRouter.of(context).canPop()
            ? Semantics(
                label: 'Retour',
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
                  onPressed: () => context.pop(),
                ),
              )
            : null,
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [_dot(active: true), const SizedBox(width: 6), _dot(active: false), const SizedBox(width: 6), _dot(active: false)]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surfaceAlt),
          child: const Text('● SETUP IN PROGRESS', style: TextStyle(color: AppColors.gris, fontSize: 11, fontWeight: FontWeight.w600))),
        const SizedBox(height: 16),
        const Text('Business Details', style: TextStyle(color: AppColors.blanc, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Step 1: Tell us about your professional services so clients can discover you easily.', style: TextStyle(color: AppColors.gris, fontSize: 14)),
        const SizedBox(height: 32),
        _field(controller: _businessNameCtrl, label: 'Business Name', hint: 'e.g., Luxe Hair Studio', icon: Icons.business),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: s.selectedCategory,
          hint: const Text('Select your main category', style: TextStyle(color: AppColors.gris)),
          dropdownColor: AppColors.surface, style: const TextStyle(color: AppColors.blanc),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gris),
          decoration: InputDecoration(labelText: 'Service Category', labelStyle: const TextStyle(color: AppColors.gris), prefixIcon: const Icon(Icons.star_outline, color: AppColors.gris, size: 20), filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: _serviceCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => n.setCategory(v),
        ),
        const SizedBox(height: 16),
        AddressAutocompleteField(
          controller: _cityCtrl,
          label: 'City / Location',
          hint: 'e.g., Los Angeles, CA',
          icon: Icons.pin_drop_outlined,
          fillColor: AppColors.surface,
        ),
        const SizedBox(height: 16),
        TextField(controller: _bioCtrl, style: const TextStyle(color: AppColors.blanc), maxLines: 4, maxLength: 300,
          decoration: InputDecoration(labelText: 'Professional Bio', hintText: 'Briefly describe your experience and what makes your services unique...', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), prefixIcon: const Icon(Icons.text_fields, color: AppColors.gris, size: 20), filled: true, fillColor: AppColors.surface, counterStyle: const TextStyle(color: AppColors.gris), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: s.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blanc, foregroundColor: AppColors.fond, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: s.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fond)) : const Text('Continue →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 32),
      ]))),
    );
  }

  Widget _dot({required bool active}) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.blanc : AppColors.gris.withAlpha(77)));

  Widget _field({required TextEditingController controller, required String label, required String hint, required IconData icon}) {
    return TextField(controller: controller, style: const TextStyle(color: AppColors.blanc), decoration: InputDecoration(labelText: label, hintText: hint, labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), prefixIcon: Icon(icon, color: AppColors.gris, size: 20), filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  }
}
