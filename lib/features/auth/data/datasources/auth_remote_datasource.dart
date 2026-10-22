import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login({required String email, required String password});
  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  });
  Future<AuthResponse> verifyEmail({required String email, required String code});
  Future<String> resendVerificationEmail({required String email});
  Future<String> forgotPassword({required String email});
  Future<UserModel> getMe();
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? addressLine,
    String? city,
    String? addressState,
    String? postalCode,
  });
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final payload = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phoneNumber': phoneNumber.trim(),
      };

      final response = await dioClient.dio.post(
        ApiConstants.register,
        data: payload,
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AuthResponse> verifyEmail({required String email, required String code}) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.verifyEmail,
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> resendVerificationEmail({required String email}) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.resendVerification,
        data: {
          'email': email.trim().toLowerCase(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['message'] ?? 'Verification code resent successfully!').toString();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.forgotPassword,
        data: {
          'email': email.trim().toLowerCase(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['message'] ?? 'Password reset link sent to your email.').toString();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.getMe);
      final data = response.data as Map<String, dynamic>;
      if (data['data'] != null && data['data'] is Map<String, dynamic>) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Invalid profile data returned from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? addressLine,
    String? city,
    String? addressState,
    String? postalCode,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (firstName != null) 'firstName': firstName.trim(),
        if (lastName != null) 'lastName': lastName.trim(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
        if (addressLine != null) 'addressLine': addressLine.trim(),
        if (city != null) 'city': city.trim(),
        if (addressState != null) 'state': addressState.trim(),
        if (postalCode != null) 'postalCode': postalCode.trim(),
      };

      final response = await dioClient.dio.patch(
        ApiConstants.updateProfile,
        data: payload,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['data'] != null && data['data'] is Map<String, dynamic>) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Invalid profile data returned from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
