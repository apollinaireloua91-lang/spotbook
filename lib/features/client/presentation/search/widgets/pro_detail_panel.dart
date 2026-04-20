import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../chat/data/chat_repository.dart';
import '../data/client_search_notifier.dart';
import '../models/search_models.dart';

class ProDetailPanel extends ConsumerWidget {
  const ProDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(
      clientSearchProvider
          .select((s) => s.showDetailPanel ? s.selectedPro : null),
    );
    if (pro == null) return const SizedBox.shrink();
    return _PanelContent(pro: pro);
  }
}

class _PanelContent extends ConsumerStatefulWidget {
  const _PanelContent({required this.pro});

  final ProSearchResult pro;

  @override
  ConsumerState<_PanelContent> createState() => _PanelContentState();
}

class _PanelContentState extends ConsumerState<_PanelContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  bool _isNavigating = false;

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

  void _navigateToProfile() {
    ref.read(clientSearchProvider.notifier).closeDetailPanel();
    context.push('/pro/${widget.pro.id}');
  }

  Future<void> _openMessage() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final chatRepo = ChatRepository(supabase: supabase);
      final conv = await chatRepo.getOrCreateConversation(
        clientId: currentUser.id,
        proId: widget.pro.id,
      );
      if (!mounted) return;
      ref.read(clientSearchProvider.notifier).closeDetailPanel();
      context.push(
        '/chat/${conv.id}',
        extra: {'otherUserName': widget.pro.name},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
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
                  // ── Handle + close ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.blanc.withAlpha(51),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => ref
                              .read(clientSearchProvider.notifier)
                              .closeDetailPanel(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.gris,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Hero section — tappable avatar + name ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Circular avatar — tappable
                        GestureDetector(
                          onTap: _navigateToProfile,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  catColor,
                                  catColor.withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: pro.avatarUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: pro.avatarUrl!,
                                      fit: BoxFit.cover,
                                      width: 56,
                                      height: 56,
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          pro.name.isNotEmpty
                                              ? pro.name[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.sora(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      pro.name.isNotEmpty
                                          ? pro.name[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.sora(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name — tappable
                              GestureDetector(
                                onTap: _navigateToProfile,
                                child: Text(
                                  pro.name,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blanc,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Category + city
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '${pro.category} \u00b7 ${pro.location}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: AppColors.gris,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (pro.online) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Online',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.blanc.withAlpha(13),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.star_rounded,
                            label: 'Rating',
                            value: pro.rating > 0
                                ? pro.rating.toStringAsFixed(1)
                                : 'New',
                            color: AppColors.ratingAmber,
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.blanc.withAlpha(20),
                          ),
                          _StatItem(
                            icon: Icons.attach_money,
                            label: 'From',
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
                        child: _ServiceRow(
                          service: s,
                          proCategory: pro.category,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Action buttons ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Message — outline style with debounce
                        Expanded(
                          child: GestureDetector(
                            onTap: _isNavigating ? null : _openMessage,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: _isNavigating
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.blanc,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 16,
                                          color: AppColors.blanc,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Message',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.blanc,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Book — filled violet with glow
                        Expanded(
                          child: _GlowBookButton(
                            proId: pro.id,
                            onTap: () {
                              ref
                                  .read(clientSearchProvider.notifier)
                                  .closeDetailPanel();
                              context.push('/pro/${pro.id}');
                            },
                          ),
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
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
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
  const _ServiceRow({
    required this.service,
    required this.proCategory,
  });

  final ProService service;
  final String proCategory;

  @override
  Widget build(BuildContext context) {
    final icon = categoryIcon(proCategory);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blanc.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blanc.withAlpha(10)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.violetDarkGradientEnd,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blanc,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  service.duration,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.gris,
                  ),
                ),
              ],
            ),
          ),
          Text(
            service.price > 0 ? '${service.price.toInt()}\$' : 'Free',
            style: GoogleFonts.dmSans(
              fontSize: 14,
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
  const _GlowBookButton({
    required this.proId,
    required this.onTap,
  });

  final String proId;
  final VoidCallback onTap;

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
        onTap: widget.onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.blanc,
              ),
              const SizedBox(width: 6),
              Text(
                'Book',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blanc,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
