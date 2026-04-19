// Consolidated domain models for Squire feature-parity priorities #2-#13.
// Grouped by feature for clarity.

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// #2 — Availability enhancements
// ══════════════════════════════════════════════════════════════════════════

/// An exception day (vacation, special hours, closed) for a pro's schedule.
@immutable
class AvailabilityException {
  const AvailabilityException({
    required this.id,
    required this.proId,
    required this.exceptionDate,
    this.isClosed = false,
    this.customStart,
    this.customEnd,
    this.note,
  });

  final String id;
  final String proId;
  final DateTime exceptionDate;
  final bool isClosed;
  final String? customStart;
  final String? customEnd;
  final String? note;

  factory AvailabilityException.fromJson(Map<String, dynamic> json) =>
      AvailabilityException(
        id: json['id'] as String,
        proId: json['pro_id'] as String,
        exceptionDate: DateTime.parse(json['exception_date'] as String),
        isClosed: json['is_closed'] as bool? ?? false,
        customStart: json['custom_start'] as String?,
        customEnd: json['custom_end'] as String?,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'pro_id': proId,
        'exception_date': exceptionDate.toIso8601String().split('T')[0],
        'is_closed': isClosed,
        'custom_start': customStart,
        'custom_end': customEnd,
        'note': note,
      };
}

// ══════════════════════════════════════════════════════════════════════════
// #3 — Tipping
// ══════════════════════════════════════════════════════════════════════════

enum TipStatus { pending, succeeded, failed, refunded }

