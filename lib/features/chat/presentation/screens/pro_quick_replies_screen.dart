import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/quick_reply_notifier.dart';
import '../../domain/quick_reply_models.dart';

/// Pro-only screen: manage (add / edit / reorder / toggle / delete) the
/// custom quick-reply chips that appear above their own chat input.
class ProQuickRepliesScreen extends ConsumerWidget {
  const ProQuickRepliesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(proQuickRepliesProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 18),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: Text(
          l.quickRepliesTitle,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: _Body(state: state),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l.quickRepliesAddButton,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showEditor(context, ref, existing: null),
      ),
    );
  }

  static Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    required ProQuickReply? existing,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReplyEditorSheet(initialText: existing?.text ?? ''),
    );
    if (result == null || !context.mounted) return;
    try {
      if (existing == null) {
        await ref.read(proQuickRepliesProvider.notifier).add(result);
      } else {
        await ref.read(proQuickRepliesProvider.notifier).edit(existing.id, result);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({required this.state});
  final ProQuickRepliesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.violet));
    }
    if (state.items.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      color: AppColors.violet,
      onRefresh: () => ref.read(proQuickRepliesProvider.notifier).refresh(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: state.items.length,
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) =>
            ref.read(proQuickRepliesProvider.notifier).reorder(oldIndex, newIndex),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _ReplyTile(
            key: ValueKey(item.id),
            item: item,
            index: index,
          );
        },
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 48, color: AppColors.violetClair),
            const SizedBox(height: 12),
            Text(
              l.quickRepliesEmptyTitle,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.quickRepliesEmptySubtitle,
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Row ───────────────────────────────────────────────────────────────────

class _ReplyTile extends ConsumerWidget {
  const _ReplyTile({
    super.key,
    required this.item,
    required this.index,
  });

  final ProQuickReply item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l.quickReplyDeleteConfirm,
              style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel, style: TextStyle(color: AppColors.gris)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.delete, style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        return ok ?? false;
      },
      onDismissed: (_) => ref.read(proQuickRepliesProvider.notifier).remove(item.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_indicator, color: AppColors.gris),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ProQuickRepliesScreen._showEditor(
                  context,
                  ref,
                  existing: item,
                ),
                child: Text(
                  item.text,
                  style: GoogleFonts.dmSans(
                    color: item.isEnabled ? AppColors.blanc : AppColors.gris,
                    fontSize: 14,
                    decoration:
                        item.isEnabled ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ),
            Switch.adaptive(
              value: item.isEnabled,
              activeThumbColor: AppColors.violet,
              onChanged: (v) => ref
                  .read(proQuickRepliesProvider.notifier)
                  .toggleEnabled(item.id, v),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit bottom sheet ───────────────────────────────────────────────

class _ReplyEditorSheet extends StatefulWidget {
  const _ReplyEditorSheet({required this.initialText});
  final String initialText;

  @override
  State<_ReplyEditorSheet> createState() => _ReplyEditorSheetState();
}

class _ReplyEditorSheetState extends State<_ReplyEditorSheet> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    final l = AppLocalizations.of(context)!;
    if (text.isEmpty) {
      setState(() => _error = l.quickReplyErrorEmpty);
      return;
    }
    if (text.length > 200) {
      setState(() => _error = l.quickReplyErrorTooLong);
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialText.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? l.quickReplyEditTitle : l.quickReplyAddTitle,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 200,
            maxLines: 3,
            minLines: 1,
            style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
            decoration: InputDecoration(
              labelText: l.quickReplyTextLabel,
              hintText: l.quickReplyTextHint,
              hintStyle: GoogleFonts.dmSans(color: AppColors.gris),
              labelStyle: GoogleFonts.dmSans(color: AppColors.gris),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l.quickReplySaveButton,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
