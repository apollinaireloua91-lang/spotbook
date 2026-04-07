import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';

class ProQrCodeScreen extends StatelessWidget {
  const ProQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final uid = user?.id ?? '';
    final meta = user?.userMetadata;
    final name = meta?['full_name'] as String? ?? 'Pro';
    final username = meta?['username'] as String? ?? uid.substring(0, 8);

    // Deep-link that opens the pro's public profile in Spotbook
    final profileUrl = 'https://spotbook.app/pro/$uid';

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'My QR Code',
          style: GoogleFonts.sora(
              color: AppColors.blanc, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.blanc),
            onPressed: () =>
                SharePlus.instance.share(ShareParams(text: profileUrl)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ─── Card with QR ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    // QR code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blanc,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QrImageView(
                        data: profileUrl,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: AppColors.blanc,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.fond,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.fond,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Text(
                      name,
                      style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: GoogleFonts.dmSans(
                          color: AppColors.gris, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    // URL pill
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profileUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lien copié !'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link,
                                color: AppColors.gris, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                profileUrl,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.grisClair, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy,
                                color: AppColors.gris, size: 13),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── Info text ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.gris, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Partagez ce QR code avec vos clients pour qu\'ils accèdent directement à votre profil et réservent vos services.',
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Action buttons ──────────────────────────────────────────
              SpotbookButton.primary(
                label: 'Share my profile',
                icon: Icons.share_outlined,
                onPressed: () =>
                    SharePlus.instance.share(ShareParams(text: profileUrl)),
              ),
              const SizedBox(height: 12),
              SpotbookButton.secondary(
                label: 'Copy link',
                icon: Icons.copy_outlined,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: profileUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
