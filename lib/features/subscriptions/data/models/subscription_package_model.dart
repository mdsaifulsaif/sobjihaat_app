class PackageItemModel {
  final String itemName;
  final String? quantity;
  final String? note;

  PackageItemModel({
    required this.itemName,
    this.quantity,
    this.note,
  });

  factory PackageItemModel.fromJson(Map<String, dynamic> json) {
    return PackageItemModel(
      itemName: (json['itemName'] ?? '').toString(),
      quantity: json['quantity']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'quantity': quantity,
        'note': note,
      };
}

class SubscriptionPackageModel {
  final String id;
  final String name;
  final String slug;
  final String boxType;
  final String? category;
  final String frequency; // weekly, monthly, both
  final String? frequencyText;
  final String? badge;
  final String? shortDescription;
  final String thumbnail;
  final double regularPrice;
  final double subscriptionPrice;
  final double? salePrice;
  final int discountPercent;
  final bool freeShipping;
  final List<PackageItemModel> items;
  final String? idealFor;
  final bool isPinnedToHome;
  final int sortOrder;
  final bool allowOneTimePurchase;

  SubscriptionPackageModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.boxType,
    this.category,
    required this.frequency,
    this.frequencyText,
    this.badge,
    this.shortDescription,
    required this.thumbnail,
    required this.regularPrice,
    required this.subscriptionPrice,
    this.salePrice,
    this.discountPercent = 0,
    this.freeShipping = true,
    this.items = const [],
    this.idealFor,
    this.isPinnedToHome = false,
    this.sortOrder = 0,
    this.allowOneTimePurchase = true,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    List<PackageItemModel> parseItems(dynamic val) {
      if (val is List) {
        return val
            .whereType<Map<String, dynamic>>()
            .map((item) => PackageItemModel.fromJson(item))
            .toList();
      }
      return [];
    }

    return SubscriptionPackageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      boxType: (json['boxType'] ?? 'Box').toString(),
      category: json['category']?.toString(),
      frequency: (json['frequency'] ?? 'monthly').toString(),
      frequencyText: json['frequencyText']?.toString(),
      badge: json['badge']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      regularPrice: parseDouble(json['regularPrice']),
      subscriptionPrice: parseDouble(json['subscriptionPrice']),
      salePrice: json['salePrice'] != null ? parseDouble(json['salePrice']) : null,
      discountPercent: parseInt(json['discountPercent']),
      freeShipping: json['freeShipping'] != false,
      items: parseItems(json['items']),
      idealFor: json['idealFor']?.toString(),
      isPinnedToHome: json['isPinnedToHome'] == true,
      sortOrder: parseInt(json['sortOrder']),
      allowOneTimePurchase: json['allowOneTimePurchase'] != false,
    );
  }
}
