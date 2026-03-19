import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/pro_verification_notifier.dart';

class ProVerificationScreen extends ConsumerStatefulWidget {
  const ProVerificationScreen({super.key});

  @override
  ConsumerState<ProVerificationScreen> createState() => _ProVerificationScreenState();
}

class _ProVerificationScreenState extends ConsumerState<ProVerificationScreen> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      await ref.read(proVerificationProvider.notifier).pickAndUploadDocument();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submit() async {
    final s = ref.read(proVerificationProvider);
    if (s.documentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your ID document'), backgroundColor: AppColors.error),
      );
      return;
    }
    try {
      await ref.read(proVerificationProvider.notifier).submit(_phoneCtrl.text.trim());
      if (!mounted) return;
      context.go('/pro/stripe-connect');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(proVerificationProvider);

    return Scaffold(
      backgroundColor: AppColors.fondDark,
      appBar: AppBar(
        backgroundColor: AppColors.fondDark,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios, size: 20)),
        title: const Text('STEP 2 OF 2', style: TextStyle(fontSize: 14, letterSpacing: 0.5)),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline, size: 22))],
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('Provider Setup', style: TextStyle(color: AppColors.blanc, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.warning.withAlpha(26)),
            child: const Text('● Pending Verification', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          const Text('Action Required', style: TextStyle(color: AppColors.gris, fontSize: 12)),
        ]),
        const SizedBox(height: 32),
        const Text('Phone Number (Required)', style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Mobile Number', style: TextStyle(color: AppColors.gris, fontSize: 13)),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(12)),
            child: const Text('+1 🇺🇸', style: TextStyle(color: AppColors.blanc, fontSize: 14))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppColors.blanc),
            decoration: InputDecoration(hintText: 'Phone number', hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), filled: true, fillColor: AppColors.surfaceAuth, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        ]),
        const SizedBox(height: 8),
        const Text("We'll send a 6-digit code to verify this number.", style: TextStyle(color: AppColors.gris, fontSize: 12)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 44, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.sms, size: 18), label: const Text('Send Verification Code'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.blanc, side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 24), const Divider(color: AppColors.border), const SizedBox(height: 24),
        const Text('Identity Document (Required)', style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Please upload a clear photo of your government-issued ID (Driver\'s License, Passport, or National ID) to activate your provider account.', style: TextStyle(color: AppColors.gris, fontSize: 13)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: s.isUploading ? null : _pickDocument,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withAlpha(77), width: 1.5, strokeAlign: BorderSide.strokeAlignInside)),
            child: Column(children: [
              if (s.isUploading) const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)
              else if (s.documentName != null) ...[
                const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 36),
                const SizedBox(height: 8),
                Text(s.documentName!, style: const TextStyle(color: AppColors.blanc, fontSize: 13)),
              ] else ...[
                const Icon(Icons.cloud_upload_outlined, color: AppColors.accent, size: 36),
                const SizedBox(height: 8),
                const Text('Tap to upload Front & Back', style: TextStyle(color: AppColors.blanc, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('SVG, PNG, JPG or PDF (MAX. 5MB)', style: TextStyle(color: AppColors.gris, fontSize: 12)),
              ],
            ])),
        ),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lock, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Your ID is encrypted and securely stored. We only use this information to verify your identity. It will never be shared publicly.', style: TextStyle(color: AppColors.gris.withAlpha(204), fontSize: 12, height: 1.4))),
          ])),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: s.isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.fondDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: s.isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fondDark)) : const Text('Submit Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 32),
      ]))),
    );
  }
}
