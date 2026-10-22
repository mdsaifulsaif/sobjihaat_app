class BrandModel {
  final String id;
  final String name;
  final String slug;
  final String logo;
  final int productCount;
  final String status;

  BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
    this.productCount = 0,
    this.status = 'active',
  });

  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  String get countText {
    if (productCount > 0) {
      return '$productCount ${productCount == 1 ? "Product" : "Products"}';
    }
    return 'View Products';
  }

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return BrandModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      productCount: parseInt(json['productCount']),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'slug': slug,
        'logo': logo,
        'productCount': productCount,
        'status': status,
      };

  static final List<BrandModel> fallbackBrands = [
    BrandModel(
      id: 'b1',
      name: 'colgate',
      slug: 'colgate',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783743224/glowly/glowly_brands/fwofchvyottpjzbqxhmu.webp',
      productCount: 0,
    ),
    BrandModel(
      id: 'b2',
      name: 'marks',
      slug: 'marks',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783742450/glowly/glowly_brands/hr8gb7jqwk16mrmrhexd.jpg',
      productCount: 2,
    ),
    BrandModel(
      id: 'b3',
      name: 'godraj',
      slug: 'godraj',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783743236/glowly/glowly_brands/nokjkfkbppywgke72ufx.webp',
      productCount: 1,
    ),
    BrandModel(
      id: 'b4',
      name: 'nestle',
      slug: 'nestle',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783742608/glowly/glowly_brands/y1zzegsxgnjhswzfkzac.jpg',
      productCount: 1,
    ),
    BrandModel(
      id: 'b5',
      name: 'pusti',
      slug: 'pusti',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783742575/glowly/glowly_brands/meovguorrwmwzgcpmiqx.jpg',
      productCount: 1,
    ),
    BrandModel(
      id: 'b6',
      name: 'fresh',
      slug: 'fresh',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783742556/glowly/glowly_brands/ampnqct8qekkpplpuvdt.jpg',
      productCount: 2,
    ),
    BrandModel(
      id: 'b7',
      name: 'aci',
      slug: 'aci',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783742398/glowly/glowly_brands/jgpgsu6amevbrq7jed0k.jpg',
      productCount: 2,
    ),
    BrandModel(
      id: 'b8',
      name: 'reckitt',
      slug: 'reckitt',
      logo:
          'https://res.cloudinary.com/dvpfgfwj4/image/upload/v1783743251/glowly/glowly_brands/wagcmzp9eg7qd7wa4d7s.webp',
      productCount: 7,
    ),
  ];
}

