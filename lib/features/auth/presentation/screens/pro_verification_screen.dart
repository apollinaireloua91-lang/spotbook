import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
          SnackBar(content: const Text('Échec de l\'envoi'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submit() async {
    final s = ref.read(proVerificationProvider);
    if (s.documentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Veuillez téléverser votre pièce d\'identité'), backgroundColor: AppColors.error),
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
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
          ),
        ),
        title: Text('STEP 2 OF 2', style: GoogleFonts.dmSans(fontSize: 14, letterSpacing: 0.5)),
        centerTitle: true,
        actions: [IconButton(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Aide bientôt disponible'), backgroundColor: AppColors.surface));
        }, icon: const Icon(Icons.help_outline, size: 22))],
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Configuration Pro', style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.warning.withAlpha(26)),
            child: Text('● Vérification en cours', style: GoogleFonts.dmSans(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Text('Action requise', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12)),
        ]),
        const SizedBox(height: 32),
        Text('Numéro de téléphone (requis)', style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Numéro mobile', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13)),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(12)),
            child: Text('+1 🇺🇸', style: TextStyle(color: AppColors.blanc, fontSize: 14))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: TextStyle(color: AppColors.blanc),
            decoration: InputDecoration(hintText: 'Numéro de téléphone', hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), filled: true, fillColor: AppColors.surfaceAuth, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        ]),
        const SizedBox(height: 8),
        Text('Nous enverrons un code à 6 chiffres pour vérifier ce numéro.', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 44, child: OutlinedButton.icon(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vérification SMS bientôt disponible'), backgroundColor: AppColors.surface));
        }, icon: const Icon(Icons.sms, size: 18), label: const Text('Envoyer le code'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.blanc, side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 24), Divider(color: AppColors.border), const SizedBox(height: 24),
        Text('Pièce d\'identité (requis)', style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Veuillez téléverser une photo claire de votre pièce d\'identité officielle (permis de conduire, passeport ou carte nationale d\'identité) pour activer votre compte Pro.', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: s.isUploading ? null : _pickDocument,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withAlpha(77), width: 1.5, strokeAlign: BorderSide.strokeAlignInside)),
            child: Column(children: [
              if (s.isUploading) CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)
              else if (s.documentName != null) ...[
                Icon(Icons.check_circle, color: AppColors.accentGreen, size: 36),
                const SizedBox(height: 8),
                Text(s.documentName!, style: TextStyle(color: AppColors.blanc, fontSize: 13)),
              ] else ...[
                Icon(Icons.cloud_upload_outlined, color: AppColors.accent, size: 36),
                const SizedBox(height: 8),
                Text('Appuyez pour téléverser recto et verso', style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('SVG, PNG, JPG ou PDF (MAX. 5 Mo)', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12)),
              ],
            ])),
        ),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Votre pièce d\'identité est chiffrée et stockée en toute sécurité. Nous utilisons ces informations uniquement pour vérifier votre identité. Elles ne seront jamais partagées publiquement.', style: GoogleFonts.dmSans(color: AppColors.gris.withAlpha(204), fontSize: 12, height: 1.4))),
          ])),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: s.isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.fond, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: s.isSubmitting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fond)) : Text('Soumettre les documents', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 32),
      ]))),
    );
  }
}
