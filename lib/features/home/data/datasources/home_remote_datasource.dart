import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../products/data/models/product_model.dart';
import '../../../subscriptions/data/models/subscription_package_model.dart';
import '../models/area_model.dart';
import '../models/banner_model.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';

class PaginatedCategoriesResponse {
  final List<CategoryModel> categories;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedCategoriesResponse({
    required this.categories,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

abstract class HomeRemoteDataSource {
  Future<List<BannerModel>> getBanners();
  Future<List<CategoryModel>> getCategories({int limit = 100});
  Future<PaginatedCategoriesResponse> getPaginatedCategories({
    int page = 1,
    int limit = 10,
    String? status,
  });
  Future<List<ProductModel>> getFeaturedProducts();
  Future<List<SubscriptionPackageModel>> getSubscriptionPackages();
  Future<List<BrandModel>> getBrands();
  Future<List<AreaModel>> getAreas();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.banners);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => BannerModel.fromJson(e))
            .where((b) => b.isActive)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<CategoryModel>> getCategories({int limit = 100}) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.categories,
        queryParameters: {'limit': limit, 'status': 'active', 'isDeleted': false},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PaginatedCategoriesResponse> getPaginatedCategories({
    int page = 1,
    int limit = 10,
    String? status = 'active',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'isDeleted': false,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await dioClient.dio.get(
        ApiConstants.categories,
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => CategoryModel.fromJson(e))
            .toList();

        final meta = data['meta'] as Map<String, dynamic>?;
        final total = (meta?['total'] as num?)?.toInt() ?? list.length;
        final totalPages = (meta?['totalPage'] as num?)?.toInt() ?? 1;

        return PaginatedCategoriesResponse(
          categories: list,
          page: page,
          limit: limit,
          total: total,
          totalPages: totalPages,
        );
      }
      return PaginatedCategoriesResponse(
        categories: [],
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return PaginatedCategoriesResponse(
        categories: [],
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
      );
    }
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      Response response;
      try {
        response = await dioClient.dio.get(ApiConstants.featuredProducts, queryParameters: {'limit': 50});
      } catch (_) {
        // Fallback to general products endpoint
        response = await dioClient.dio.get(ApiConstants.products, queryParameters: {'limit': 50});
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'] is List ? data['data'] as List : (data['data']?['products'] as List? ?? []);
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => ProductModel.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SubscriptionPackageModel>> getSubscriptionPackages() async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.subscriptionPackages,
        queryParameters: {'status': 'active'},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final packages = (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => SubscriptionPackageModel.fromJson(e))
            .toList();

        // Strictly sort by subscriptionPrice from lowest to highest as per specification
        packages.sort((a, b) => a.subscriptionPrice.compareTo(b.subscriptionPrice));
        return packages;
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<BrandModel>> getBrands() async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.brands,
        queryParameters: {'limit': 50, 'status': 'active'},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => BrandModel.fromJson(e))
            .where((b) => b.status == 'active')
            .toList();
        if (list.isNotEmpty) return list;
      }
      return BrandModel.fallbackBrands;
    } catch (_) {
      return BrandModel.fallbackBrands;
    }
  }


  @override
  Future<List<AreaModel>> getAreas() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.areas);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => AreaModel.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return [];
    }
  }
}
