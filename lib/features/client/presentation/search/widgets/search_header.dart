import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../cubit/client_search_cubit.dart';

class SearchHeader extends StatefulWidget {
  const SearchHeader({super.key});

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row + toggle ──
          Row(
            children: [
              Text(
                'Découvrir',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blanc,
                ),
              ),
              const Spacer(),
              const _ViewModeToggle(),
            ],
          ),
          const SizedBox(height: 12),

          // ── Search bar + filter ──
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasFocus
                          ? AppColors.violet
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.blanc,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Barbier, nail art, coach...',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.grisInactif,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.grisInactif,
                        size: 18,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                                context.read<ClientSearchCubit>().search('');
                              },
                              child: Icon(
                                Icons.close,
                                color: AppColors.gris,
                                size: 16,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      context.read<ClientSearchCubit>().search(v);
                      setState(() {}); // refresh clear icon
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ── Filter button ──
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => Container(
                      height: MediaQuery.of(ctx).size.height * 0.65,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Filtres',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blanc,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.blanc.withValues(alpha: 0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close,
                                        color: AppColors.gris, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: AppColors.border, height: 1),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                // Distance
                                Text('Distance maximale',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gris)),
                                const SizedBox(height: 8),
                                StatefulBuilder(
                                  builder: (ctx2, setLocal) {
                                    double distance = 10;
                                    return Column(
                                      children: [
                                        Slider(
                                          value: distance,
                                          min: 1,
                                          max: 50,
                                          activeColor: AppColors.violet,
                                          inactiveColor: AppColors.border,
                                          onChanged: (v) =>
                                              setLocal(() => distance = v),
                                        ),
                                        Text('${distance.round()} km',
                                            style: GoogleFonts.dmSans(
                                                color: AppColors.blanc,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Note minimum
                                Text('Note minimale',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gris)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [3.0, 3.5, 4.0, 4.5]
                                      .map((rating) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              border: Border.all(
                                                  color: AppColors.border),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text('⭐ $rating+',
                                                style: GoogleFonts.dmSans(
                                                    color:
                                                        AppColors.ratingAmber,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 20),
                                // Prix
                                Text('Gamme de prix',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gris)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: ['\$', '\$\$', '\$\$\$', '\$\$\$\$']
                                      .map((price) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              border: Border.all(
                                                  color: AppColors.border),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(price,
                                                style: GoogleFonts.dmSans(
                                                    color: AppColors.success,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 20),
                                // Disponibilité
                                Text('Disponibilité',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gris)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    'En ligne',
                                    'Dispo aujourd\'hui',
                                    'Dispo cette semaine',
                                  ]
                                      .map((label) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              border: Border.all(
                                                  color: AppColors.border),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(label,
                                                style: GoogleFonts.dmSans(
                                                    color: AppColors.blanc,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                                // Bouton appliquer
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.violet,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                    child: Text('Appliquer',
                                        style: GoogleFonts.dmSans(
                                            color: AppColors.blanc,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: AppColors.violet,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── View Mode Toggle (carte / liste) ────────────────────────────────

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ClientSearchCubit, ClientSearchState, String>(
      selector: (state) => state.viewMode,
      builder: (context, viewMode) {
        final isMap = viewMode == 'map';
        return GestureDetector(
          onTap: () => context.read<ClientSearchCubit>().toggleViewMode(),
          child: Container(
            width: 120,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // ── Animated violet slider ──
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  alignment:
                      isMap ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // ── Labels ──
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'Carte',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMap
                                ? AppColors.blanc
                                : AppColors.gris,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Liste',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMap
                                ? AppColors.gris
                                : AppColors.blanc,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
