import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/category_repository.dart';
import '../domain/quick_reply_models.dart';
import 'quick_reply_repository.dart';

/// Maximum chips shown to a **client** — matches Messenger Marketplace UX:
/// exactly 3 ready-made questions to ask the pro.
const int _clientMaxChipCount = 3;

/// Maximum chips shown to a **pro** — their own custom replies plus category
/// defaults. Higher cap because pros curate their own list and may have 5+
/// saved replies they want quick access to.
const int _proMaxChipCount = 8;

/// Hard-coded last-resort fallback questions shown to a **client** when the
/// `quick_reply_templates` table returns nothing (e.g. fresh DB where the
/// seed migration hasn't run yet, or a pro with a brand-new category that has
/// no templates).
///
/// Guarantees the bar is never empty for clients.
const List<Map<String, String>> _clientGenericFallback = [
  {
    'fr': 'Bonjour, êtes-vous disponible ?',
    'en': 'Hi, are you available?',
  },
  {
    'fr': 'Quel est votre tarif ?',
    'en': 'What’s your rate?',
  },
  {
    'fr': 'Où êtes-vous situé(e) ?',
    'en': 'Where are you based?',
  },
];

/// Resolves the pro category slug to seed templates against.
///
/// Priority:
///   1. If [proCategoryLabel] is non-null, look it up in the in-memory
///      [proCategoriesProvider] list and return its `slug`.
///   2. Else return `'autre'` (generic fallback — always seeded).
String _resolveSlug(
  List<ProCategory> categories,
  String? proCategoryLabel,
) {
  if (proCategoryLabel == null || proCategoryLabel.isEmpty) return 'autre';
  for (final c in categories) {
    if (c.label == proCategoryLabel && c.slug != null && c.slug!.isNotEmpty) {
      return c.slug!;
    }
  }
  return 'autre';
}

/// Parameters for the [quickRepliesProvider].
class QuickRepliesArgs {
  const QuickRepliesArgs({
    required this.proCategoryLabel,
    required this.audience,
    required this.languageCode,
  });

  /// Label stored in `profiles_pro.category` (e.g. "Photographe").
  /// Nullable — for clients chatting with a pro whose category we don't know,
  /// we default to the generic `'autre'` slug.
  final String? proCategoryLabel;

  /// `'pro'` when the current user is a pro, `'client'` otherwise.
  final String audience;

  /// `'fr'` or `'en'` — used to pick the localized template text.
  final String languageCode;

  @override
  bool operator ==(Object other) =>
      other is QuickRepliesArgs &&
      other.proCategoryLabel == proCategoryLabel &&
      other.audience == audience &&
      other.languageCode == languageCode;

  @override
  int get hashCode =>
      Object.hash(proCategoryLabel, audience, languageCode);
}

/// The final list of chips to display: custom replies first, then enough
/// seeded templates to reach [_maxChipCount].
///
/// Re-computes automatically when the pro's category, audience, locale, or
/// custom-reply list changes.
final quickRepliesProvider = FutureProvider.autoDispose
    .family<List<QuickReplyItem>, QuickRepliesArgs>((ref, args) async {
  final repo = ref.watch(quickReplyRepositoryProvider);
  final categoriesAsync = ref.watch(proCategoriesProvider);
  final categories = categoriesAsync.maybeWhen(
    data: (c) => c,
    orElse: () => const <ProCategory>[],
  );

  final slug = _resolveSlug(categories, args.proCategoryLabel);
  final isClient = args.audience == 'client';
  final maxCount = isClient ? _clientMaxChipCount : _proMaxChipCount;

  // Only the pro themself sees their custom replies (audience='pro' means the
  // current user IS the pro in this conversation).
  final customs = !isClient
      ? await repo.fetchMyCustomReplies()
      : const <ProQuickReply>[];

  var templates = await repo.fetchTemplates(
    categorySlug: slug,
    audience: args.audience,
  );
  // Fallback to generic bucket if this specific category has nothing seeded.
  if (templates.isEmpty && slug != 'autre') {
    templates = await repo.fetchTemplates(
      categorySlug: 'autre',
      audience: args.audience,
    );
  }

  final chips = <QuickReplyItem>[
    for (final c in customs.where((c) => c.isEnabled))
      QuickReplyItem(text: c.text, isCustom: true),
    for (final t in templates)
      QuickReplyItem(text: t.textFor(args.languageCode), isCustom: false),
  ];

  // Last-resort fallback for clients: if the DB returned nothing (e.g. seed
  // migration not applied yet), use the hardcoded generic questions so the
  // bar is never empty.
  if (isClient && chips.isEmpty) {
    for (final q in _clientGenericFallback) {
      chips.add(QuickReplyItem(
        text: q[args.languageCode] ?? q['fr']!,
        isCustom: false,
      ));
    }
  }

  // De-dupe by text while preserving order (custom wins over seeded if same).
  final seen = <String>{};
  final deduped = <QuickReplyItem>[];
  for (final item in chips) {
    if (seen.add(item.text.toLowerCase())) {
      deduped.add(item);
      if (deduped.length >= maxCount) break;
    }
  }
  return deduped;
});

