import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<OrdersResponseModel> getMyOrders({
    int page = 1,
    int limit = 10,
    String? status,
  });

  Future<OrderModel> getOrderTracking(String orderIdOrNumber);

  Future<OrderModel> cancelOrder({
    required String orderId,
    required String reason,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final DioClient dioClient;

  OrderRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<OrdersResponseModel> getMyOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.toLowerCase();
      }

      final response = await dioClient.dio.get(
        ApiConstants.myOrders,
        queryParameters: queryParams,
      );

      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
        return OrdersResponseModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      return OrdersResponseModel(orders: [], total: 0, page: page, limit: limit);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: 'Failed to fetch orders: $e');
    }
  }

  @override
  Future<OrderModel> getOrderTracking(String orderIdOrNumber) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.trackOrder(orderIdOrNumber),
      );

      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
        return OrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Invalid tracking details returned from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: 'Failed to track order: $e');
    }
  }

  @override
  Future<OrderModel> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      final response = await dioClient.dio.patch(
        ApiConstants.cancelOrder(orderId),
        data: {'reason': reason},
      );

      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
        return OrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Failed to cancel order');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: 'Failed to cancel order: $e');
    }
  }
}
