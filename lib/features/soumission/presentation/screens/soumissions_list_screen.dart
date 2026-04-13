import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/soumission_repository.dart';
import '../../domain/soumission_model.dart';

/// Lists all soumissions (quotes) created by the Pro.
class SoumissionsListScreen extends ConsumerWidget {
  const SoumissionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final async = ref.watch(mySoumissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mes soumissions',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.violet),
            onPressed: () => context.push('/pro/soumissions/create'),
          ),
        ],
      ),
      body: async.when(
        data: (soumissions) {
          if (soumissions.isEmpty) {
            return _EmptyState(
              onCreateTap: () => context.push('/pro/soumissions/create'),
            );
          }
          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async =>
                ref.invalidate(mySoumissionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: soumissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SoumissionCard(
                soumission: soumissions[i],
                onShare: () => _share(context, soumissions[i]),
                onTap: () {},
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.violet),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur : $e',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.gris),
            ),
          ),
        ),
      ),
    );
  }

  void _share(BuildContext context, Soumission s) {
    final url = 'https://getspotbook.app/quote/${s.shareToken}';
    SharePlus.instance.share(
      ShareParams(
        text: 'Voici votre soumission "${s.title}" — $url',
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                color: AppColors.grisInactif, size: 56),
            const SizedBox(height: 16),
            Text(
              'Aucune soumission',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez des soumissions pour vos services et partagez-les avec vos clients.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SpotbookButton.primary(
              label: 'Créer une soumission',
              onPressed: onCreateTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Soumission card
// ═══════════════════════════════════════════════════════════════════════════════

class _SoumissionCard extends StatelessWidget {
  const _SoumissionCard({
    required this.soumission,
    required this.onShare,
    required this.onTap,
  });

  final Soumission soumission;
  final VoidCallback onShare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    soumission.title,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusChip(status: soumission.status),
              ],
            ),

            if (soumission.clientName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Client : ${soumission.clientName}',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Total + date row
            Row(
              children: [
                Text(
                  soumission.displayTotal,
                  style: GoogleFonts.sora(
                    color: AppColors.violet,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (soumission.createdAt != null)
                  Text(
                    DateFormat('d MMM yyyy', 'fr_CA')
                        .format(soumission.createdAt!),
                    style: GoogleFonts.dmSans(
                      color: AppColors.grisInactif,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                if (soumission.isDraft || soumission.isSent)
                  Expanded(
                    child: SpotbookButton.outlined(
                      label: 'Partager',
                      icon: Icons.share_outlined,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onShare();
                      },
                    ),
                  ),
                if (soumission.validUntil != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    soumission.isExpired
                        ? 'Expirée'
                        : 'Valide jusqu\'au ${DateFormat('d MMM').format(soumission.validUntil!)}',
                    style: GoogleFonts.dmSans(
                      color: soumission.isExpired
                          ? AppColors.error
                          : AppColors.grisInactif,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Status chip
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'draft' => ('Brouillon', AppColors.grisInactif),
      'sent' => ('Envoyée', AppColors.warning),
      'viewed' => ('Vue', AppColors.violetClair),
      'accepted' => ('Acceptée', AppColors.violet),
      'paid' => ('Payée', AppColors.success),
      'expired' => ('Expirée', AppColors.error),
      'cancelled' => ('Annulée', AppColors.error),
      _ => (status, AppColors.gris),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
