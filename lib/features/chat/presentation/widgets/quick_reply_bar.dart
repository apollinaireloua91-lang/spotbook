import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/locale/app_locale_notifier.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/chat_repository.dart';
import '../../data/quick_reply_notifier.dart';
import '../../domain/quick_reply_models.dart';

/// Horizontal scrollable strip of ready-to-send message chips, Messenger
/// Marketplace-style. Always visible when the input is empty.
///
/// Audience resolution:
///   * if the current user is the conversation's pro → `audience = 'pro'`
///     (seeded templates for "answering clients", plus the pro's own custom
///     replies);
///   * otherwise → `audience = 'client'` (seeded templates for "asking a pro
///     about X", keyed on the pro's category).
///
/// Resilience: the bar NEVER renders empty. If any upstream fetch fails
/// (network, RLS, missing conversation row, empty DB seed), a hardcoded
/// fallback of 3 generic questions keeps the UX functional.
class QuickReplyBar extends ConsumerWidget {
  const QuickReplyBar({
    super.key,
    required this.conversationId,
    required this.controller,
    required this.isInputEmpty,
  });

  final String conversationId;

  /// Shared with [ChatScreen] — tapping a chip writes into this controller.
  final TextEditingController controller;

  /// The parent screen drives visibility so we don't double-listen to the
  /// same controller; we just hide ourselves when `false`.
  final bool isInputEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isInputEmpty) return const SizedBox.shrink();

    final currentUid = ref.read(chatRepositoryProvider).currentUserId;
    final locale = ref.watch(appLocaleProvider);
    final lang = locale.languageCode;

    // Meta lookup is best-effort — errors/loading/null all collapse to
    // "unknown meta" which maps to audience='client' with no category.
    final metaAsync = ref.watch(conversationQuickReplyMetaProvider(conversationId));
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

    // Prefer the DB-backed list. Fall back to the hardcoded safety net if
    // it's still loading, errored, or returned nothing.
    final items = repliesAsync.asData?.value ?? const <QuickReplyItem>[];
    final finalItems = items.isNotEmpty
        ? items
        : _hardcodedFallback(audience: audience, languageCode: lang);

    if (finalItems.isEmpty) return const SizedBox.shrink();

    return _QuickReplyStrip(
      items: finalItems,
      onTap: _applyChip,
    );
  }

  void _applyChip(QuickReplyItem item) {
    HapticFeedback.selectionClick();
    controller.text = item.text;
    controller.selection = TextSelection.collapsed(offset: item.text.length);
  }

  /// Ultra-safe last-resort chips. Shown when every upstream source is
  /// unavailable. Pro side still gets something useful so their bar isn't
  /// empty during loading either.
  static List<QuickReplyItem> _hardcodedFallback({
    required String audience,
    required String languageCode,
  }) {
    final isFr = languageCode != 'en';
    if (audience == 'pro') {
      return [
        QuickReplyItem(
          text: isFr ? 'Merci pour votre message' : 'Thanks for your message',
          isCustom: false,
        ),
        QuickReplyItem(
          text: isFr ? 'Je reviens vers vous rapidement' : 'I’ll get back to you shortly',
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

class _QuickReplyStrip extends StatelessWidget {
  const _QuickReplyStrip({
    required this.items,
    required this.onTap,
  });

  final List<QuickReplyItem> items;
  final ValueChanged<QuickReplyItem> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: l.quickReplyBarLabel,
      container: true,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.fond,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _QuickReplyChip(
            item: items[i],
            onTap: () => onTap(items[i]),
          ),
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({
    required this.item,
    required this.onTap,
  });

  final QuickReplyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isCustom
                ? AppColors.violet.withValues(alpha: 0.5)
                : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          item.text,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
