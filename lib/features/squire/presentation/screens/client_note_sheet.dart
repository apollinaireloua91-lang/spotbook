import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/squire_repository.dart';
import '../../domain/squire_models.dart';

/// Priority #8 — Private pro notes about a client.
/// Opens as a modal sheet from a client's booking detail or CRM list.
class ClientNoteSheet extends ConsumerStatefulWidget {
  const ClientNoteSheet({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  final String clientId;
  final String clientName;

  static Future<void> show(
    BuildContext context, {
    required String clientId,
    required String clientName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ClientNoteSheet(
        clientId: clientId,
        clientName: clientName,
      ),
    );
  }

  @override
  ConsumerState<ClientNoteSheet> createState() =>
      _ClientNoteSheetState();
}

class _ClientNoteSheetState extends ConsumerState<ClientNoteSheet> {
  final _noteCtrl = TextEditingController();
  final _tags = <String>{};
  ClientNote? _existing;
  bool _loading = true;
  bool _saving = false;

  static const _suggestedTags = [
    'Allergie',
    'Préférence',
    'Style',
    'Ponctuel',
    'Généreux',
    'Difficile',
    'VIP',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(squireRepositoryProvider);
      final note = await repo.loadClientNote(clientId: widget.clientId);
      if (!mounted) return;
      setState(() {
        _existing = note;
        if (note != null) {
          _noteCtrl.text = note.note;
          _tags.addAll(note.tags);
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      await repo.saveClientNote(
        clientId: widget.clientId,
        note: text,
        tags: _tags.toList(),
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (_existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Supprimer la note ?',
            style: GoogleFonts.sora(color: AppColors.blanc)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.dmSans(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.dmSans(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = ref.read(squireRepositoryProvider);
      await repo.deleteClientNote(_existing!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
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
                Row(
                  children: [
                    Icon(Icons.lock_outline,
                        color: AppColors.violet, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Note privée',
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Sur ${widget.clientName} — jamais visible par le client.',
                  style: GoogleFonts.dmSans(
                      color: AppColors.gris, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 5,
                  maxLength: 2000,
                  style: GoogleFonts.dmSans(color: AppColors.blanc),
                  decoration: InputDecoration(
                    hintText: 'Allergie, préférence, style préféré...',
                    hintStyle: GoogleFonts.dmSans(color: AppColors.gris),
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Tags',
                    style: GoogleFonts.dmSans(
                        color: AppColors.gris, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _suggestedTags.map((t) {
                    final selected = _tags.contains(t);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (selected) {
                            _tags.remove(t);
                          } else {
                            _tags.add(t);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.violet
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppColors.violet
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          t,
                          style: GoogleFonts.dmSans(
                            color:
                                selected ? Colors.white : AppColors.blanc,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (_existing != null) ...[
                      IconButton(
                        onPressed: _delete,
                        icon: Icon(Icons.delete_outline,
                            color: AppColors.error),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: SpotbookButton.primary(
                        label:
                            _saving ? 'Enregistrement...' : 'Enregistrer',
                        onPressed: _saving ||
                                _noteCtrl.text.trim().isEmpty
                            ? null
                            : _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
