class BannerModel {
  final String id;
  final String? title;
  final String image;
  final String? mobileImage;
  final String? link;
  final int order;
  final bool isActive;

  BannerModel({
    required this.id,
    this.title,
    required this.image,
    this.mobileImage,
    this.link,
    this.order = 0,
    this.isActive = true,
  });

  String get displayImage => (mobileImage != null && mobileImage!.isNotEmpty) ? mobileImage! : image;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] as String?,
      image: (json['image'] ?? '').toString(),
      mobileImage: json['mobileImage'] as String?,
      link: json['link'] as String?,
      order: json['order'] is int ? json['order'] as int : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'image': image,
        'mobileImage': mobileImage,
        'link': link,
        'order': order,
        'isActive': isActive,
      };
}
