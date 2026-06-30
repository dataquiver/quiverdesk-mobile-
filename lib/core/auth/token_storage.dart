import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'qd_access_token';
  static const _keyRefreshToken = 'qd_refresh_token';
  static const _keyUserRole = 'qd_user_role';
  static const _keyUserName = 'qd_user_name';
  static const _keyUserId = 'qd_user_id';
  static const _keyBusinessId = 'qd_business_id';
  static const _keyUserEmail = 'qd_user_email';

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  static Future<void> saveUserInfo({
    required String role,
    required String name,
    required String userId,
    String? businessId,
    String? email,
  }) async {
    await _storage.write(key: _keyUserRole, value: role);
    await _storage.write(key: _keyUserName, value: name);
    await _storage.write(key: _keyUserId, value: userId);
    if (businessId != null) {
      await _storage.write(key: _keyBusinessId, value: businessId);
    }
    if (email != null) {
      await _storage.write(key: _keyUserEmail, value: email);
    }
  }

  static Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  static Future<String?> getUserRole() => _storage.read(key: _keyUserRole);
  static Future<String?> getUserName() => _storage.read(key: _keyUserName);
  static Future<String?> getUserId() => _storage.read(key: _keyUserId);
  static Future<String?> getBusinessId() => _storage.read(key: _keyBusinessId);
  static Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);

  static Future<void> clearAll() async => _storage.deleteAll();

  static Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    return !_isExpired(token);
  }

  static bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(decoded) as Map<String, dynamic>;
      final exp = map['exp'] as int?;
      if (exp == null) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }
}
