class ReviewUserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatar;

  ReviewUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
  });

  factory ReviewUserModel.fromJson(Map<String, dynamic> json) {
    return ReviewUserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
}

class ReviewModel {
  final String id;
  final String productId;
  final ReviewUserModel? user;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    this.user,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      productId: (json['productID'] ?? json['productId'] ?? '').toString(),
      user: json['user'] is Map<String, dynamic>
          ? ReviewUserModel.fromJson(json['user'])
          : null,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class ProductReviewsResult {
  final List<ReviewModel> reviews;
  final int total;
  final double averageRating;
  final Map<int, int> ratingCounts;

  ProductReviewsResult({
    required this.reviews,
    required this.total,
    required this.averageRating,
    required this.ratingCounts,
  });
}
