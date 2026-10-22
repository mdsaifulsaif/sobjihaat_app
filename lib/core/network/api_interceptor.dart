import 'package:dio/dio.dart';
import '../storage/storage_service.dart';
import '../constants/api_constants.dart';

class ApiInterceptor extends QueuedInterceptor {
  final StorageService storageService;
  final Dio dio;

  ApiInterceptor({
    required this.storageService,
    required this.dio,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await storageService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiConstants.refreshToken) &&
        !err.requestOptions.path.contains(ApiConstants.login)) {
      final refreshToken = await storageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final response = await dio.post(
            ApiConstants.refreshToken,
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {
                'x-refresh-token': refreshToken,
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            final newAccessToken = response.data['accessToken'] as String?;
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await storageService.saveAccessToken(newAccessToken);

              final retryOptions = err.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          await storageService.clearTokens();
        }
      }
    }

    return handler.next(err);
  }
}
