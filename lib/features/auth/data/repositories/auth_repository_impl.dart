import 'dart:convert';
import '../../../../core/storage/storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    final response = await remoteDataSource.login(email: email, password: password);
    if (response.accessToken != null && response.refreshToken != null) {
      await storageService.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
      );
    }
    if (response.user != null) {
      await storageService.saveUserData(jsonEncode(response.user!.toJson()));
    }
    return response;
  }

  @override
  Future<AuthResponse> googleLogin({
    required String email,
    required String firstName,
    required String lastName,
    required String googleId,
    String? avatarUrl,
  }) async {
    final response = await remoteDataSource.googleLogin(
      email: email,
      firstName: firstName,
      lastName: lastName,
      googleId: googleId,
      avatarUrl: avatarUrl,
    );
    if (response.accessToken != null && response.refreshToken != null) {
      await storageService.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
      );
    }
    if (response.user != null) {
      await storageService.saveUserData(jsonEncode(response.user!.toJson()));
    }
    return response;
  }

  @override
  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await remoteDataSource.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
    );
    if (response.accessToken != null && response.refreshToken != null) {
      await storageService.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
      );
    }
    if (response.user != null) {
      await storageService.saveUserData(jsonEncode(response.user!.toJson()));
    }
    return response;
  }

  @override
  Future<AuthResponse> verifyEmail({required String email, required String code}) async {
    final response = await remoteDataSource.verifyEmail(email: email, code: code);
    if (response.accessToken != null && response.refreshToken != null) {
      await storageService.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
      );
    }
    if (response.user != null) {
      await storageService.saveUserData(jsonEncode(response.user!.toJson()));
    }
    return response;
  }

  @override
  Future<String> resendVerificationEmail({required String email}) async {
    return await remoteDataSource.resendVerificationEmail(email: email);
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    return await remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<String> resetPassword({required String token, required String newPassword}) async {
    return await remoteDataSource.resetPassword(token: token, newPassword: newPassword);
  }

  @override
  Future<UserModel?> checkCurrentUser() async {
    final token = await storageService.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final freshUser = await remoteDataSource.getMe();
      await storageService.saveUserData(jsonEncode(freshUser.toJson()));
      return freshUser;
    } catch (_) {
      final cachedJson = storageService.getUserData();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          return UserModel.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }
      return null;
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
    final updated = await remoteDataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      addressLine: addressLine,
      city: city,
      addressState: addressState,
      postalCode: postalCode,
    );
    await storageService.saveUserData(jsonEncode(updated.toJson()));
    return updated;
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // In case backend is unreachable, still proceed to wipe local credentials
    } finally {
      await storageService.clearAll();
    }
  }
}
