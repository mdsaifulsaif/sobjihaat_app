class ProductModel {
  final String id;
  final String name;
  final String? shortDescription;
  final double regularPrice;
  final double? salePrice;
  final int discountPercent;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final double? weightOrVolume;
  final String? unitName;
  final String? categoryName;
  final bool isFeatured;
  final bool isOnSale;

  ProductModel({
    required this.id,
    required this.name,
    this.shortDescription,
    required this.regularPrice,
    this.salePrice,
    this.discountPercent = 0,
    this.stock = 0,
    required this.thumbnail,
    this.images = const [],
    this.weightOrVolume,
    this.unitName,
    this.categoryName,
    this.isFeatured = false,
    this.isOnSale = false,
  });

  double get effectivePrice => (salePrice != null && salePrice! > 0 && salePrice! < regularPrice)
      ? salePrice!
      : regularPrice;

  bool get hasDiscount => (salePrice != null && salePrice! > 0 && salePrice! < regularPrice) || discountPercent > 0;

  int get computedDiscountPercent {
    if (discountPercent > 0) return discountPercent;
    if (salePrice != null && salePrice! > 0 && salePrice! < regularPrice) {
      return (((regularPrice - salePrice!) / regularPrice) * 100).round();
    }
    return 0;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
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

    List<String> parseImages(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    String? parseUnitName() {
      if (json['unitDetails'] is Map) {
        return (json['unitDetails']['shortName'] ?? json['unitDetails']['name'])?.toString();
      }
      if (json['unit'] is Map) {
        return (json['unit']['shortName'] ?? json['unit']['name'])?.toString();
      }
      if (json['unit'] is String && json['unit'].toString().isNotEmpty) {
        return json['unit'].toString();
      }
      return null;
    }

    String? parseCategoryName() {
      if (json['categoryDetails'] is Map) {
        return json['categoryDetails']['name']?.toString();
      }
      if (json['categoryID'] is Map) {
        return json['categoryID']['name']?.toString();
      }
      if (json['category'] is Map) {
        return json['category']['name']?.toString();
      }
      if (json['categoryName'] != null) {
        return json['categoryName'].toString();
      }
      return null;
    }

    return ProductModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      shortDescription: json['shortDescription'] as String?,
      regularPrice: parseDouble(json['regularPrice']),
      salePrice: json['salePrice'] != null ? parseDouble(json['salePrice']) : null,
      discountPercent: parseInt(json['discountPercent']),
      stock: parseInt(json['stock']),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      images: parseImages(json['images']),
      weightOrVolume: json['weightOrVolume'] != null ? parseDouble(json['weightOrVolume']) : null,
      unitName: parseUnitName(),
      categoryName: parseCategoryName(),
      isFeatured: json['isFeatured'] == true,
      isOnSale: json['isOnSale'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'shortDescription': shortDescription,
        'regularPrice': regularPrice,
        'salePrice': salePrice,
        'discountPercent': discountPercent,
        'stock': stock,
        'thumbnail': thumbnail,
        'images': images,
        'weightOrVolume': weightOrVolume,
        'isFeatured': isFeatured,
        'isOnSale': isOnSale,
      };
}
