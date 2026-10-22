import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/product_model.dart';

class PaginatedProductsResponse {
  final List<ProductModel> products;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedProductsResponse({
    required this.products,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

abstract class ProductRemoteDataSource {
  Future<PaginatedProductsResponse> getProductsByCategorySlug({
    required String slug,
    int page = 1,
    int limit = 12,
    String? searchTerm,
    String? sort,
  });

  Future<PaginatedProductsResponse> searchProducts({
    required String searchTerm,
    int page = 1,
    int limit = 12,
    String? sort,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient dioClient;

  ProductRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PaginatedProductsResponse> getProductsByCategorySlug({
    required String slug,
    int page = 1,
    int limit = 12,
    String? searchTerm,
    String? sort,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (searchTerm != null && searchTerm.trim().isNotEmpty) {
        queryParams['searchTerm'] = searchTerm.trim();
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final response = await dioClient.dio.get(
        ApiConstants.productsByCategory(slug),
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final rawList = data['data'];
        final meta = data['meta'] as Map<String, dynamic>?;

        final products = (rawList is List)
            ? rawList
                .whereType<Map<String, dynamic>>()
                .map((e) => ProductModel.fromJson(e))
                .toList()
            : <ProductModel>[];

        final pageNum = meta?['page'] is num ? (meta!['page'] as num).toInt() : page;
        final limitNum = meta?['limit'] is num ? (meta!['limit'] as num).toInt() : limit;
        final total = meta?['total'] is num ? (meta!['total'] as num).toInt() : products.length;
        final totalPages = meta?['totalPage'] is num
            ? (meta!['totalPage'] as num).toInt()
            : (meta?['totalPages'] is num ? (meta!['totalPages'] as num).toInt() : 1);

        return PaginatedProductsResponse(
          products: products,
          page: pageNum,
          limit: limitNum,
          total: total,
          totalPages: totalPages,
        );
      }

      return PaginatedProductsResponse(
        products: [],
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<PaginatedProductsResponse> searchProducts({
    required String searchTerm,
    int page = 1,
    int limit = 12,
    String? sort,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'status': 'active',
      };
      if (searchTerm.trim().isNotEmpty) {
        queryParams['searchTerm'] = searchTerm.trim();
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final response = await dioClient.dio.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final rawList = data['data'];
        final meta = data['meta'] as Map<String, dynamic>?;

        final products = (rawList is List)
            ? rawList
                .whereType<Map<String, dynamic>>()
                .map((e) => ProductModel.fromJson(e))
                .toList()
            : <ProductModel>[];

        final pageNum = meta?['page'] is num ? (meta!['page'] as num).toInt() : page;
        final limitNum = meta?['limit'] is num ? (meta!['limit'] as num).toInt() : limit;
        final total = meta?['total'] is num ? (meta!['total'] as num).toInt() : products.length;
        final totalPages = meta?['totalPage'] is num
            ? (meta!['totalPage'] as num).toInt()
            : (meta?['totalPages'] is num ? (meta!['totalPages'] as num).toInt() : 1);

        return PaginatedProductsResponse(
          products: products,
          page: pageNum,
          limit: limitNum,
          total: total,
          totalPages: totalPages,
        );
      }

      return PaginatedProductsResponse(
        products: [],
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
