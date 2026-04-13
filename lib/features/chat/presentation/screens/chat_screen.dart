import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/chat_notifier.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, this.otherUserName});
  final String conversationId;
  final String? otherUserName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadMessages(widget.conversationId);
    });
    _msgCtrl.addListener(_onTyping);
  }

  void _onTyping() {
    if (_msgCtrl.text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendTypingIndicator();
    }
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_onTyping);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    ref.read(chatProvider.notifier).dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    _msgCtrl.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final repo = ref.read(chatRepositoryProvider);
    final url = await repo.uploadChatImage(widget.conversationId, bytes);
    await ref.read(chatProvider.notifier).sendImage(url);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final state = ref.watch(chatProvider);
    final currentUid = ref.read(chatRepositoryProvider).currentUserId;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
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
        title: Column(
          children: [
            Text(
              widget.otherUserName ?? 'Chat',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (state.isOtherTyping)
              Text(
                'typing...',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? _buildShimmer()
                : ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMe = msg.senderId == currentUid;
                      final showTime = index == state.messages.length - 1 ||
                          state.messages[index + 1].createdAt.difference(msg.createdAt).inMinutes.abs() > 5;
                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showTime: showTime,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: 8,
        itemBuilder: (_, index) {
          final isMe = index % 3 != 0;
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              height: 36,
              width: 120.0 + (index * 20) % 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewPadding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Send image',
            child: IconButton(
              icon: Icon(Icons.image_outlined, color: AppColors.gris),
              onPressed: _pickImage,
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            label: 'Send',
            child: IconButton(
              icon: Icon(Icons.send, color: AppColors.blanc),
              onPressed: _sendMessage,
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showTime,
  });

  final MessageModel message;
  final bool isMe;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.blanc : AppColors.surfaceAlt,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: message.imageUrl!,
                      width: 200,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: AppColors.surface,
                        highlightColor: AppColors.surfaceAlt,
                        child: Container(width: 200, height: 150, color: AppColors.surface),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 200,
                        height: 150,
                        color: AppColors.surface,
                        child: Icon(Icons.broken_image, color: AppColors.gris),
                      ),
                    ),
                  ),
                if (message.content != null)
                  Text(
                    message.content!,
                    style: GoogleFonts.dmSans(
                      color: isMe ? AppColors.fond : AppColors.blanc,
                      fontSize: 15,
                    ),
                  ),
                if (isMe) ...[
                  const SizedBox(height: 2),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isMe
                        ? (message.isRead ? AppColors.gris : AppColors.border)
                        : AppColors.gris,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
