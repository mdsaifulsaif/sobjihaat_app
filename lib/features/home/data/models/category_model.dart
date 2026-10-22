class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String image;
  final int productCount;
  final bool isFeatured;
  final bool showInHome;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    required this.image,
    this.productCount = 0,
    this.isFeatured = false,
    this.showInHome = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return CategoryModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      image: (json['image'] ?? '').toString(),
      productCount: parseInt(json['productCount'] ?? json['itemCount']),
      isFeatured: json['isFeatured'] == true,
      showInHome: json['showInHome'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'icon': icon,
        'image': image,
        'productCount': productCount,
        'isFeatured': isFeatured,
        'showInHome': showInHome,
      };
}
