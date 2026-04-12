class PromoCodeDetail {
  const PromoCodeDetail({
    required this.id,
    required this.code,
    required this.proId,
    required this.discountPercent,
    this.maxUses,
    this.currentUses = 0,
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String proId;
  final int discountPercent;
  final int? maxUses;
  final int currentUses;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isMaxed => maxUses != null && currentUses >= maxUses!;

  factory PromoCodeDetail.fromJson(Map<String, dynamic> json) {
    return PromoCodeDetail(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      proId: json['pro_id'] as String,
      discountPercent: json['discount_percent'] as int? ?? 0,
      maxUses: json['max_uses'] as int?,
      currentUses: json['current_uses'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReferralModel {
  const ReferralModel({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.code,
    this.creditAmount = 10,
    this.credited = false,
    required this.createdAt,
  });

  final String id;
  final String referrerId;
  final String referredId;
  final String code;
  final double creditAmount;
  final bool credited;
  final DateTime createdAt;

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      referredId: json['referred_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 10,
      credited: json['credited'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
