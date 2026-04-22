import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/locale/app_locale_notifier.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/chat_notifier.dart';
import '../../data/chat_repository.dart';
import '../../data/quick_reply_notifier.dart';
import '../../domain/chat_models.dart';
import '../../domain/quick_reply_models.dart';
import '../widgets/quick_reply_bar.dart';

/// Curated set of emojis shown in the Messenger-style inline picker.
/// Kept deliberately small (60 items) so the sheet stays fast and
/// avoids the weight of a dedicated dependency.
const List<String> _kChatEmojis = [
  '😀','😁','😂','🤣','😊','😇','🙂','😍','🥰','😘',
  '😎','🤩','🤗','🤔','😌','😴','😢','😭','😡','🤯',
  '🎉','🎊','✨','🔥','💯','❤️','💕','💖','💜','💙',
  '👍','👎','👏','🙏','💪','🤝','✊','👋','🤙','🫶',
  '🙌','🫡','💰','💵','💸','💎','⭐','🌟','☀️','🌙',
  '📅','⏰','📍','📞','💬','📸','🎵','🎶','🎨','🎭',
];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUserName,
    this.otherUserAvatar,
  });
  final String conversationId;
  final String? otherUserName;
  final String? otherUserAvatar;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();

  /// Drives the composer's send button state + empty-state vs. quick-reply
  /// bar visibility. Mirrors Messenger Marketplace: bar hides the moment
  /// the user starts typing.
  bool _isInputEmpty = true;

  /// When true, the emoji panel replaces the keyboard below the composer.
  bool _showEmojiPanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadMessages(widget.conversationId);
    });
    _msgCtrl.addListener(_onTyping);
    // Closing the emoji panel the moment the user requests the keyboard
    // keeps the two input modes from stacking.
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus && _showEmojiPanel) {
        setState(() => _showEmojiPanel = false);
      }
    });
  }

  void _onTyping() {
    final nowEmpty = _msgCtrl.text.isEmpty;
    if (nowEmpty != _isInputEmpty) {
      setState(() => _isInputEmpty = nowEmpty);
    }
    if (!nowEmpty) {
      ref.read(chatProvider.notifier).sendTypingIndicator();
    }
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_onTyping);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
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
    HapticFeedback.selectionClick();
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final repo = ref.read(chatRepositoryProvider);
    final url = await repo.uploadChatImage(widget.conversationId, bytes);
    await ref.read(chatProvider.notifier).sendImage(url);
  }

  void _toggleEmojiPanel() {
    HapticFeedback.selectionClick();
    // Hide the keyboard before showing the panel so they don't fight over
    // the viewport. Delayed show gives the keyboard time to animate down.
    if (_showEmojiPanel) {
      setState(() => _showEmojiPanel = false);
      _inputFocus.requestFocus();
    } else {
      _inputFocus.unfocus();
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _showEmojiPanel = true);
      });
    }
  }

  void _insertEmoji(String emoji) {
    HapticFeedback.selectionClick();
    final sel = _msgCtrl.selection;
    final text = _msgCtrl.text;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _msgCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _applyQuickReply(QuickReplyItem item) {
    HapticFeedback.selectionClick();
    _msgCtrl.text = item.text;
    _msgCtrl.selection = TextSelection.collapsed(offset: item.text.length);
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final state = ref.watch(chatProvider);
    final currentUid = ref.read(chatRepositoryProvider).currentUserId;
    final l = AppLocalizations.of(context)!;

    final hasMessages = state.messages.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.fond,
      resizeToAvoidBottomInset: true,
      appBar: _ChatAppBar(
        otherUserName: widget.otherUserName ?? l.chatTitle,
        otherUserAvatar: widget.otherUserAvatar,
        isTyping: state.isOtherTyping,
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? _buildShimmer()
                : hasMessages
                    ? _buildMessageList(state.messages, currentUid)
                    : _ChatEmptyState(
                        conversationId: widget.conversationId,
                        otherUserName: widget.otherUserName,
                        otherUserAvatar: widget.otherUserAvatar,
                        onTapQuickReply: _applyQuickReply,
                      ),
          ),
          // Only show the bottom quick-reply strip when there are already
          // messages. In empty state the suggestions live in the middle of
          // the screen as a proper welcome experience.
          if (hasMessages)
            QuickReplyBar(
              conversationId: widget.conversationId,
              controller: _msgCtrl,
              isInputEmpty: _isInputEmpty,
            ),
          _PremiumInputBar(
            controller: _msgCtrl,
            focusNode: _inputFocus,
            isInputEmpty: _isInputEmpty,
            emojiPanelVisible: _showEmojiPanel,
            onSend: _sendMessage,
            onPickImage: _pickImage,
            onToggleEmoji: _toggleEmojiPanel,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _showEmojiPanel
                ? _EmojiPanel(onPick: _insertEmoji)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> messages, String? currentUid) {
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderId == currentUid;
        final showTime = index == messages.length - 1 ||
            messages[index + 1]
                    .createdAt
                    .difference(msg.createdAt)
                    .inMinutes
                    .abs() >
                5;
        // Tail is shown on the last bubble of a streak (same sender, <2 min).
        final isLastInGroup = index == 0 ||
            messages[index - 1].senderId != msg.senderId ||
            messages[index - 1]
                    .createdAt
                    .difference(msg.createdAt)
                    .inMinutes
                    .abs() >
                2;
        return _MessageBubble(
          message: msg,
          isMe: isMe,
          showTime: showTime,
          hasTail: isLastInGroup,
          otherUserAvatar: widget.otherUserAvatar,
        );
      },
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
              margin: const EdgeInsets.symmetric(vertical: 6),
              height: 38,
              width: 130.0 + (index * 22) % 110,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// AppBar — premium, with avatar + presence dot + glass blur
// ═════════════════════════════════════════════════════════════════════════

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.isTyping,
  });

  final String otherUserName;
  final String? otherUserAvatar;
  final bool isTyping;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.fond.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 70,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _GlassIconSquare(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 10),
                  _AppBarAvatar(
                    otherUserAvatar: otherUserAvatar,
                    otherUserName: otherUserName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isTyping
                              ? Row(
                                  key: const ValueKey('typing'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _TypingDots(color: AppColors.violetClair),
                                    const SizedBox(width: 6),
                                    Text(
                                      l.typingIndicator,
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.violetClair,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Spotbook',
                                  key: const ValueKey('brand'),
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.gris,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _GlassIconSquare(
                    icon: Icons.info_outline_rounded,
                    onTap: () {
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarAvatar extends StatelessWidget {
  const _AppBarAvatar({
    required this.otherUserAvatar,
    required this.otherUserName,
  });

  final String? otherUserAvatar;
  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientAccent,
        boxShadow: AppColors.isDark
            ? [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: Container(
          color: AppColors.surface,
          child: otherUserAvatar != null && otherUserAvatar!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: otherUserAvatar!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _InitialAvatar(name: otherUserName),
                  errorWidget: (_, __, ___) =>
                      _InitialAvatar(name: otherUserName),
                )
              : _InitialAvatar(name: otherUserName),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.sora(
          color: AppColors.textOnPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Animated three-dot indicator shown beside "typing…".
/// Pure CSS-style: no external tween lib, just a looping AnimatedBuilder.
class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});
  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by a third of the cycle.
            final t = ((_c.value + i * 0.33) % 1.0);
            final scale = 0.55 + (0.45 * (1 - (t - 0.5).abs() * 2).clamp(0, 1));
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _GlassIconSquare extends StatelessWidget {
  const _GlassIconSquare({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Icon(icon, color: AppColors.blanc, size: 17),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Empty state — moved from bottom chips to centered hero + vertical cards
// ═════════════════════════════════════════════════════════════════════════

class _ChatEmptyState extends ConsumerWidget {
  const _ChatEmptyState({
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.onTapQuickReply,
  });

  final String conversationId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final ValueChanged<QuickReplyItem> onTapQuickReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final currentUid = ref.read(chatRepositoryProvider).currentUserId;
    final locale = ref.watch(appLocaleProvider);
    final lang = locale.languageCode;

    final metaAsync =
        ref.watch(conversationQuickReplyMetaProvider(conversationId));
    final meta = metaAsync.asData?.value;

    final audience =
        (meta != null && currentUid == meta.proId) ? 'pro' : 'client';
    final category = meta?.proCategoryLabel;

    final repliesAsync = ref.watch(
      quickRepliesProvider(
        QuickRepliesArgs(
          proCategoryLabel: category,
          audience: audience,
          languageCode: lang,
        ),
      ),
    );

    // DB list, or hardcoded fallback so the middle of the screen is always
    // useful (matches QuickReplyBar's resilience contract).
    final items = repliesAsync.asData?.value ?? const <QuickReplyItem>[];
    final finalItems = items.isNotEmpty
        ? items
        : _clientFallback(audience: audience, lang: lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Center(
            child: _EmptyHero(
              name: otherUserName ?? 'Spotbook',
              avatarUrl: otherUserAvatar,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              l.chatEmptyTitle,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l.chatEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ...finalItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SuggestionCard(
                item: item,
                onTap: () => onTapQuickReply(item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<QuickReplyItem> _clientFallback({
    required String audience,
    required String lang,
  }) {
    final isFr = lang != 'en';
    if (audience == 'pro') {
      return [
        QuickReplyItem(
          text: isFr ? 'Merci pour votre message' : 'Thanks for your message',
          isCustom: false,
        ),
        QuickReplyItem(
          text: isFr
              ? 'Je reviens vers vous rapidement'
              : 'I’ll get back to you shortly',
          isCustom: false,
        ),
        QuickReplyItem(
          text: isFr ? 'Voici mon tarif' : 'Here’s my rate',
          isCustom: false,
        ),
      ];
    }
    return [
      QuickReplyItem(
        text: isFr ? 'Bonjour, êtes-vous disponible ?' : 'Hi, are you available?',
        isCustom: false,
      ),
      QuickReplyItem(
        text: isFr ? 'Quel est votre tarif ?' : 'What’s your rate?',
        isCustom: false,
      ),
      QuickReplyItem(
        text: isFr ? 'Où êtes-vous situé(e) ?' : 'Where are you based?',
        isCustom: false,
      ),
    ];
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.name, required this.avatarUrl});
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientAccent,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: AppColors.isDark ? 0.45 : 0.25),
            blurRadius: 38,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Container(
          color: AppColors.surface,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _InitialAvatar(name: name),
                  errorWidget: (_, __, ___) => _InitialAvatar(name: name),
                )
              : Center(
                  child: Text(
                    name.trim().isEmpty
                        ? '?'
                        : name.trim().characters.first.toUpperCase(),
                    style: GoogleFonts.sora(
                      color: AppColors.textOnPrimary,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.item, required this.onTap});
  final QuickReplyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCustom = item.isCustom;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCustom
                  ? AppColors.violet.withValues(alpha: 0.55)
                  : AppColors.border,
              width: isCustom ? 1.0 : 0.6,
            ),
            boxShadow: AppColors.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientAccent,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.text,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.gris,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Input bar — premium, pill composer with emoji + gradient send
// ═════════════════════════════════════════════════════════════════════════

class _PremiumInputBar extends StatelessWidget {
  const _PremiumInputBar({
    required this.controller,
    required this.focusNode,
    required this.isInputEmpty,
    required this.emojiPanelVisible,
    required this.onSend,
    required this.onPickImage,
    required this.onToggleEmoji,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isInputEmpty;
  final bool emojiPanelVisible;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onToggleEmoji;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isActive = !isInputEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).viewPadding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.fond,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _RoundIconButton(
            icon: Icons.add_photo_alternate_rounded,
            onTap: onPickImage,
            tint: AppColors.violetClair,
            semanticsLabel: 'Envoyer une image',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46, maxHeight: 128),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: focusNode.hasFocus
                      ? AppColors.violet.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 6),
                  Semantics(
                    label: l.chatEmojiPickerLabel,
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        emojiPanelVisible
                            ? Icons.keyboard_rounded
                            : Icons.sentiment_satisfied_rounded,
                        color: emojiPanelVisible
                            ? AppColors.violet
                            : AppColors.gris,
                        size: 22,
                      ),
                      onPressed: onToggleEmoji,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 38, minHeight: 38),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: GoogleFonts.dmSans(
                          color: AppColors.blanc,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        keyboardAppearance:
                            AppColors.isDark ? Brightness.dark : Brightness.light,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          hintText: l.chatMessageHint,
                          hintStyle: GoogleFonts.dmSans(
                            color: AppColors.gris,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(isActive: isActive, onTap: onSend),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tint,
    required this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color tint;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Icon(icon, color: tint, size: 22),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isActive, required this.onTap});
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Envoyer',
      button: true,
      child: AnimatedScale(
        scale: isActive ? 1.0 : 0.92,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.55,
          duration: const Duration(milliseconds: 140),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: isActive ? onTap : null,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? AppColors.gradientAccent : null,
                  color: isActive ? null : AppColors.surface,
                  border: isActive
                      ? null
                      : Border.all(color: AppColors.border, width: 0.5),
                  boxShadow: isActive && AppColors.isDark
                      ? [
                          BoxShadow(
                            color:
                                AppColors.violet.withValues(alpha: 0.45),
                            blurRadius: 16,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color:
                      isActive ? AppColors.textOnPrimary : AppColors.gris,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Emoji panel — 6-column grid, lightweight & themed
// ═════════════════════════════════════════════════════════════════════════

class _EmojiPanel extends StatelessWidget {
  const _EmojiPanel({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _kChatEmojis.length,
        itemBuilder: (_, i) {
          final emoji = _kChatEmojis[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onPick(emoji),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Message bubble — premium violet gradient for "me", tail, read ticks
// ═════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showTime,
    required this.hasTail,
    required this.otherUserAvatar,
  });

  final MessageModel message;
  final bool isMe;
  final bool showTime;
  final bool hasTail;
  final String? otherUserAvatar;

  @override
  Widget build(BuildContext context) {
    final tail = const Radius.circular(6);
    final round = const Radius.circular(20);
    final bubbleRadius = BorderRadius.only(
      topLeft: round,
      topRight: round,
      bottomLeft: isMe ? round : (hasTail ? tail : round),
      bottomRight: isMe ? (hasTail ? tail : round) : round,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              SizedBox(
                width: 28,
                child: hasTail
                    ? _SmallAvatar(avatarUrl: otherUserAvatar)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                margin: const EdgeInsets.symmetric(vertical: 1.5),
                padding: message.imageUrl != null
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? AppColors.gradientAccent : null,
                  color: isMe ? null : AppColors.surface,
                  borderRadius: bubbleRadius,
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.border, width: 0.5),
                  boxShadow: isMe && AppColors.isDark
                      ? [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrl!,
                          width: 220,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.surface,
                            highlightColor: AppColors.surfaceAlt,
                            child: Container(
                              width: 220,
                              height: 160,
                              color: AppColors.surface,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 220,
                            height: 160,
                            color: AppColors.surface,
                            child: Icon(Icons.broken_image,
                                color: AppColors.gris),
                          ),
                        ),
                      ),
                    if (message.content != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: message.imageUrl != null ? 6 : 0,
                          left: message.imageUrl != null ? 4 : 0,
                          right: message.imageUrl != null ? 4 : 0,
                          bottom: message.imageUrl != null ? 4 : 0,
                        ),
                        child: Text(
                          message.content!,
                          style: GoogleFonts.dmSans(
                            color: isMe
                                ? AppColors.textOnPrimary
                                : AppColors.blanc,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (isMe && hasTail) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 13,
                            color: message.isRead
                                ? AppColors.textOnPrimary
                                : AppColors.textOnPrimary.withValues(alpha: 0.65),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.avatarUrl});
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientAccent,
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipOval(
        child: Container(
          color: AppColors.surface,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
