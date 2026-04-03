import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TRAITEUR SOUMISSION BOTTOM SHEET — Full form with deposit preview
// ═════════════════════════════════════════════════════════════════════════════

/// Opens the Traiteur soumission form sheet.
void showTraiteurSoumissionSheet(BuildContext context, {required String proId}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SoumissionSheet(proId: proId),
  );
}

class _SoumissionSheet extends StatefulWidget {
  const _SoumissionSheet({required this.proId});

  final String proId;

  @override
  State<_SoumissionSheet> createState() => _SoumissionSheetState();
}

class _SoumissionSheetState extends State<_SoumissionSheet> {
  final _guestsCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _eventType = 'Mariage';
  DateTime _date = DateTime.now().add(const Duration(days: 14));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  String _forfait = 'Essentiel 25\$';
  final Set<String> _dietaryPrefs = {};
  bool _isSubmitting = false;

  static const _eventTypes = [
    'Mariage',
    'Anniversaire',
    'Fête familiale',
    'Corporate',
    'Baby shower',
    'Graduation',
    'Gala',
    'Autre',
  ];

  static const _forfaits = [
    'Essentiel 25\$',
    'Premium 45\$',
    'Grand événement 38\$',
    'Menu personnalisé',
  ];

  static const _dietaryOptions = [
    '🥩 Standard',
    '🥬 Végétarien',
    '🌱 Végane',
    '🚫 Sans gluten',
    '🥜 Sans noix',
    '🐟 Halal',
    '✡️ Casher',
  ];

  double get _forfaitPrice {
    if (_forfait.contains('25')) return 25;
    if (_forfait.contains('45')) return 45;
    if (_forfait.contains('38')) return 38;
    return 0;
  }

  int get _guestCount => int.tryParse(_guestsCtrl.text) ?? 0;

  double get _totalEstimate => _forfaitPrice * _guestCount;

  double get _depositAmount => (_totalEstimate * 0.30 * 100).roundToDouble() / 100;

  @override
  void dispose() {
    _guestsCtrl.dispose();
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_guestCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Veuillez entrer le nombre d\'invités',
              style: TextStyle(color: AppColors.blanc)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('catering_submissions').insert({
        'pro_id': widget.proId,
        'client_id': userId,
        'event_type': _eventType,
        'guest_count': _guestCount,
        'event_date': _date.toIso8601String(),
        'event_time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
        'location': _locationCtrl.text,
        'forfait': _forfait,
        'budget': double.tryParse(_budgetCtrl.text),
        'dietary_prefs': _dietaryPrefs.toList(),
        'notes': _notesCtrl.text,
        'estimated_total': _totalEstimate,
        'deposit_amount': _depositAmount,
        'deposit_percentage': 30,
        'status': 'pending',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              '✅ Demande envoyée ! Réponse en 24-48h.',
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
            content: Text('Erreur : $e',
                style: const TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.fond,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Text(
                  '📋 Demande de soumission',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.gris, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Scrollable form
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              children: [
                // Event type
                _buildLabel('Type d\'événement'),
                const SizedBox(height: 6),
                _buildDropdown(
                  value: _eventType,
                  items: _eventTypes,
                  onChanged: (v) => setState(() => _eventType = v!),
                ),

                const SizedBox(height: 16),

                // Guest count
                _buildLabel('Nombre d\'invités'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _guestsCtrl,
                  hint: 'Ex: 50',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Date
                _buildLabel('Date'),
                const SizedBox(height: 6),
                _buildDatePicker(),

                const SizedBox(height: 16),

                // Time
                _buildLabel('Heure'),
                const SizedBox(height: 6),
                _buildTimePicker(),

                const SizedBox(height: 16),

                // Location
                _buildLabel('Lieu'),
                const SizedBox(height: 6),
                AddressAutocompleteField(
                  controller: _locationCtrl,
                  label: '',
                  hint: 'Adresse ou salle',
                  fillColor: AppColors.fond,
                ),

                const SizedBox(height: 16),

                // Forfait
                _buildLabel('Forfait'),
                const SizedBox(height: 6),
                _buildDropdown(
                  value: _forfait,
                  items: _forfaits,
                  onChanged: (v) => setState(() => _forfait = v!),
                ),

                const SizedBox(height: 16),

                // Budget
                _buildLabel('Budget'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _budgetCtrl,
                  hint: 'Ex: 2000 \$',
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Dietary preferences
                _buildLabel('Préférences alimentaires'),
                const SizedBox(height: 8),
                _DietaryChips(
                  options: _dietaryOptions,
                  selected: _dietaryPrefs,
                  onToggle: (opt) {
                    setState(() {
                      if (_dietaryPrefs.contains(opt)) {
                        _dietaryPrefs.remove(opt);
                      } else {
                        _dietaryPrefs.add(opt);
                      }
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Notes
                _buildLabel('Notes'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _notesCtrl,
                  hint: 'Détails, thème, demandes spéciales...',
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Deposit preview
                if (_guestCount > 0 && _forfaitPrice > 0)
                  _DepositPreview(
                    forfait: _forfait,
                    guestCount: _guestCount,
                    totalEstimate: _totalEstimate,
                    depositAmount: _depositAmount,
                  ),

                const SizedBox(height: 20),

                // Submit button
                GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.5, -0.5),
                        end: Alignment(0.5, 0.5),
                        colors: [AppColors.catering, AppColors.cateringDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.blanc,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Envoyer la demande de soumission',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blanc,
                              ),
                            ),
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

  // ── Form helpers ──

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.gris,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        color: AppColors.blanc,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: AppColors.grisInactif,
        ),
        filled: true,
        fillColor: AppColors.fond,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.catering),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fond,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.gris, size: 20),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.blanc,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final label =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) {
            return Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.catering,
                  surface: AppColors.surface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 16, color: AppColors.gris),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.blanc,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    final label =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _time,
          builder: (ctx, child) {
            return Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.catering,
                  surface: AppColors.surface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => _time = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.gris),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.blanc,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIETARY CHIPS — multi-select toggle
// ═════════════════════════════════════════════════════════════════════════════

class _DietaryChips extends StatelessWidget {
  const _DietaryChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onToggle(opt);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.catering.withAlpha(38)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.catering.withAlpha(102)
                    : AppColors.border,
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: isSelected
                    ? AppColors.cateringLight
                    : AppColors.gris,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DEPOSIT PREVIEW — real-time calculation
// ═════════════════════════════════════════════════════════════════════════════

class _DepositPreview extends StatelessWidget {
  const _DepositPreview({
    required this.forfait,
    required this.guestCount,
    required this.totalEstimate,
    required this.depositAmount,
  });

  final String forfait;
  final int guestCount;
  final double totalEstimate;
  final double depositAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.catering.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.catering.withAlpha(51),
        ),
      ),
      child: Column(
        children: [
          _PreviewLine(label: 'Forfait', value: forfait),
          const SizedBox(height: 6),
          _PreviewLine(label: 'Invités', value: '$guestCount personnes'),
          const SizedBox(height: 6),
          _PreviewLine(
            label: 'Total estimé',
            value: '\$${totalEstimate.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.catering.withAlpha(38)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dépôt 30%',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blanc,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '\$${depositAmount.toStringAsFixed(0)}',
                  key: ValueKey(depositAmount),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.catering,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.gris,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.blanc,
          ),
        ),
      ],
    );
  }
}
