import 'user_model.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final int? accessTokenExpires;
  final UserModel? user;
  final String? verificationEmail; // when registration prompts verification

  AuthResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.accessTokenExpires,
    this.user,
    this.verificationEmail,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    String? verificationEmail;

    if (json['data'] != null) {
      if (json['data'] is Map<String, dynamic>) {
        final dataMap = json['data'] as Map<String, dynamic>;
        // If data contains an email directly (e.g. from registerUser: data: { email: ... })
        if (dataMap.containsKey('email') && !dataMap.containsKey('_id') && !dataMap.containsKey('firstName')) {
          verificationEmail = dataMap['email']?.toString();
        } else {
          parsedUser = UserModel.fromJson(dataMap);
        }
      }
    }

    return AuthResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      accessTokenExpires: json['accessTokenExpires'] as int?,
      user: parsedUser,
      verificationEmail: verificationEmail,
    );
  }
}
