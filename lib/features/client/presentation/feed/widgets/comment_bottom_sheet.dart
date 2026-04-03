import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/data/comments_notifier.dart';
import 'comment_bubble.dart';

class CommentBottomSheet extends ConsumerStatefulWidget {
  const CommentBottomSheet({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _likedComments = <String>{};

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
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _textCtrl.text.trim();
    if (content.isEmpty) return;
    _textCtrl.clear();
    _focusNode.unfocus();
    await ref
        .read(commentsProvider.notifier)
        .addComment(widget.videoId, content);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(commentsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.75,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.comments.length}',
                      style: TextStyle(
                        color: AppColors.gris,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: AppColors.border.withAlpha(80)),

              // Comments list
              Expanded(
                child: s.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.violet,
                          strokeWidth: 2,
                        ),
                      )
                    : s.comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppColors.gris.withAlpha(80),
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Soyez le premier à commenter',
                                  style: TextStyle(
                                    color: AppColors.gris,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: s.comments.length,
                            itemBuilder: (context, index) {
                              final comment = s.comments[index];
                              return CommentBubble(
                                comment: comment,
                                isLiked:
                                    _likedComments.contains(comment.id),
                                onLikeTap: () {
                                  setState(() {
                                    if (_likedComments.contains(comment.id)) {
                                      _likedComments.remove(comment.id);
                                    } else {
                                      _likedComments.add(comment.id);
                                    }
                                  });
                                },
                                onReplyTap: () {
                                  _focusNode.requestFocus();
                                },
                              );
                            },
                          ),
              ),

              // Input bar
              Divider(height: 1, color: AppColors.border.withAlpha(80)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  8,
                  bottomInset + 8,
                ),
                child: Row(
                  children: [
                    // My avatar placeholder
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.violet.withAlpha(60),
                      child: const Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.fond,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _textCtrl,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(
                              color: AppColors.gris.withAlpha(120),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _sendComment(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _sendComment,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.violet,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
