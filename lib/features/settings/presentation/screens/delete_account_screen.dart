import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
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
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(_deleteProvider);
    final n = ref.read(_deleteProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(backgroundColor: AppColors.fond, surfaceTintColor: Colors.transparent, elevation: 0, title: Text(l.deleteAccount, style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error.withAlpha(15),
                          AppColors.error.withAlpha(5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withAlpha(40)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withAlpha(10),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.error.withAlpha(30),
                                AppColors.error.withAlpha(12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withAlpha(25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(l.deleteAccountIrreversible, style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(l.deleteAccountDescription, style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15, height: 1.5), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: n.toggleConfirm,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: s.confirmed ? AppColors.error.withAlpha(12) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: s.confirmed ? AppColors.error.withAlpha(60) : AppColors.border,
                        ),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: s.confirmed ? AppColors.error : AppColors.border, width: 2),
                            color: s.confirmed ? AppColors.error : Colors.transparent,
                          ),
                          child: s.confirmed ? Icon(Icons.check, color: AppColors.blanc, size: 16) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l.deleteAccountConfirmCheckbox, style: GoogleFonts.dmSans(color: s.confirmed ? AppColors.error : AppColors.blanc, fontSize: 15, fontWeight: s.confirmed ? FontWeight.w600 : FontWeight.normal))),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                    onPressed: s.confirmed && !s.isLoading ? () async {
                      try {
                        await n.deleteAccount();
                        if (context.mounted) context.go('/login');
                      } catch (_) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.deleteAccountFailed), backgroundColor: AppColors.error));
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.blanc, disabledBackgroundColor: AppColors.error.withAlpha(77), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: s.isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blanc)) : Text(l.deleteAccountPermanently, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 52, child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.blanc, side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(l.cancel, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
