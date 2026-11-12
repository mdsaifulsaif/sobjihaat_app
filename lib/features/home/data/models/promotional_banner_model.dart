class PromotionalBannerModel {
  final String id;
  final String? title;
  final String? subtitle;
  final String image;
  final String? link;
  final String? linkType;
  final String? categorySlug;
  final int order;
  final bool isActive;

  PromotionalBannerModel({
    required this.id,
    this.title,
    this.subtitle,
    required this.image,
    this.link,
    this.linkType,
    this.categorySlug,
    this.order = 0,
    this.isActive = true,
  });

  factory PromotionalBannerModel.fromJson(Map<String, dynamic> json) {
    return PromotionalBannerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      image: (json['image'] ?? '').toString(),
      link: json['link'] as String?,
      linkType: json['linkType'] as String?,
      categorySlug: json['categorySlug'] as String?,
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'subtitle': subtitle,
        'image': image,
        'link': link,
        'linkType': linkType,
        'categorySlug': categorySlug,
        'order': order,
        'isActive': isActive,
      };
}

