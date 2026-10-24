import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<ProductReviewsResult> getProductReviews(String productId, {int page = 1, int limit = 10});
  Future<void> createReview({required String productId, required int rating, required String comment});
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final DioClient dioClient;

  ReviewRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ProductReviewsResult> getProductReviews(String productId, {int page = 1, int limit = 10}) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.productReviews(productId),
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      final rawList = data['data'];
      final reviews = <ReviewModel>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            reviews.add(ReviewModel.fromJson(item));
          }
        }
      }

      final meta = data['meta'] is Map<String, dynamic> ? data['meta'] as Map<String, dynamic> : null;
      final total = meta?['total'] is num ? (meta!['total'] as num).toInt() : reviews.length;
      final avg = meta?['averageRating'] is num
          ? (meta!['averageRating'] as num).toDouble()
          : (reviews.isNotEmpty
              ? reviews.fold<double>(0.0, (sum, r) => sum + r.rating) / reviews.length
              : 0.0);

      final ratingCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      if (meta?['ratingCounts'] is Map) {
        final rc = meta!['ratingCounts'] as Map;
        for (int i = 1; i <= 5; i++) {
          final countVal = rc['$i'] ?? rc[i];
          if (countVal is num) ratingCounts[i] = countVal.toInt();
        }
      } else {
        for (final r in reviews) {
          final star = r.rating.round();
          if (star >= 1 && star <= 5) {
            ratingCounts[star] = (ratingCounts[star] ?? 0) + 1;
          }
        }
      }

      return ProductReviewsResult(
        reviews: reviews,
        total: total,
        averageRating: avg,
        ratingCounts: ratingCounts,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> createReview({required String productId, required int rating, required String comment}) async {
    try {
      await dioClient.dio.post(
        ApiConstants.addReview,
        data: {
          'productID': productId,
          'rating': rating,
          'comment': comment,
        },
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}
