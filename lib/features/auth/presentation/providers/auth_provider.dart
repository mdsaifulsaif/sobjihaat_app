import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

// Dependency Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs: prefs);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DioClient(storageService: storageService);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSourceImpl(dioClient: dioClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
  );
});

// Modern Riverpod Notifier Provider
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  StorageService get _storageService => ref.read(storageServiceProvider);

  /// Check stored credentials and validate session
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.checkCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
      }
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    }
  }

  /// User Login
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final response = await _repository.login(email: email, password: password);

      if (rememberMe) {
        await _storageService.setRememberEmail(email);
      } else {
        await _storageService.clearRememberEmail();
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        successMessage: 'Welcome back, ${response.user?.firstName ?? ''}!',
      );
      return true;
    } on ApiException catch (e) {
      if (e.message.toLowerCase().contains('verify your email')) {
        state = state.copyWith(
          status: AuthStatus.verificationRequired,
          pendingVerificationEmail: email,
          errorMessage: e.message,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        );
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  /// Google Sign In
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: ApiConstants.googleClientId,
        scopes: ['email', 'profile'],
      );

      GoogleSignInAccount? account;
      try {
        account = await googleSignIn.signIn();
      } catch (e) {
        // Fallback: try direct sign-in without serverClientId
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        account = await googleSignIn.signIn();
      }

      if (account == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return false;
      }

      final fullName = (account.displayName ?? '').trim();
      final nameParts = fullName.split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty
          ? nameParts.first
          : (account.email.split('@').first);
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : 'User';

      final response = await _repository.googleLogin(
        email: account.email,
        firstName: firstName,
        lastName: lastName,
        googleId: account.id,
        avatarUrl: account.photoUrl,
      );

      if (response.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
          successMessage: 'Welcome back, ${response.user?.firstName ?? ''}!',
        );
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: response.message.isNotEmpty
            ? response.message
            : 'Google login failed.',
      );
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } on PlatformException catch (e) {
      String msg = 'Google Sign-In failed.';
      if (e.code == 'sign_in_failed' ||
          (e.message?.contains('10') ?? false) ||
          e.toString().contains('10')) {
        msg = 'Google Sign-In config issue (ApiException 10): Android SHA-1 fingerprint needs to be added in Google Cloud Console.';
      } else if (e.code == 'network_error') {
        msg = 'Network error during Google Sign-In. Please check your internet connection.';
      } else {
        msg = e.message ?? e.toString();
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// User Registration
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final response = await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(
        status: AuthStatus.verificationRequired,
        pendingVerificationEmail: response.verificationEmail ?? email,
        successMessage: response.message,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to create account. Please try again.',
      );
      return false;
    }
  }

  /// Verify Email with 6-digit OTP code
  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final response = await _repository.verifyEmail(email: email, code: code);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        pendingVerificationEmail: null,
        successMessage: 'Account verified successfully!',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification failed. Please check the code and try again.',
      );
      return false;
    }
  }

  /// Resend verification code
  Future<bool> resendVerificationEmail({required String email}) async {
    try {
      final message = await _repository.resendVerificationEmail(email: email);
      state = state.copyWith(successMessage: message);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to resend code');
      return false;
    }
  }

  /// Forgot Password
  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final message = await _repository.forgotPassword(email: email);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: message,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to send password reset link',
      );
      return false;
    }
  }

  /// Reset Password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final message = await _repository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: message,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to reset password. Link may be invalid or expired.',
      );
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? addressLine,
    String? city,
    String? addressState,
    String? postalCode,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final updatedUser = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        addressLine: addressLine,
        city: city,
        addressState: addressState,
        postalCode: postalCode,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: updatedUser,
        successMessage: 'Profile updated successfully! 🎉',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to update profile. Please try again.',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void setPendingVerificationEmail(String email) {
    state = state.copyWith(
      pendingVerificationEmail: email,
      status: AuthStatus.verificationRequired,
    );
  }
}
