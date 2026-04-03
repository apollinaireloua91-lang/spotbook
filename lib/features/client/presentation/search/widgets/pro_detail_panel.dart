import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../chat/data/chat_repository.dart';
import '../cubit/client_search_cubit.dart';
import '../models/search_models.dart';

class ProDetailPanel extends StatelessWidget {
  const ProDetailPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ClientSearchCubit, ClientSearchState, ProSearchResult?>(
      selector: (state) => state.showDetailPanel ? state.selectedPro : null,
      builder: (context, pro) {
        if (pro == null) return const SizedBox.shrink();
        return _PanelContent(pro: pro);
      },
    );
  }
}

class _PanelContent extends StatefulWidget {
  const _PanelContent({required this.pro});

  final ProSearchResult pro;

  @override
  State<_PanelContent> createState() => _PanelContentState();
}

class _PanelContentState extends State<_PanelContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pro = widget.pro;
    final catColor = categoryColor(pro.category);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SlideTransition(
      position: _slideAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.75,
          snap: true,
          snapSizes: const [0.25, 0.45, 0.75],
          builder: (context, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.blanc.withAlpha(20),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.only(bottom: bottomInset + 16),
                children: [
                  const SizedBox(height: 8),
                  // ── Handle ──
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Close button ──
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => context
                            .read<ClientSearchCubit>()
                            .closeDetailPanel(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.gris,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Hero section ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [catColor, catColor.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: pro.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: CachedNetworkImage(
                                    imageUrl: pro.avatarUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    pro.name.isNotEmpty
                                        ? pro.name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.blanc,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pro.name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blanc,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${categoryEmoji(pro.category)} ${pro.category}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.gris,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (pro.online) ...[
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'En ligne',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.gris,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    pro.location,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.gris,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats row ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'Note',
                            value: '\u2B50 ${pro.rating}',
                            color: AppColors.ratingAmber,
                          ),
                          _StatItem(
                            label: 'Distance',
                            value: '${pro.distKm} km',
                            color: AppColors.violet,
                          ),
                          _StatItem(
                            label: 'Prix',
                            value: '${pro.priceRange}\$',
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Services list ──
                  if (pro.services.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Services',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blanc,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pro.services.map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: _ServiceRow(service: s),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Action buttons ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Message
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final supabase = Supabase.instance.client;
                              final currentUser = supabase.auth.currentUser;
                              if (currentUser == null) return;
                              try {
                                final chatRepo = ChatRepository(supabase: supabase);
                                final conv = await chatRepo.getOrCreateConversation(
                                  clientId: currentUser.id,
                                  proId: widget.pro.id,
                                );
                                if (!context.mounted) return;
                                context.push(
                                  '/chat/${conv.id}',
                                  extra: {'otherUserName': widget.pro.name},
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '\uD83D\uDCAC Message',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blanc,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Book — with glow pulse
                        Expanded(
                          child: _GlowBookButton(proId: pro.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Stat Item ───────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.gris,
          ),
        ),
      ],
    );
  }
}

// ─── Service Row ─────────────────────────────────────────────────────

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final ProService service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.violetDarkGradientEnd,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.spa_outlined,
              size: 16,
              color: AppColors.violetClair,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blanc,
                  ),
                ),
                Text(
                  service.duration,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.gris,
                  ),
                ),
              ],
            ),
          ),
          Text(
            service.price > 0 ? '${service.price.toInt()}\$' : 'Gratuit',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.violet,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glow Pulse Book Button ──────────────────────────────────────────

class _GlowBookButton extends StatefulWidget {
  const _GlowBookButton({required this.proId});

  final String proId;

  @override
  State<_GlowBookButton> createState() => _GlowBookButtonState();
}

class _GlowBookButtonState extends State<_GlowBookButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: _glowAnim.value),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () =>
            context.push('/client/booking-flow/${widget.proId}'),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '\uD83D\uDCC5 Réserver',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.blanc,
            ),
          ),
        ),
      ),
    );
  }
}
