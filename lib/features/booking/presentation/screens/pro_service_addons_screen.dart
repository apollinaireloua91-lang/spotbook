import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../../shared/widgets/spotbook_text_field.dart';
import '../../data/service_addon_repository.dart';
import '../../domain/service_addon_models.dart';

/// Screen for Pro to manage add-ons attached to a specific service.
///
/// State is managed locally in this StatefulWidget (simpler than a family
/// notifier given Riverpod 3.x API constraints). The repository remains a
/// Riverpod provider for testability.
class ProServiceAddonsScreen extends ConsumerStatefulWidget {
  const ProServiceAddonsScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.currency,
    required this.proId,
  });

  final String serviceId;
  final String serviceName;
  final String currency;
  final String proId;

  /// Business rule: max add-ons per service — caps UX clutter, matches Squire.
  static const int maxAddonsPerService = 10;

  @override
  ConsumerState<ProServiceAddonsScreen> createState() =>
      _ProServiceAddonsScreenState();
}

class _ProServiceAddonsScreenState
    extends ConsumerState<ProServiceAddonsScreen> {
  List<ServiceAddon> _addons = [];
  bool _isLoading = true;
  String? _error;

  bool get _canAddMore =>
      _addons.length < ProServiceAddonsScreen.maxAddonsPerService;

  ServiceAddonRepository get _repo =>
      ref.read(serviceAddonRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final addons = await _repo.listForService(widget.serviceId);
      if (!mounted) return;
      setState(() {
        _addons = addons;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Create or update via the form sheet.
  Future<bool> _submit(ServiceAddon draftOrEdited,
      {ServiceAddon? editing}) async {
    if (editing == null && !_canAddMore) {
      _showError(
          'Maximum ${ProServiceAddonsScreen.maxAddonsPerService} extras par service.');
      return false;
    }
    try {
      if (editing != null) {
        final saved = await _repo.update(draftOrEdited);
        setState(() {
          _addons = _addons.map((a) => a.id == saved.id ? saved : a).toList();
        });
      } else {
        final created = await _repo.create(draftOrEdited);
        setState(() {
          _addons = [..._addons, created];
        });
      }
      return true;
    } catch (e) {
      _showError(e.toString());
      return false;
    }
  }

  Future<void> _toggleActive(ServiceAddon addon) async {
    final next = !addon.isActive;
    final previous = _addons;
    // Optimistic
    setState(() {
      _addons = _addons
          .map((a) => a.id == addon.id ? a.copyWith(isActive: next) : a)
          .toList();
    });
    try {
      await _repo.setActive(addon.id, next);
    } catch (e) {
      setState(() => _addons = previous);
      _showError(e.toString());
    }
  }

  Future<void> _delete(ServiceAddon addon) async {
    final previous = _addons;
    setState(() => _addons = _addons.where((a) => a.id != addon.id).toList());
    try {
      await _repo.delete(addon.id);
    } catch (e) {
      setState(() => _addons = previous);
      _showError(e.toString());
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final previous = _addons;
    if (newIndex > oldIndex) newIndex -= 1;
    final list = [..._addons];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() => _addons = list);
    try {
      await _repo.reorder(list);
    } catch (e) {
      setState(() => _addons = previous);
      _showError(e.toString());
    }
  }

  Future<void> _openForm({ServiceAddon? editing}) async {
    await _AddonFormSheet.show(
      context: context,
      serviceId: widget.serviceId,
      proId: widget.proId,
      currency: widget.currency,
      editing: editing,
      onSubmit: (data) => _submit(data, editing: editing),
    );
  }

  Future<void> _confirmDelete(ServiceAddon addon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Supprimer cet extra ?',
          style: GoogleFonts.sora(color: AppColors.blanc),
        ),
        content: Text(
          '«${addon.name}» ne sera plus proposé aux clients. Les réservations passées gardent leur extra.',
          style: GoogleFonts.dmSans(color: AppColors.grisClair),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.dmSans(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: GoogleFonts.dmSans(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await _delete(addon);
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
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
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
        ),
        title: Text(
          'Extras',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading && _addons.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SpotbookLoadingShimmer.card(itemCount: 4),
            )
          : _error != null && _addons.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(color: AppColors.gris),
                    ),
                  ),
                )
              : _buildList(),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        // Header: service name + count + add button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_addons.length} / ${ProServiceAddonsScreen.maxAddonsPerService} extras',
                      style: GoogleFonts.dmSans(
                          color: AppColors.gris, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_canAddMore)
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 22),
                ),
            ],
          ),
        ),
        // Helper text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.violetClair, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les extras apparaissent comme options payantes lors de la réservation. Ex : «Lavage +5\$».',
                    style: GoogleFonts.dmSans(
                      color: AppColors.grisClair,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // List
        Expanded(
          child: _addons.isEmpty
              ? EmptyState(
                  icon: Icons.tune_rounded,
                  title: 'Aucun extra',
                  subtitle:
                      'Propose des options payantes en plus de ton service (ex : lavage, soin, produit).',
                  ctaLabel: 'Ajouter un extra',
                  onCta: _canAddMore ? () => _openForm() : null,
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: _addons.length,
                  onReorder: (o, n) {
                    HapticFeedback.selectionClick();
                    _reorder(o, n);
                  },
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, i) {
                    final addon = _addons[i];
                    return Padding(
                      key: ValueKey(addon.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AddonTile(
                        addon: addon,
                        currency: widget.currency,
                        index: i,
                        onEdit: () => _openForm(editing: addon),
                        onToggle: () => _toggleActive(addon),
                        onDelete: () => _confirmDelete(addon),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AddonTile extends StatelessWidget {
  const _AddonTile({
    required this.addon,
    required this.currency,
    required this.index,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ServiceAddon addon;
  final String currency;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priceLabel =
        CurrencyFormatter.formatAmount(addon.price, currency: currency);
    return SpotbookCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: Icon(Icons.drag_indicator,
                  color: AppColors.gris.withValues(alpha: 0.7), size: 20),
            ),
          ),
          // Name + price + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        addon.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+$priceLabel',
                        style: GoogleFonts.dmSans(
                          color: AppColors.violetClair,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (addon.durationMinutes > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${addon.durationMinutes} min',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (addon.description != null &&
                    addon.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    addon.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppColors.grisClair,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
                if (!addon.isActive) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gris.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Masqué',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions column
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                icon: Icon(Icons.edit_outlined,
                    color: AppColors.violetClair, size: 18),
                tooltip: 'Modifier',
              ),
              IconButton(
                onPressed: onToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                icon: Icon(
                  addon.isActive
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.gris,
                  size: 18,
                ),
                tooltip: addon.isActive ? 'Masquer' : 'Afficher',
              ),
              IconButton(
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                icon: Icon(Icons.delete_outline,
                    color: AppColors.error, size: 18),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet form for creating or editing an add-on.
class _AddonFormSheet extends StatefulWidget {
  const _AddonFormSheet({
    required this.serviceId,
    required this.proId,
    required this.currency,
    required this.editing,
    required this.onSubmit,
  });

  final String serviceId;
  final String proId;
  final String currency;
  final ServiceAddon? editing;
  final Future<bool> Function(ServiceAddon) onSubmit;

  static Future<void> show({
    required BuildContext context,
    required String serviceId,
    required String proId,
    required String currency,
    required ServiceAddon? editing,
    required Future<bool> Function(ServiceAddon) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddonFormSheet(
        serviceId: serviceId,
        proId: proId,
        currency: currency,
        editing: editing,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<_AddonFormSheet> createState() => _AddonFormSheetState();
}

class _AddonFormSheetState extends State<_AddonFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late int _duration;
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _priceCtrl = TextEditingController(
        text: e != null ? e.price.toStringAsFixed(2) : '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _duration = e?.durationMinutes ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final priceText = _priceCtrl.text.trim().replaceAll(',', '.');
    final desc = _descCtrl.text.trim();

    // Validation — mirror the DB CHECK constraints client-side
    if (name.length < 2) {
      setState(() => _formError = 'Nom trop court (min 2 caractères).');
      return;
    }
    if (name.length > 80) {
      setState(() => _formError = 'Nom trop long (max 80 caractères).');
      return;
    }
    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      setState(() => _formError = 'Prix invalide.');
      return;
    }
    if (price > 500) {
      setState(() => _formError = 'Prix max : 500\$.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final payload = widget.editing != null
        ? widget.editing!.copyWith(
            name: name,
            description: desc.isEmpty ? null : desc,
            price: price,
            durationMinutes: _duration,
          )
        : ServiceAddon.draft(
            serviceId: widget.serviceId,
            proId: widget.proId,
            name: name,
            description: desc.isEmpty ? null : desc,
            price: price,
            durationMinutes: _duration,
          );

    final ok = await widget.onSubmit(payload);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isEdit ? 'Modifier l\'extra' : 'Nouvel extra',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Une option payante optionnelle (ex : lavage, soin, produit).',
              style:
                  GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Name
            SpotbookTextField(
              controller: _nameCtrl,
              label: 'Nom',
              hint: 'ex : Lavage des cheveux',
              maxLength: 80,
            ),
            const SizedBox(height: 12),

            // Price + duration row
            Row(
              children: [
                Expanded(
                  child: SpotbookTextField(
                    controller: _priceCtrl,
                    label: 'Prix (${widget.currency})',
                    hint: '5.00',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DurationDropdown(
                    value: _duration,
                    onChanged: (v) => setState(() => _duration = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description (optional)
            SpotbookTextField(
              controller: _descCtrl,
              label: 'Description (optionnel)',
              hint: 'Courte description pour le client',
              maxLength: 280,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            if (_formError != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: GoogleFonts.dmSans(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SpotbookButton.primary(
              label: _saving
                  ? 'Enregistrement...'
                  : (isEdit ? 'Enregistrer' : 'Créer l\'extra'),
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
            SpotbookButton.secondary(
              label: 'Annuler',
              onPressed: _saving ? null : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dropdown for picking add-on duration (0, 5, 10, 15, 20, 30, 45, 60 min).
class _DurationDropdown extends StatelessWidget {
  const _DurationDropdown({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [0, 5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durée sup.',
          style: GoogleFonts.dmSans(
            color: AppColors.grisClair,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surface,
            iconEnabledColor: AppColors.gris,
            style: GoogleFonts.dmSans(
              color: AppColors.blanc,
              fontSize: 15,
            ),
            items: _options
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m == 0 ? 'Aucune' : '$m min'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
