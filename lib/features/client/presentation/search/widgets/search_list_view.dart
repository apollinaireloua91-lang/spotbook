import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../cubit/client_search_cubit.dart';
import 'event_search_card.dart';
import 'pro_list_card.dart';

class SearchListView extends StatefulWidget {
  const SearchListView({super.key});

  @override
  State<SearchListView> createState() => _SearchListViewState();
}

class _SearchListViewState extends State<SearchListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientSearchCubit, ClientSearchState>(
      builder: (context, state) {
        if (state.pros.isEmpty && state.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.grisInactif,
                ),
                const SizedBox(height: 12),
                Text(
                  'No results',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gris,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try another search or category',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.grisInactif,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          children: [
            // ── Section: Près de toi ──
            if (state.pros.isNotEmpty) ...[
              _SectionTitle(
                title: 'Near you \uD83D\uDCCD',
              ),
              const SizedBox(height: 8),
              ...List.generate(state.pros.length, (index) {
                final delay = (index * 0.08).clamp(0.0, 0.6);
                return _StaggeredItem(
                  animation: _staggerCtrl,
                  delay: delay,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ProListCard(
                      pro: state.pros[index],
                      onTap: () {
                        context
                            .read<ClientSearchCubit>()
                            .openDetailPanel(state.pros[index].id);
                      },
                    ),
                  ),
                );
              }),
            ],

            // ── Section: Événements à venir ──
            if (state.events.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'Upcoming events \uD83C\uDF89',
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return EventSearchCard(
                      event: state.events[index],
                      onTap: () => context.push(
                        '/event/${state.events[index].id}',
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.blanc,
        ),
      ),
    );
  }
}

// ─── Staggered FadeSlideUp ───────────────────────────────────────────

class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({
    required this.animation,
    required this.delay,
    required this.child,
  });

  final AnimationController animation;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
