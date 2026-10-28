class ShippingTierModel {
  final int min;
  final int max;
  final double charge;

  const ShippingTierModel({
    required this.min,
    required this.max,
    required this.charge,
  });

  bool get isFree => charge <= 0;
  bool get isUnlimited => max >= 99999;

  String get orderRangeText {
    if (isUnlimited) {
      return '৳$min+';
    }
    return '৳$min – ৳$max';
  }

  String get chargeText => isFree ? 'Free' : '৳${charge.toInt()}';

  factory ShippingTierModel.fromJson(Map<String, dynamic> json) {
    return ShippingTierModel(
      min: (json['min'] is num)
          ? (json['min'] as num).toInt()
          : int.tryParse(json['min']?.toString() ?? '0') ?? 0,
      max: (json['max'] is num)
          ? (json['max'] as num).toInt()
          : int.tryParse(json['max']?.toString() ?? '99999') ?? 99999,
      charge: (json['charge'] is num)
          ? (json['charge'] as num).toDouble()
          : double.tryParse(json['charge']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'charge': charge,
      };
}

class ShippingConfigModel {
  final String id;
  final String type;
  final bool isActive;
  final List<ShippingTierModel> tiers;
  final double riderCommission;

  const ShippingConfigModel({
    required this.id,
    required this.type,
    required this.isActive,
    required this.tiers,
    this.riderCommission = 0,
  });

  static List<ShippingTierModel> get defaultTiers => const [
        ShippingTierModel(min: 0, max: 499, charge: 30),
        ShippingTierModel(min: 500, max: 999, charge: 50),
        ShippingTierModel(min: 1000, max: 1999, charge: 40),
        ShippingTierModel(min: 2000, max: 4999, charge: 30),
        ShippingTierModel(min: 5000, max: 999999, charge: 0),
      ];

  int get freeDeliveryThreshold {
    final freeTier = tiers.firstWhere(
      (t) => t.isFree,
      orElse: () => const ShippingTierModel(min: 5000, max: 999999, charge: 0),
    );
    return freeTier.min;
  }

  double get baseShippingCharge {
    if (tiers.isNotEmpty) return tiers.first.charge;
    return 30.0;
  }

  double getChargeForSubtotal(double subtotal) {
    if (tiers.isEmpty) return subtotal >= 5000 ? 0.0 : 30.0;
    for (final tier in tiers) {
      if (subtotal >= tier.min && subtotal <= tier.max) {
        return tier.charge;
      }
    }
    if (subtotal >= freeDeliveryThreshold) {
      return 0.0;
    }
    return tiers.first.charge;
  }

  factory ShippingConfigModel.fromJson(Map<String, dynamic> json) {
    final rawTiers = json['tiers'];
    List<ShippingTierModel> tierList = [];
    if (rawTiers is List) {
      tierList = rawTiers
          .whereType<Map<String, dynamic>>()
          .map((e) => ShippingTierModel.fromJson(e))
          .toList();
    }
    if (tierList.isEmpty) {
      tierList = defaultTiers;
    }
    return ShippingConfigModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'local').toString(),
      isActive: json['isActive'] != false,
      tiers: tierList,
      riderCommission: (json['riderCommission'] is num)
          ? (json['riderCommission'] as num).toDouble()
          : 0.0,
    );
  }
}
