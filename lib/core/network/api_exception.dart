import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final data = response?.data;
        String errorMessage = 'Something went wrong. Please try again.';

        if (data is Map<String, dynamic>) {
          if (data['message'] != null && data['message'].toString().isNotEmpty) {
            errorMessage = data['message'].toString();
          } else if (data['error'] != null) {
            errorMessage = data['error'].toString();
          } else if (data['errorMessages'] is List && (data['errorMessages'] as List).isNotEmpty) {
            final firstError = (data['errorMessages'] as List).first;
            if (firstError is Map && firstError['message'] != null) {
              errorMessage = firstError['message'].toString();
            }
          }
        }

        return ApiException(
          message: errorMessage,
          statusCode: response?.statusCode,
          errors: data,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Unable to connect to the server. Please check your connection or server status.',
          statusCode: 503,
        );

      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled.');

      default:
        return ApiException(
          message: dioException.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  @override
  String toString() => message;
}
