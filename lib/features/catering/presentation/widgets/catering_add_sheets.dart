import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/catering_repository.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ADD DISH BOTTOM SHEET
// ═════════════════════════════════════════════════════════════════════════════

void showAddDishSheet(
  BuildContext context, {
  required CateringRepository repo,
  required String proId,
  required VoidCallback onDone,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddDishSheet(
      repo: repo,
      proId: proId,
      onDone: onDone,
    ),
  );
}

class _AddDishSheet extends StatefulWidget {
  const _AddDishSheet({
    required this.repo,
    required this.proId,
    required this.onDone,
  });

  final CateringRepository repo;
  final String proId;
  final VoidCallback onDone;

  @override
  State<_AddDishSheet> createState() => _AddDishSheetState();
}

class _AddDishSheetState extends State<_AddDishSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content:
              Text('Please enter a dish name', style: TextStyle(color: AppColors.blanc)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.repo.addMenuItem(
        proId: widget.proId,
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        pricePerPerson: double.tryParse(_priceCtrl.text),
        emoji: _emojiCtrl.text.trim().isEmpty ? null : _emojiCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Dish added!', style: TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error: $e', style: TextStyle(color: AppColors.blanc)),
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
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
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
                  '🍽️ Add Dish',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.gris, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              children: [
                _CateringField(controller: _nameCtrl, label: 'Dish name', hint: 'E.g. Jollof Rice'),
                const SizedBox(height: 14),
                _CateringField(controller: _descCtrl, label: 'Description', hint: 'Short description', maxLines: 2),
                const SizedBox(height: 14),
                _CateringField(
                  controller: _priceCtrl,
                  label: 'Price per person (\$)',
                  hint: 'E.g. 15',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _CateringField(controller: _emojiCtrl, label: 'Emoji (optional)', hint: '🍗'),
                const SizedBox(height: 24),
                _CateringSubmitButton(
                  label: 'Add Dish',
                  isSubmitting: _isSubmitting,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADD PACKAGE BOTTOM SHEET
// ═════════════════════════════════════════════════════════════════════════════

void showAddPackageSheet(
  BuildContext context, {
  required CateringRepository repo,
  required String proId,
  required VoidCallback onDone,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddPackageSheet(
      repo: repo,
      proId: proId,
      onDone: onDone,
    ),
  );
}

class _AddPackageSheet extends StatefulWidget {
  const _AddPackageSheet({
    required this.repo,
    required this.proId,
    required this.onDone,
  });

  final CateringRepository repo;
  final String proId;
  final VoidCallback onDone;

  @override
  State<_AddPackageSheet> createState() => _AddPackageSheetState();
}

class _AddPackageSheetState extends State<_AddPackageSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _inclusionsCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _inclusionsCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text);
    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Name and price are required',
              style: TextStyle(color: AppColors.blanc)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final inclusions = _inclusionsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await widget.repo.addForfait(
        proId: widget.proId,
        name: name,
        pricePerPerson: price,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        inclusions: inclusions,
        minGuests: int.tryParse(_minCtrl.text),
        maxGuests: int.tryParse(_maxCtrl.text),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Package added!', style: TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error: $e', style: TextStyle(color: AppColors.blanc)),
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
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: BoxDecoration(
        color: AppColors.fond,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Text(
                  '📦 Add Package',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.gris, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              children: [
                _CateringField(controller: _nameCtrl, label: 'Package name', hint: 'E.g. Premium'),
                const SizedBox(height: 14),
                _CateringField(
                  controller: _priceCtrl,
                  label: 'Price per person (\$)',
                  hint: 'E.g. 45',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _CateringField(controller: _descCtrl, label: 'Description', hint: 'What\'s included', maxLines: 2),
                const SizedBox(height: 14),
                _CateringField(
                  controller: _inclusionsCtrl,
                  label: 'Inclusions (comma separated)',
                  hint: 'Appetizer, Main course, Dessert, Drinks',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CateringField(
                        controller: _minCtrl,
                        label: 'Min guests',
                        hint: '10',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CateringField(
                        controller: _maxCtrl,
                        label: 'Max guests',
                        hint: '200',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _CateringSubmitButton(
                  label: 'Add Package',
                  isSubmitting: _isSubmitting,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED FORM HELPERS
// ═════════════════════════════════════════════════════════════════════════════

class _CateringField extends StatelessWidget {
  const _CateringField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.gris,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.blanc),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.grisInactif),
            filled: true,
            fillColor: AppColors.fond,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.catering),
            ),
          ),
        ),
      ],
    );
  }
}

class _CateringSubmitButton extends StatelessWidget {
  const _CateringSubmitButton({
    required this.label,
    required this.isSubmitting,
    required this.onTap,
  });

  final String label;
  final bool isSubmitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
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
          child: isSubmitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.blanc,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                ),
        ),
      ),
    );
  }
}
