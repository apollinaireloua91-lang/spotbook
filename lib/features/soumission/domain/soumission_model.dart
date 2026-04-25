import '../../../shared/utils/currency_formatter.dart';

/// A line item within a soumission (quote).
class SoumissionLineItem {
  const SoumissionLineItem({
    required this.label,
    this.qty = 1,
    required this.unitPriceCents,
  });

  final String label;
  final int qty;
  final int unitPriceCents;

  int get totalCents => qty * unitPriceCents;

  factory SoumissionLineItem.fromJson(Map<String, dynamic> json) {
    return SoumissionLineItem(
      label: json['label'] as String? ?? '',
      qty: json['qty'] as int? ?? 1,
      unitPriceCents: json['unit_price_cents'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'qty': qty,
        'unit_price_cents': unitPriceCents,
      };
}

/// Pro-initiated service quote (soumission).
class Soumission {
  const Soumission({
    required this.id,
    required this.proId,
    this.clientId,
    required this.title,
    this.description,
    this.serviceId,
    this.lineItems = const [],
    this.subtotalCents = 0,
    this.taxCents = 0,
    this.totalCents = 0,
    this.shareToken,
    this.clientEmail,
    this.clientPhone,
    this.clientName,
    this.status = 'draft',
    this.paymentIntentId,
    this.paidAt,
    this.validUntil,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String proId;
  final String? clientId;
  final String title;
  final String? description;
  final String? serviceId;
  final List<SoumissionLineItem> lineItems;
  final int subtotalCents;
  final int taxCents;
  final int totalCents;
  final String? shareToken;
  final String? clientEmail;
  final String? clientPhone;
  final String? clientName;
  final String status;
  final String? paymentIntentId;
  final DateTime? paidAt;
  final DateTime? validUntil;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isPaid => status == 'paid';
  bool get isExpired =>
      status == 'expired' ||
      (validUntil != null && validUntil!.isBefore(DateTime.now()) && status != 'paid');

  String get displayTotal => CurrencyFormatter.formatAmount(totalCents / 100);

  factory Soumission.fromJson(Map<String, dynamic> json) {
    final rawItems = json['line_items'];
    final items = <SoumissionLineItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(SoumissionLineItem.fromJson(item));
        }
      }
    }

    return Soumission(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      clientId: json['client_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      serviceId: json['service_id'] as String?,
      lineItems: items,
      subtotalCents: json['subtotal_cents'] as int? ?? 0,
      taxCents: json['tax_cents'] as int? ?? 0,
      totalCents: json['total_cents'] as int? ?? 0,
      shareToken: json['share_token'] as String?,
      clientEmail: json['client_email'] as String?,
      clientPhone: json['client_phone'] as String?,
      clientName: json['client_name'] as String?,
      status: json['status'] as String? ?? 'draft',
      paymentIntentId: json['payment_intent_id'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
