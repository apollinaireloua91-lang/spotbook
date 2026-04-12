import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import 'cubit/client_search_cubit.dart';
import 'widgets/category_pills.dart';
import 'widgets/pro_detail_panel.dart';
import 'widgets/search_header.dart';
import 'widgets/search_list_view.dart';
import 'widgets/search_map_view.dart';

class ClientSearchScreen extends StatelessWidget {
  const ClientSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientSearchCubit(),
      child: const _ClientSearchBody(),
    );
  }
}

class _ClientSearchBody extends StatelessWidget {
  const _ClientSearchBody();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: BlocBuilder<ClientSearchCubit, ClientSearchState>(
        builder: (context, state) {
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
                    onPressed: () => context.read<ClientSearchCubit>().refresh(),
                    icon: Icon(Icons.refresh, color: AppColors.violet),
                    label: Text('Réessayer', style: GoogleFonts.dmSans(color: AppColors.violet)),
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
                        onTap: () => context
                            .read<ClientSearchCubit>()
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
