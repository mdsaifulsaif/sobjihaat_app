import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';
import 'api_interceptor.dart';

class DioClient {
  late final Dio dio;
  final StorageService storageService;

  DioClient({required this.storageService}) {
    final customUrl = storageService.getCustomBaseUrl();
    final baseUrl = (customUrl != null && customUrl.isNotEmpty)
        ? customUrl
        : ApiConstants.defaultBaseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      ApiInterceptor(storageService: storageService, dio: dio),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}
