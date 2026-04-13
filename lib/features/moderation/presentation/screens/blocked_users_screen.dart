import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/moderation_repository.dart';
import '../../domain/moderation_models.dart';

class _BlockedState {
  const _BlockedState({this.users = const [], this.isLoading = true});
  final List<BlockModel> users;
  final bool isLoading;
  _BlockedState copyWith({List<BlockModel>? users, bool? isLoading}) =>
      _BlockedState(users: users ?? this.users, isLoading: isLoading ?? this.isLoading);
}

class _BlockedNotifier extends Notifier<_BlockedState> {
  @override
  _BlockedState build() {
    _load();
    return const _BlockedState();
  }

  Future<void> _load() async {
    final repo = ref.read(moderationRepositoryProvider);
    final users = await repo.getBlockedUsers();
    state = state.copyWith(users: users, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Future<void> unblock(String blockedId) async {
    final repo = ref.read(moderationRepositoryProvider);
    await repo.unblockUser(blockedId);
    state = state.copyWith(
      users: state.users.where((u) => u.blockedId != blockedId).toList(),
    );
  }
}

final _blockedProvider = NotifierProvider<_BlockedNotifier, _BlockedState>(
  _BlockedNotifier.new,
  isAutoDispose: true,
);

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(_blockedProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.retourLabel,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(l.blockedUsersTitle,
            style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: state.isLoading
          ? Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceAlt,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: 6,
                itemBuilder: (_, __) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          : state.users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, color: AppColors.gris, size: 48),
                      const SizedBox(height: 12),
                      Text(l.blockedUsersEmpty,
                          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.blanc,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => ref.read(_blockedProvider.notifier).refresh(),
                  child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: state.users.length,
                  itemBuilder: (context, index) {
                    final block = state.users[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.surfaceAlt,
                            backgroundImage: block.blockedAvatarUrl != null
                                ? CachedNetworkImageProvider(block.blockedAvatarUrl!)
                                : null,
                            child: block.blockedAvatarUrl == null
                                ? Icon(Icons.person, color: AppColors.gris, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              block.blockedName ?? 'User',
                              style: GoogleFonts.dmSans(
                                color: AppColors.blanc,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                ref.read(_blockedProvider.notifier).unblock(block.blockedId);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text(l.blockedUsersUnblock,
                                  style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 13, fontWeight: FontWeight.w500)),
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
