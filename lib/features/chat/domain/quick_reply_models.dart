/// Domain models for quick-reply chips shown above the chat input.
///
/// Two sources feed the UI:
///   * [QuickReplyTemplate] — read-only defaults seeded per pro category +
///     audience. Localized (FR/EN).
///   * [ProQuickReply]      — a pro's own custom quick replies (CRUD).
///
/// The UI merges them via [QuickReplyItem]: a normalized chip payload that
/// doesn't care about the source.
library;

/// A default, locale-aware quick-reply suggestion.
class QuickReplyTemplate {
  const QuickReplyTemplate({
    required this.id,
    required this.categorySlug,
    required this.audience,
    required this.textFr,
    required this.textEn,
    required this.sortOrder,
  });

  final String id;
  final String categorySlug;

  /// `'pro'` or `'client'` — which side of the conversation this hint is for.
  final String audience;
  final String textFr;
  final String textEn;
  final int sortOrder;

  /// Returns the localized text for the active locale. Falls back to FR.
  String textFor(String languageCode) =>
      languageCode == 'en' ? textEn : textFr;

  factory QuickReplyTemplate.fromJson(Map<String, dynamic> json) {
    return QuickReplyTemplate(
      id: json['id'] as String,
      categorySlug: json['category_slug'] as String,
      audience: json['audience'] as String,
      textFr: json['text_fr'] as String,
      textEn: json['text_en'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A custom quick reply authored by a pro (visible only to its owner).
class ProQuickReply {
  const ProQuickReply({
    required this.id,
    required this.proId,
    required this.text,
    required this.sortOrder,
    required this.isEnabled,
    required this.createdAt,
  });

  final String id;
  final String proId;
  final String text;
  final int sortOrder;
  final bool isEnabled;
  final DateTime createdAt;

  ProQuickReply copyWith({
    String? text,
    int? sortOrder,
    bool? isEnabled,
  }) =>
      ProQuickReply(
        id: id,
        proId: proId,
        text: text ?? this.text,
        sortOrder: sortOrder ?? this.sortOrder,
        isEnabled: isEnabled ?? this.isEnabled,
        createdAt: createdAt,
      );

  factory ProQuickReply.fromJson(Map<String, dynamic> json) {
    return ProQuickReply(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      text: json['text'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Unified chip payload consumed by the chat input bar.
///
/// `isCustom` lets the UI tag custom replies differently if we ever want to
/// (today they look the same — simpler UX).
class QuickReplyItem {
  const QuickReplyItem({
    required this.text,
    required this.isCustom,
  });

  final String text;
  final bool isCustom;
}
