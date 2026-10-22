import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/area_model.dart';
import '../models/coupon_model.dart';

abstract class CartRemoteDataSource {
  Future<List<CouponModel>> getAvailableCoupons({String? userId});
  Future<AppliedCouponResult> applyCoupon({
    required String code,
    required double subtotal,
    String? userId,
    required List<Map<String, dynamic>> items,
  });
  Future<List<AreaModel>> getAreas();
  Future<double> getShippingPreview({
    required String deliveryType,
    required double subtotal,
  });
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final DioClient dioClient;

  CartRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CouponModel>> getAvailableCoupons({String? userId}) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.availableCoupons,
        queryParameters: userId != null && userId.isNotEmpty ? {'userID': userId} : null,
      );
      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => CouponModel.fromJson(e as Map<String, dynamic>))
            .where((c) => c.isActive)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: 'Failed to fetch coupons: $e');
    }
  }

  @override
  Future<AppliedCouponResult> applyCoupon({
    required String code,
    required double subtotal,
    String? userId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.applyCoupon,
        data: {
          'code': code.trim().toUpperCase(),
          'subtotal': subtotal,
          if (userId != null && userId.isNotEmpty) 'userID': userId,
          'items': items,
        },
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return AppliedCouponResult.fromJson(body);
      }
      throw ApiException(message: 'Invalid response from coupon service');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<AreaModel>> getAreas() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.areas);
      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => AreaModel.fromJson(e as Map<String, dynamic>))
            .where((a) => a.isActive)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: 'Failed to load delivery areas: $e');
    }
  }

  @override
  Future<double> getShippingPreview({
    required String deliveryType,
    required double subtotal,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.shippingPreview,
        queryParameters: {
          'deliveryType': deliveryType,
          'subtotal': subtotal,
        },
      );
      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        final charge = data['shippingCharge'];
        if (charge is num) return charge.toDouble();
        return double.tryParse(charge?.toString() ?? '0') ?? 0;
      }
      // Fallback: Free delivery over 1000 for local, 60 if under; 120 for nationwide
      return deliveryType == 'local' ? (subtotal >= 1000 ? 0.0 : 60.0) : 120.0;
    } catch (_) {
      // Offline / fallback calculation identical to web
      return deliveryType == 'local' ? (subtotal >= 1000 ? 0.0 : 60.0) : 120.0;
    }
  }

  @override
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.placeOrder,
        data: orderData,
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return body;
      }
      return {'success': true};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
