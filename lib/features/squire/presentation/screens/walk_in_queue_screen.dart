import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/squire_repository.dart';
import '../../domain/squire_models.dart';

/// Priority #6 — Walk-in queue management for Pros.
/// Lists active walk-ins with position, wait time, status toggle actions.
class WalkInQueueScreen extends ConsumerStatefulWidget {
  const WalkInQueueScreen({super.key});

  @override
  ConsumerState<WalkInQueueScreen> createState() => _WalkInQueueScreenState();
}

class _WalkInQueueScreenState extends ConsumerState<WalkInQueueScreen> {
  List<WalkInEntry> _queue = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      final queue = await repo.listActiveWalkIns();
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addWalkIn() async {
    final result = await _AddWalkInSheet.show(context);
    if (result == null) return;
    try {
      final repo = ref.read(squireRepositoryProvider);
      await repo.addWalkIn(
        clientName: result['name'] as String,
        clientPhone: result['phone'] as String?,
        estimatedWaitMinutes: result['wait'] as int?,
      );
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commonErrorWithDetail(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateStatus(
      WalkInEntry entry, WalkInStatus status) async {
    HapticFeedback.lightImpact();
    try {
      final repo = ref.read(squireRepositoryProvider);
      await repo.updateWalkInStatus(entry.id, status);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commonErrorWithDetail(e.toString()))),
        );
      }
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
          onPressed: () => context.pop(),
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
          'File d\'attente',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _addWalkIn,
            icon: Icon(Icons.person_add, color: AppColors.violet),
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SpotbookLoadingShimmer.card(itemCount: 4),
            )
          : RefreshIndicator(
              color: AppColors.violet,
              onRefresh: _load,
              child: _queue.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        EmptyState(
                          icon: Icons.people_alt_outlined,
                          title: 'File vide',
                          subtitle:
                              'Ajoute un walk-in quand un client arrive sans RDV.',
                          ctaLabel: 'Ajouter un walk-in',
                          onCta: _addWalkIn,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _queue.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => _WalkInTile(
                        entry: _queue[i],
                        onStart: () =>
                            _updateStatus(_queue[i], WalkInStatus.inService),
                        onComplete: () =>
                            _updateStatus(_queue[i], WalkInStatus.completed),
                        onNoShow: () =>
                            _updateStatus(_queue[i], WalkInStatus.noShow),
                      ),
                    ),
            ),
    );
  }
}

class _WalkInTile extends StatelessWidget {
  const _WalkInTile({
    required this.entry,
    required this.onStart,
    required this.onComplete,
    required this.onNoShow,
  });

  final WalkInEntry entry;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onNoShow;

  @override
  Widget build(BuildContext context) {
    final isInService = entry.status == WalkInStatus.inService;
    return SpotbookCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isInService
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.violet.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${entry.position}',
                    style: GoogleFonts.sora(
                      color: isInService
                          ? AppColors.success
                          : AppColors.violet,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.clientName,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.estimatedWaitMinutes != null)
                      Text(
                        '~${entry.estimatedWaitMinutes} min d\'attente',
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (isInService)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'EN COURS',
                    style: GoogleFonts.dmSans(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!isInService)
                Expanded(
                  child: SpotbookButton.primary(
                    label: 'Démarrer',
                    onPressed: onStart,
                  ),
                ),
              if (isInService)
                Expanded(
                  child: SpotbookButton.primary(
                    label: 'Terminer',
                    onPressed: onComplete,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onNoShow,
                icon:
                    Icon(Icons.person_off, color: AppColors.error, size: 18),
                tooltip: 'No-show',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddWalkInSheet extends StatefulWidget {
  const _AddWalkInSheet();

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddWalkInSheet(),
    );
  }

  @override
  State<_AddWalkInSheet> createState() => _AddWalkInSheetState();
}

class _AddWalkInSheetState extends State<_AddWalkInSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int _wait = 15;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
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
          Text('Ajouter un walk-in',
              style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            style: GoogleFonts.dmSans(color: AppColors.blanc),
            decoration: InputDecoration(
              labelText: 'Nom du client',
              labelStyle: GoogleFonts.dmSans(color: AppColors.gris),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.dmSans(color: AppColors.blanc),
            decoration: InputDecoration(
              labelText: 'Téléphone (optionnel)',
              labelStyle: GoogleFonts.dmSans(color: AppColors.gris),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Attente estimée : $_wait min',
              style: GoogleFonts.dmSans(color: AppColors.gris)),
          Slider(
            value: _wait.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            activeColor: AppColors.violet,
            onChanged: (v) => setState(() => _wait = v.round()),
          ),
          const SizedBox(height: 12),
          SpotbookButton.primary(
            label: 'Ajouter à la file',
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, {
                      'name': _name.text.trim(),
                      'phone': _phone.text.trim().isEmpty
                          ? null
                          : _phone.text.trim(),
                      'wait': _wait,
                    }),
          ),
        ],
      ),
    );
  }
}