@immutable
class Tip {
  const Tip({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.proId,
    required this.amountCents,
    this.currency = 'CAD',
    this.status = TipStatus.pending,
    this.stripePaymentIntentId,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String bookingId;
  final String clientId;
  final String proId;
  final int amountCents;
  final String currency;
  final TipStatus status;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime? completedAt;

  double get amountDollars => amountCents / 100.0;

  factory Tip.fromJson(Map<String, dynamic> json) {
    TipStatus parseStatus(String v) => TipStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => TipStatus.pending,
        );
    return Tip(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      amountCents: json['amount_cents'] as int,
      currency: json['currency'] as String? ?? 'CAD',
      status: parseStatus(json['status'] as String? ?? 'pending'),
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// #5 — Waitlist
// ══════════════════════════════════════════════════════════════════════════

enum WaitlistStatus { waiting, notified, booked, expired, cancelled }

@immutable
class BookingWaitlistEntry {
  const BookingWaitlistEntry({
    required this.id,
    required this.clientId,
    required this.proId,
    this.serviceId,
    required this.preferredDate,
    this.preferredTimeStart,
    this.preferredTimeEnd,
    this.status = WaitlistStatus.waiting,
    this.notifiedAt,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String proId;
  final String? serviceId;
  final DateTime preferredDate;
  final String? preferredTimeStart;
  final String? preferredTimeEnd;
  final WaitlistStatus status;
  final DateTime? notifiedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory BookingWaitlistEntry.fromJson(Map<String, dynamic> json) {
    WaitlistStatus s(String v) => WaitlistStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => WaitlistStatus.waiting,
        );
    return BookingWaitlistEntry(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      serviceId: json['service_id'] as String?,
      preferredDate: DateTime.parse(json['preferred_date'] as String),
      preferredTimeStart: json['preferred_time_start'] as String?,
      preferredTimeEnd: json['preferred_time_end'] as String?,
      status: s(json['status'] as String? ?? 'waiting'),
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// #6 — Walk-in queue
// ══════════════════════════════════════════════════════════════════════════

enum WalkInStatus { waiting, inService, completed, noShow, cancelled }

@immutable
class WalkInEntry {
  const WalkInEntry({
    required this.id,
    required this.proId,
    required this.clientName,
    this.clientPhone,
    this.clientId,
    this.serviceId,
    required this.position,
    this.status = WalkInStatus.waiting,
    this.estimatedWaitMinutes,
    required this.checkedInAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String proId;
  final String clientName;
  final String? clientPhone;
  final String? clientId;
  final String? serviceId;
  final int position;
  final WalkInStatus status;
  final int? estimatedWaitMinutes;
  final DateTime checkedInAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory WalkInEntry.fromJson(Map<String, dynamic> json) {
    WalkInStatus s(String v) => WalkInStatus.values.firstWhere(
          (e) =>
              e.name == v ||
              (e == WalkInStatus.inService && v == 'in_service') ||
              (e == WalkInStatus.noShow && v == 'no_show'),
          orElse: () => WalkInStatus.waiting,
        );
    return WalkInEntry(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      clientName: json['client_name'] as String,
      clientPhone: json['client_phone'] as String?,
      clientId: json['client_id'] as String?,
      serviceId: json['service_id'] as String?,
      position: json['position'] as int,
      status: s(json['status'] as String? ?? 'waiting'),
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int?,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// #7 — Recurring bookings
// ══════════════════════════════════════════════════════════════════════════

@immutable
class RecurringBooking {
  const RecurringBooking({
    required this.id,
    required this.clientId,
    required this.proId,
    required this.serviceId,
    required this.dayOfWeek,
    required this.startTime,
    this.frequencyWeeks = 2,
    this.isActive = true,
    required this.nextBookingDate,
    this.lastGeneratedBookingId,
    required this.createdAt,
    this.cancelledAt,
  });

  final String id;
  final String clientId;
  final String proId;
  final String serviceId;
  final int dayOfWeek;
  final String startTime;
  final int frequencyWeeks;
  final bool isActive;
  final DateTime nextBookingDate;
  final String? lastGeneratedBookingId;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  factory RecurringBooking.fromJson(Map<String, dynamic> json) =>
      RecurringBooking(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        proId: json['pro_id'] as String,
        serviceId: json['service_id'] as String,
        dayOfWeek: json['day_of_week'] as int,
        startTime: json['start_time'] as String,
        frequencyWeeks: json['frequency_weeks'] as int? ?? 2,
        isActive: json['is_active'] as bool? ?? true,
        nextBookingDate:
            DateTime.parse(json['next_booking_date'] as String),
        lastGeneratedBookingId:
            json['last_generated_booking_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        cancelledAt: json['cancelled_at'] != null
            ? DateTime.parse(json['cancelled_at'] as String)
            : null,
      );
}

// ══════════════════════════════════════════════════════════════════════════
// #8 — Client notes (CRM)
// ══════════════════════════════════════════════════════════════════════════

@immutable
class ClientNote {
  const ClientNote({
    required this.id,
    required this.proId,
    required this.clientId,
    required this.note,
    this.tags = const [],
    this.isPrivate = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String proId;
  final String clientId;
  final String note;
  final List<String> tags;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ClientNote.fromJson(Map<String, dynamic> json) => ClientNote(
        id: json['id'] as String,
        proId: json['pro_id'] as String,
        clientId: json['client_id'] as String,
        note: json['note'] as String,
        tags: ((json['tags'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        isPrivate: json['is_private'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toUpsertJson() => {
        'pro_id': proId,
        'client_id': clientId,
        'note': note,
        'tags': tags,
        'is_private': isPrivate,
      };
}

// ══════════════════════════════════════════════════════════════════════════
// #9 — Loyalty
// ══════════════════════════════════════════════════════════════════════════

@immutable
class LoyaltyProgram {
  const LoyaltyProgram({
    required this.proId,
    this.name = 'Programme fidélité',
    this.pointsPerDollar = 1,
    this.pointsForFreeService = 100,
    this.isActive = true,
  });

  final String proId;
  final String name;
  final int pointsPerDollar;
  final int pointsForFreeService;
  final bool isActive;

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) => LoyaltyProgram(
        proId: json['pro_id'] as String,
        name: json['name'] as String? ?? 'Programme fidélité',
        pointsPerDollar: json['points_per_dollar'] as int? ?? 1,
        pointsForFreeService: json['points_for_free_service'] as int? ?? 100,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toUpsertJson() => {
        'pro_id': proId,
        'name': name,
        'points_per_dollar': pointsPerDollar,
        'points_for_free_service': pointsForFreeService,
        'is_active': isActive,
      };

  LoyaltyProgram copyWith({
    String? name,
    int? pointsPerDollar,
    int? pointsForFreeService,
    bool? isActive,
  }) =>
      LoyaltyProgram(
        proId: proId,
        name: name ?? this.name,
        pointsPerDollar: pointsPerDollar ?? this.pointsPerDollar,
        pointsForFreeService:
            pointsForFreeService ?? this.pointsForFreeService,
        isActive: isActive ?? this.isActive,
      );
}

enum LoyaltyLedgerType { earned, redeemed, expired, bonus, adjustment }

@immutable
class LoyaltyLedgerEntry {
  const LoyaltyLedgerEntry({
    required this.id,
    required this.clientId,
    required this.proId,
    this.bookingId,
    required this.points,
    required this.type,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String proId;
  final String? bookingId;
  final int points;
  final LoyaltyLedgerType type;
  final String? description;
  final DateTime createdAt;

  factory LoyaltyLedgerEntry.fromJson(Map<String, dynamic> json) {
    LoyaltyLedgerType t(String v) => LoyaltyLedgerType.values.firstWhere(
          (e) => e.name == v,
          orElse: () => LoyaltyLedgerType.adjustment,
        );
    return LoyaltyLedgerEntry(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      bookingId: json['booking_id'] as String?,
      points: json['points'] as int,
      type: t(json['type'] as String),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// #10 — Referrals
// ══════════════════════════════════════════════════════════════════════════

enum ReferralStatus { pending, completed, expired, revoked }

@immutable
class UserReferral {
  const UserReferral({
    required this.id,
    required this.referrerId,
    this.referredId,
    required this.referralCode,
    this.rewardCents = 1000,
    this.currency = 'CAD',
    this.status = ReferralStatus.pending,
    this.completedAt,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String referrerId;
  final String? referredId;
  final String referralCode;
  final int rewardCents;
  final String currency;
  final ReferralStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  double get rewardDollars => rewardCents / 100.0;

  factory UserReferral.fromJson(Map<String, dynamic> json) {
    ReferralStatus s(String v) => ReferralStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => ReferralStatus.pending,
        );
    return UserReferral(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      referredId: json['referred_id'] as String?,
      referralCode: json['referral_code'] as String,
      rewardCents: json['reward_cents'] as int? ?? 1000,
      currency: json['currency'] as String? ?? 'CAD',
      status: s(json['status'] as String? ?? 'pending'),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// #12 — Digital receipts
// ══════════════════════════════════════════════════════════════════════════

@immutable
class DigitalReceipt {
  const DigitalReceipt({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.proId,
    required this.receiptNumber,
    required this.subtotalCents,
    this.addonsCents = 0,
    this.promoDiscountCents = 0,
    this.loyaltyDiscountCents = 0,
    this.tipCents = 0,
    this.taxCents = 0,
    required this.totalCents,
    this.currency = 'CAD',
    this.paymentMethod,
    this.lineItems = const [],
    required this.generatedAt,
    this.emailedAt,
  });

  final String id;
  final String bookingId;
  final String clientId;
  final String proId;
  final String receiptNumber;
  final int subtotalCents;
  final int addonsCents;
  final int promoDiscountCents;
  final int loyaltyDiscountCents;
  final int tipCents;
  final int taxCents;
  final int totalCents;
  final String currency;
  final String? paymentMethod;
  final List<Map<String, dynamic>> lineItems;
  final DateTime generatedAt;
  final DateTime? emailedAt;

  double get totalDollars => totalCents / 100.0;
  double get tipDollars => tipCents / 100.0;

  factory DigitalReceipt.fromJson(Map<String, dynamic> json) => DigitalReceipt(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        clientId: json['client_id'] as String,
        proId: json['pro_id'] as String,
        receiptNumber: json['receipt_number'] as String,
        subtotalCents: json['subtotal_cents'] as int,
        addonsCents: json['addons_cents'] as int? ?? 0,
        promoDiscountCents: json['promo_discount_cents'] as int? ?? 0,
        loyaltyDiscountCents: json['loyalty_discount_cents'] as int? ?? 0,
        tipCents: json['tip_cents'] as int? ?? 0,
        taxCents: json['tax_cents'] as int? ?? 0,
        totalCents: json['total_cents'] as int,
        currency: json['currency'] as String? ?? 'CAD',
        paymentMethod: json['payment_method'] as String?,
        lineItems: ((json['line_items'] as List?) ?? [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
        generatedAt: DateTime.parse(json['generated_at'] as String),
        emailedAt: json['emailed_at'] != null
            ? DateTime.parse(json['emailed_at'] as String)
            : null,
      );
}

// ══════════════════════════════════════════════════════════════════════════
// #13 — Enhanced review (multi-criteria)
// ══════════════════════════════════════════════════════════════════════════

@immutable
class ReviewCriteria {
  const ReviewCriteria({
    this.overallRating,
    this.punctualityRating,
    this.qualityRating,
    this.ambianceRating,
    this.wouldRecommend,
    this.comment,
  });

  final int? overallRating;
  final int? punctualityRating;
  final int? qualityRating;
  final int? ambianceRating;
  final bool? wouldRecommend;
  final String? comment;

  Map<String, dynamic> toInsertJson() => {
        if (overallRating != null) 'rating': overallRating,
        if (punctualityRating != null) 'punctuality_rating': punctualityRating,
        if (qualityRating != null) 'quality_rating': qualityRating,
        if (ambianceRating != null) 'ambiance_rating': ambianceRating,
        if (wouldRecommend != null) 'would_recommend': wouldRecommend,
        if (comment != null && comment!.trim().isNotEmpty) 'comment': comment,
      };
}
