import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';

class _DeleteState {
  const _DeleteState({this.confirmed = false, this.isLoading = false});
  final bool confirmed;
  final bool isLoading;
  _DeleteState copyWith({bool? confirmed, bool? isLoading}) =>
      _DeleteState(confirmed: confirmed ?? this.confirmed, isLoading: isLoading ?? this.isLoading);
}

class _DeleteNotifier extends Notifier<_DeleteState> {
  @override
  _DeleteState build() => const _DeleteState();
  void toggleConfirm() => state = state.copyWith(confirmed: !state.confirmed);

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authRepositoryProvider).softDeleteAccount();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final _deleteProvider = NotifierProvider<_DeleteNotifier, _DeleteState>(_DeleteNotifier.new, isAutoDispose: true);

class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_deleteProvider);
    final n = ref.read(_deleteProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(backgroundColor: AppColors.fond, surfaceTintColor: Colors.transparent, elevation: 0, title: Text('Supprimer le compte', style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.warning_amber_outlined, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Cette action est irréversible', style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Votre compte sera désactivé pendant 30 jours avant la suppression définitive. Vos données seront effacées et ne pourront pas être récupérées.', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: n.toggleConfirm,
              child: Row(children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: s.confirmed ? AppColors.error : AppColors.border, width: 2), color: s.confirmed ? AppColors.error : Colors.transparent),
                  child: s.confirmed ? Icon(Icons.check, color: AppColors.blanc, size: 16) : null),
                const SizedBox(width: 12),
                Expanded(child: Text('Je confirme vouloir supprimer mon compte', style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15))),
              ]),
            ),
            const Spacer(),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: s.confirmed && !s.isLoading ? () async {
                try {
                  await n.deleteAccount();
                  if (context.mounted) context.go('/login');
                } catch (_) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Échec de la suppression'), backgroundColor: AppColors.error));
                }
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.blanc, disabledBackgroundColor: AppColors.error.withAlpha(77), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: s.isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blanc)) : Text('Supprimer définitivement', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 52, child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.blanc, side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Annuler', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
