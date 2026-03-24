import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/auth_repository.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_next.text != _confirm.text) {
      _toast(l10n.proConfirmPassword, error: true);
      return;
    }
    if (_next.text.length < 8) {
      _toast(l10n.error, error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.proSettingsSavedToast),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        _toast(e.toString(), error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: SpotbookColors.background,
      appBar: AppBar(
        backgroundColor: SpotbookColors.background,
        leading: Semantics(
          label: l10n.cancel,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: SpotbookColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          l10n.proChangePasswordTitle,
          style: const TextStyle(
            color: SpotbookColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _Field(
            label: l10n.proCurrentPassword,
            controller: _current,
            obscure: true,
          ),
          const SizedBox(height: 16),
          _Field(
            label: l10n.proNewPassword,
            controller: _next,
            obscure: true,
          ),
          const SizedBox(height: 16),
          _Field(
            label: l10n.proConfirmPassword,
            controller: _confirm,
            obscure: true,
          ),
          const SizedBox(height: 32),
          SpotbookButton.primary(
            label: l10n.save,
            isLoading: _loading,
            onPressed: _loading ? null : () => _submit(l10n),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SpotbookColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: SpotbookColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: SpotbookColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SpotbookColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SpotbookColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SpotbookColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
