import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/squire_repository.dart';
import '../../domain/squire_models.dart';

/// Priority #13 — Multi-criteria review sheet.
/// Overall + punctuality + quality + ambiance + would recommend + comment.
class EnhancedReviewSheet extends ConsumerStatefulWidget {
  const EnhancedReviewSheet({
    super.key,
    required this.bookingId,
    required this.proId,
    required this.proName,
  });

  final String bookingId;
  final String proId;
  final String proName;

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required String proId,
    required String proName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EnhancedReviewSheet(
        bookingId: bookingId,
        proId: proId,
        proName: proName,
      ),
    );
  }

  @override
  ConsumerState<EnhancedReviewSheet> createState() =>
      _EnhancedReviewSheetState();
}

class _EnhancedReviewSheetState extends ConsumerState<EnhancedReviewSheet> {
  int _overall = 0;
  int _punctuality = 0;
  int _quality = 0;
  int _ambiance = 0;
  bool? _recommend;
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_overall == 0) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      await repo.submitEnhancedReview(
        bookingId: widget.bookingId,
        proId: widget.proId,
        criteria: ReviewCriteria(
          overallRating: _overall,
          punctualityRating: _punctuality == 0 ? null : _punctuality,
          qualityRating: _quality == 0 ? null : _quality,
          ambianceRating: _ambiance == 0 ? null : _ambiance,
          wouldRecommend: _recommend,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  Widget _starRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: GoogleFonts.dmSans(
                    color: AppColors.blanc, fontSize: 14)),
          ),
          ...List.generate(5, (i) {
            final filled = i < value;
            return IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onChanged(i + 1);
              },
              icon: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                color: filled ? AppColors.starGold : AppColors.gris,
                size: 28,
              ),
              padding: const EdgeInsets.all(2),
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
            );
          }),
        ],
      ),
    );
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
      child: SingleChildScrollView(
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
            Text(
              'Évaluer ${widget.proName}',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _starRow('Global', _overall, (v) => setState(() => _overall = v)),
            _starRow('Ponctualité', _punctuality,
                (v) => setState(() => _punctuality = v)),
            _starRow(
                'Qualité', _quality, (v) => setState(() => _quality = v)),
            _starRow('Ambiance', _ambiance,
                (v) => setState(() => _ambiance = v)),
            const SizedBox(height: 8),
            Text('Le recommanderais-tu ?',
                style: GoogleFonts.dmSans(
                    color: AppColors.gris, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _recommend = true),
                    icon: Icon(Icons.thumb_up_rounded,
                        color: _recommend == true
                            ? AppColors.success
                            : AppColors.gris),
                    label: Text(
                      'Oui',
                      style: GoogleFonts.dmSans(
                        color: _recommend == true
                            ? AppColors.success
                            : AppColors.gris,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _recommend = false),
                    icon: Icon(Icons.thumb_down_rounded,
                        color: _recommend == false
                            ? AppColors.error
                            : AppColors.gris),
                    label: Text(
                      'Non',
                      style: GoogleFonts.dmSans(
                        color: _recommend == false
                            ? AppColors.error
                            : AppColors.gris,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 500,
              style: GoogleFonts.dmSans(color: AppColors.blanc),
              decoration: InputDecoration(
                labelText: 'Commentaire (optionnel)',
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
            SpotbookButton.primary(
              label: _saving ? 'Envoi...' : 'Publier l\'avis',
              onPressed: (_overall == 0 || _saving) ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
