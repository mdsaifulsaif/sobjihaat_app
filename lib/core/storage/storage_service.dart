import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences prefs;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _baseUrlOverrideKey = 'custom_base_url';
  static const String _rememberEmailKey = 'remember_email';

  StorageService({
    FlutterSecureStorage? secureStorage,
    required this.prefs,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // --- Secure Tokens ---
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // --- Cached User Profile & Settings ---
  Future<void> saveUserData(String userJson) async {
    await prefs.setString(_userDataKey, userJson);
  }

  String? getUserData() {
    return prefs.getString(_userDataKey);
  }

  Future<void> clearUserData() async {
    await prefs.remove(_userDataKey);
  }

  // --- Base URL Override for physical devices / dev servers ---
  Future<void> setCustomBaseUrl(String url) async {
    await prefs.setString(_baseUrlOverrideKey, url.trim());
  }

  String? getCustomBaseUrl() {
    return prefs.getString(_baseUrlOverrideKey);
  }

  Future<void> removeCustomBaseUrl() async {
    await prefs.remove(_baseUrlOverrideKey);
  }

  // --- Remember Me ---
  Future<void> setRememberEmail(String email) async {
    await prefs.setString(_rememberEmailKey, email);
  }

  String? getRememberEmail() {
    return prefs.getString(_rememberEmailKey);
  }

  Future<void> clearRememberEmail() async {
    await prefs.remove(_rememberEmailKey);
  }

  // Complete clean wipe on logout
  Future<void> clearAll() async {
    await clearTokens();
    await clearUserData();
  }
}