// ─── Pro-side management state (used by ProQuickRepliesScreen) ─────────────

class ProQuickRepliesState {
  const ProQuickRepliesState({
    this.items = const [],
    this.isLoading = true,
    this.error,
  });

  final List<ProQuickReply> items;
  final bool isLoading;
  final Object? error;

  ProQuickRepliesState copyWith({
    List<ProQuickReply>? items,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) =>
      ProQuickRepliesState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ProQuickRepliesNotifier extends Notifier<ProQuickRepliesState> {
  @override
  ProQuickRepliesState build() {
    _load();
    return const ProQuickRepliesState();
  }

  Future<void> _load() async {
    try {
      final items =
          await ref.read(quickReplyRepositoryProvider).fetchMyCustomReplies();
      state = state.copyWith(items: items, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Future<void> add(String text) async {
    final created =
        await ref.read(quickReplyRepositoryProvider).createCustomReply(text);
    state = state.copyWith(items: [...state.items, created]);
    _invalidateChatBar();
  }

  Future<void> edit(String id, String newText) async {
    final updated = await ref
        .read(quickReplyRepositoryProvider)
        .updateCustomReply(id: id, text: newText);
    state = state.copyWith(
      items: state.items.map((e) => e.id == id ? updated : e).toList(),
    );
    _invalidateChatBar();
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final updated = await ref
        .read(quickReplyRepositoryProvider)
        .updateCustomReply(id: id, isEnabled: enabled);
    state = state.copyWith(
      items: state.items.map((e) => e.id == id ? updated : e).toList(),
    );
    _invalidateChatBar();
  }

  Future<void> remove(String id) async {
    await ref.read(quickReplyRepositoryProvider).deleteCustomReply(id);
    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
    );
    _invalidateChatBar();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final list = [...state.items];
    // Flutter's ReorderableListView passes newIndex shifted when moving down.
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = list.removeAt(oldIndex);
    list.insert(adjusted, moved);

    // Optimistic UI update.
    state = state.copyWith(items: list);

    try {
      await ref
          .read(quickReplyRepositoryProvider)
          .reorderCustomReplies(list.map((e) => e.id).toList());
      _invalidateChatBar();
    } catch (e) {
      // Rollback on failure.
      await _load();
      rethrow;
    }
  }

  /// Forces the chat-side [quickRepliesProvider] to re-fetch after custom
  /// replies change. Safe to call even if nothing is currently listening.
  void _invalidateChatBar() {
    ref.invalidate(quickRepliesProvider);
  }
}

final proQuickRepliesProvider =
    NotifierProvider<ProQuickRepliesNotifier, ProQuickRepliesState>(
  ProQuickRepliesNotifier.new,
  isAutoDispose: true,
);

// ─── Helper : resolve conversation meta for quick-reply seeding ────────────

/// Compact view of what the quick-reply bar needs to know about a conversation.
class ConversationQuickReplyMeta {
  const ConversationQuickReplyMeta({
    required this.proId,
    required this.proCategoryLabel,
  });

  final String proId;

  /// Label stored in `profiles_pro.category` (e.g. "Photographe"),
  /// or null if the pro has no category set yet.
  final String? proCategoryLabel;
}

/// Fetches both the conversation's pro id and pro category label in a single
/// round-trip. Used by [QuickReplyBar] to determine audience (the current user
/// is "pro" iff their uid == proId) and to pick the seeded-template slug.
///
/// Cached per conversation id (auto-disposes when nobody listens).
final conversationQuickReplyMetaProvider = FutureProvider.autoDispose
    .family<ConversationQuickReplyMeta?, String>((ref, conversationId) async {
  final supabase = Supabase.instance.client;
  final data = await supabase
      .from('conversations')
      .select('pro_id, profiles_pro:pro_id(category)')
      .eq('id', conversationId)
      .maybeSingle();
  if (data == null) return null;
  final proId = data['pro_id'] as String?;
  if (proId == null) return null;
  final pro = data['profiles_pro'] as Map<String, dynamic>?;
  return ConversationQuickReplyMeta(
    proId: proId,
    proCategoryLabel: pro?['category'] as String?,
  );
});
