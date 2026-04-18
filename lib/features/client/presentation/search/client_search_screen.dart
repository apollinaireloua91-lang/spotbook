import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import 'data/client_search_notifier.dart';
import 'widgets/category_pills.dart';
import 'widgets/pro_detail_panel.dart';
import 'widgets/search_header.dart';
import 'widgets/search_list_view.dart';
import 'widgets/search_map_view.dart';

class ClientSearchScreen extends ConsumerWidget {
  const ClientSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider); // force rebuild on theme toggle
    final topPadding = MediaQuery.paddingOf(context).top;
    final state = ref.watch(clientSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const SpotbookLoadingShimmer.list();
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: AppColors.gris, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(clientSearchProvider.notifier).refresh(),
                    icon: Icon(Icons.refresh, color: AppColors.violet),
                    label: Text('Réessayer',
                        style: GoogleFonts.dmSans(color: AppColors.violet)),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // ── Main content ──
              Column(
                children: [
                  SizedBox(height: topPadding + 8),

                  // ── Header (title + toggle + search bar) ──
                  const SearchHeader(),
                  const SizedBox(height: 12),

                  // ── Category pills ──
                  const CategoryPills(),
                  const SizedBox(height: 10),

                  // ── Map or List view ──
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: state.viewMode == 'map'
                          ? const SearchMapView(key: ValueKey('map'))
                          : const SearchListView(key: ValueKey('list')),
                    ),
                  ),
                ],
              ),

              // ── Detail panel overlay (slides up over map/list) ──
              if (state.showDetailPanel && state.selectedPro != null)
                Positioned.fill(
                  child: Stack(
                    children: [
                      // Scrim
                      GestureDetector(
                        onTap: () => ref
                            .read(clientSearchProvider.notifier)
                            .closeDetailPanel(),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                      // Panel
                      const ProDetailPanel(),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
