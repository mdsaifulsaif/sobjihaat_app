import '../../data/models/auth_response.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
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
  Future<UserModel?> checkCurrentUser();
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
