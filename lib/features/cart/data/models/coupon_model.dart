class CouponModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double maxDiscount;
  final double minPurchase;
  final DateTime? startDate;
  final DateTime? endDate;
  final String applicableTo;
  final List<String> specificUsers;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.discountType = 'percentage',
    this.discountValue = 0,
    this.maxDiscount = 0,
    this.minPurchase = 0,
    this.startDate,
    this.endDate,
    this.applicableTo = 'all',
    this.specificUsers = const [],
    this.isActive = true,
  });

  bool get isPercentage => discountType.toLowerCase() == 'percentage';

  String get discountBadgeText =>
      isPercentage ? '${discountValue.toInt()}% OFF' : '৳${discountValue.toInt()} FLAT OFF';

  bool isEligibleForAmount(double subtotal) {
    if (minPurchase <= 0) return true;
    return subtotal >= minPurchase;
  }

  double calculateDiscount(double subtotal) {
    if (!isEligibleForAmount(subtotal)) return 0;
    double discount = 0;
    if (isPercentage) {
      discount = (subtotal * discountValue) / 100.0;
      if (maxDiscount > 0 && discount > maxDiscount) {
        discount = maxDiscount;
      }
    } else {
      discount = discountValue;
    }
    return discount > subtotal ? subtotal : discount;
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    List<String> parseSpecificUsers(dynamic users) {
      if (users is List) {
        return users.map((u) {
          if (u is Map<String, dynamic>) {
            return (u['_id'] ?? u['id'] ?? '').toString();
          }
          return u.toString();
        }).toList();
      }
      return [];
    }

    return CouponModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString().toUpperCase(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      discountType: (json['discountType'] ?? 'percentage').toString(),
      discountValue: (json['discountValue'] is num)
          ? (json['discountValue'] as num).toDouble()
          : double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0,
      maxDiscount: (json['maxDiscount'] is num)
          ? (json['maxDiscount'] as num).toDouble()
          : double.tryParse(json['maxDiscount']?.toString() ?? '0') ?? 0,
      minPurchase: (json['minPurchase'] is num)
          ? (json['minPurchase'] as num).toDouble()
          : double.tryParse(json['minPurchase']?.toString() ?? '0') ?? 0,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      applicableTo: (json['applicableTo'] ?? 'all').toString(),
      specificUsers: parseSpecificUsers(json['specificUsers']),
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        'name': name,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'maxDiscount': maxDiscount,
        'minPurchase': minPurchase,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'applicableTo': applicableTo,
        'isActive': isActive,
      };
}

class AppliedCouponResult {
  final String code;
  final double discountAmount;
  final String? discountType;
  final String? message;

  const AppliedCouponResult({
    required this.code,
    required this.discountAmount,
    this.discountType,
    this.message,
  });

  factory AppliedCouponResult.fromJson(Map<String, dynamic> json, [String? message]) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return AppliedCouponResult(
      code: (data['code'] ?? data['couponCode'] ?? '').toString().toUpperCase(),
      discountAmount: (data['discountAmount'] is num)
          ? (data['discountAmount'] as num).toDouble()
          : double.tryParse(data['discountAmount']?.toString() ?? '0') ?? 0,
      discountType: data['discountType']?.toString(),
      message: message ?? json['message']?.toString(),
    );
  }
}
