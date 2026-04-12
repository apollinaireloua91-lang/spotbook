import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/spotbook_colors.dart';

/// Badge pill avec gradient de catégorie Pro.
///
/// ```dart
/// CategoryBadge(category: 'barbier')
/// CategoryBadge(category: 'coach', fontSize: 11)
/// ```
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 9,
    this.padding,
  });

  final String category;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  /// Libellé lisible pour chaque catégorie.
  static const Map<String, String> _labels = {
    'barbier': 'Barbier',
    'nail_art': 'Nail Art',
    'coach': 'Coach',
    'photo': 'Photo',
    'tatoueur': 'Tatoueur',
    'esthetique': 'Esthétique',
    'traiteur': 'Traiteur',
    'dj': 'DJ',
  };

  @override
  Widget build(BuildContext context) {
    final gradient = SpotbookColors.gradientForCategory(category);
    final label = _labels[category.toLowerCase()] ?? category;

    return Container(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: fontSize, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: SpotbookColors.white,
          height: 1.2,
        ),
      ),
    );
  }
}
