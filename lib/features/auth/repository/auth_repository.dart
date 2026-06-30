import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/models/user_model.dart';

class AuthRepository {
  final _dio = ApiClient.instance;

  Future<UserModel> login(String emailOrMobile, String password) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'emailOrMobile': emailOrMobile, 'password': password},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw body['message'] ?? 'Login failed';
    }

    final data = body['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final contexts = (data['contexts'] as List<dynamic>? ?? [])
        .map((e) => AuthContext.fromJson(e as Map<String, dynamic>))
        .toList();

    // Decode JWT to get claims
    final claims = _decodeJwt(token);
    final primaryContext = contexts.isNotEmpty ? contexts.first : null;

    await TokenStorage.saveTokens(accessToken: token);
    await TokenStorage.saveUserInfo(
      role: primaryContext?.roleCode ?? '',
      name: claims['Name'] ?? '',
      userId: (claims['personId'] ?? '').toString(),
      businessId: primaryContext?.tenantId.toString(),
      email: claims['Email'] ?? '',
    );

    return UserModel.fromJwt(claims, businessId: primaryContext?.tenantId);
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await TokenStorage.clearAll();
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return null;

    final claims = _decodeJwt(token);
    final businessIdStr = await TokenStorage.getBusinessId();
    final businessId = businessIdStr != null ? int.tryParse(businessIdStr) : null;

    return UserModel.fromJwt(claims, businessId: businessId);
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
