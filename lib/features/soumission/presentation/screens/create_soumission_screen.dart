import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/soumission_repository.dart';
import '../../domain/soumission_model.dart';

/// Screen where Pro creates a new soumission (quote).
class CreateSoumissionScreen extends ConsumerStatefulWidget {
  const CreateSoumissionScreen({super.key});

  @override
  ConsumerState<CreateSoumissionScreen> createState() =>
      _CreateSoumissionScreenState();
}

class _CreateSoumissionScreenState
    extends ConsumerState<CreateSoumissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Regex simple pour valider le format email côté client. Le backend
  // re-valide via isValidEmail() — double-check intentionnel.
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final List<_LineItemEntry> _items = [_LineItemEntry()];
  DateTime? _validUntil;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _subtotalCents => _items.fold<int>(0, (sum, item) {
        final price = (double.tryParse(item.priceCtrl.text) ?? 0) * 100;
        final qty = int.tryParse(item.qtyCtrl.text) ?? 1;
        return sum + (price * qty).round();
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajoutez au moins un item'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final lineItems = _items.map((e) {
        final price = (double.tryParse(e.priceCtrl.text) ?? 0) * 100;
        return SoumissionLineItem(
          label: e.labelCtrl.text.trim(),
          qty: int.tryParse(e.qtyCtrl.text) ?? 1,
          unitPriceCents: price.round(),
        );
      }).toList();

      // 1. Crée la soumission en brouillon. Si l'envoi email échoue à l'étape
      // suivante, le brouillon reste accessible (recoverable state).
      final repo = ref.read(soumissionRepositoryProvider);
      final created = await repo.create(
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        lineItems: lineItems,
        clientName: _clientNameCtrl.text.trim(),
        clientEmail: _clientEmailCtrl.text.trim(),
        validUntil: _validUntil,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      // 2. Envoie l'email via Edge Function + flip status draft → sent.
      await repo.sendToClient(created.id);

      ref.invalidate(mySoumissionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Soumission envoyée au client !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nouvelle soumission',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // ── Title ──
            _SectionLabel('Titre *'),
            const SizedBox(height: 6),
            _StyledField(
              controller: _titleCtrl,
              hint: 'Ex: Rénovation salle de bain',
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Min. 3 caractères' : null,
            ),

            const SizedBox(height: 20),

            // ── Description ──
            _SectionLabel('Description'),
            const SizedBox(height: 6),
            _StyledField(
              controller: _descCtrl,
              hint: 'Détails du travail...',
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // ── Client info ──
            _SectionLabel('Informations client *'),
            const SizedBox(height: 6),
            _StyledField(
              controller: _clientNameCtrl,
              hint: 'Nom du client',
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Nom du client requis'
                  : null,
            ),
            const SizedBox(height: 10),
            _StyledField(
              controller: _clientEmailCtrl,
              hint: 'Email du client',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final val = v?.trim() ?? '';
                if (val.isEmpty) return 'Email du client requis';
                if (!_emailRegex.hasMatch(val)) return 'Email invalide';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Line items ──
            Row(
              children: [
                _SectionLabel('Items'),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _items.add(_LineItemEntry()));
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppColors.violet, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Ajouter',
                        style: GoogleFonts.dmSans(
                          color: AppColors.violet,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _items.length; i++)
              _LineItemRow(
                entry: _items[i],
                index: i,
                onRemove: _items.length > 1
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _items[i].dispose();
                          _items.removeAt(i);
                        });
                      }
                    : null,
                onChanged: () => setState(() {}),
              ),

            const SizedBox(height: 16),

            // ── Subtotal ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Text(
                    'Sous-total',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.formatAmount(_subtotalCents / 100),
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Valid until ──
            _SectionLabel('Valide jusqu\'au'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.violet,
                        surface: AppColors.surface,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) setState(() => _validUntil = date);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: AppColors.grisInactif, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _validUntil != null
                          ? '${_validUntil!.day}/${_validUntil!.month}/${_validUntil!.year}'
                          : 'Sélectionner une date',
                      style: GoogleFonts.dmSans(
                        color: _validUntil != null
                            ? AppColors.blanc
                            : AppColors.grisInactif,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Notes ──
            _SectionLabel('Notes internes'),
            const SizedBox(height: 6),
            _StyledField(
              controller: _notesCtrl,
              hint: 'Notes visibles uniquement par vous...',
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // ── Submit ──
            SpotbookButton.primary(
              label: _isSubmitting ? 'Envoi en cours...' : 'Envoyer la soumission',
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        color: AppColors.blanc,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: AppColors.grisInactif),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.grisInactif, size: 20)
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.violet, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}

class _LineItemEntry {
  final labelCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  void dispose() {
    labelCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.entry,
    required this.index,
    this.onRemove,
    required this.onChanged,
  });

  final _LineItemEntry entry;
  final int index;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(Icons.close, color: AppColors.error, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.labelCtrl,
              onChanged: (_) => onChanged(),
              style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: GoogleFonts.dmSans(color: AppColors.grisInactif),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    controller: entry.qtyCtrl,
                    onChanged: (_) => onChanged(),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Qté',
                      hintStyle:
                          GoogleFonts.dmSans(color: AppColors.grisInactif),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: entry.priceCtrl,
                    onChanged: (_) => onChanged(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Prix unitaire (\$)',
                      hintStyle:
                          GoogleFonts.dmSans(color: AppColors.grisInactif),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if (double.tryParse(v.trim()) == null) return 'Invalide';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
