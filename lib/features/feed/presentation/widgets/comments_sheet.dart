import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/comments_notifier.dart';
import '../../domain/video_model.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.videoId});
  final String videoId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(commentsProvider, (_, __) {});
    Future.microtask(
      () => ref.read(commentsProvider.notifier).loadComments(widget.videoId),
    );
  }

  @override
  void dispose() {
    ref.read(commentsProvider.notifier).clear();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _textCtrl.text.trim();
    if (content.isEmpty) return;
    _textCtrl.clear();
    await ref.read(commentsProvider.notifier).addComment(widget.videoId, content);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(commentsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gris, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Comments (${s.comments.length})', style: const TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8), const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: s.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blanc))
                  : s.comments.isEmpty
                      ? const Center(child: Text('Aucun commentaire pour le moment', style: TextStyle(color: AppColors.gris, fontSize: 14)))
                      : ListView.builder(controller: scrollController, reverse: true, itemCount: s.comments.length,
                          itemBuilder: (context, index) => _CommentTile(comment: s.comments[s.comments.length - 1 - index])),
            ),
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: EdgeInsets.only(left: 16, right: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8, top: 8),
              child: Row(children: [
                Expanded(child: TextField(controller: _textCtrl, style: const TextStyle(color: AppColors.blanc, fontSize: 14),
                  decoration: InputDecoration(hintText: 'Ajouter un commentaire...', hintStyle: const TextStyle(color: AppColors.gris), filled: true, fillColor: AppColors.surfaceAlt, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
                IconButton(onPressed: _sendComment, icon: const Icon(Icons.send, color: AppColors.accent, size: 22)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: AppColors.surfaceAlt,
          backgroundImage: comment.userAvatarUrl != null ? CachedNetworkImageProvider(comment.userAvatarUrl!) : null,
          child: comment.userAvatarUrl == null ? const Icon(Icons.person, size: 16, color: AppColors.gris) : null),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(comment.userName ?? 'User', style: const TextStyle(color: AppColors.blanc, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(comment.content, style: const TextStyle(color: AppColors.grisClair, fontSize: 13)),
        ])),
      ]),
    );
  }
}
