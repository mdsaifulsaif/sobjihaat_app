import '../../data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  verificationRequired,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? pendingVerificationEmail;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.pendingVerificationEmail,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? pendingVerificationEmail,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      pendingVerificationEmail:
          pendingVerificationEmail ?? this.pendingVerificationEmail,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
