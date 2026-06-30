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

    // API returns { accessToken, expiresIn, person, contexts }
    final token = body['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw body['message'] ?? 'Login failed';
    }

    final person = body['person'] as Map<String, dynamic>? ?? {};
    final contexts = (body['contexts'] as List<dynamic>? ?? [])
        .map((e) => AuthContext.fromJson(e as Map<String, dynamic>))
        .toList();

    final primaryContext = contexts.isNotEmpty ? contexts.first : null;

    final name = person['fullName'] as String? ?? '';
    final email = person['email'] as String? ?? '';
    final userId = (person['personId'] ?? '').toString();
    final roleCode = primaryContext?.roleCode ?? '';
    final businessId = primaryContext?.tenantId;

    await TokenStorage.saveTokens(accessToken: token);
    await TokenStorage.saveUserInfo(
      role: roleCode,
      name: name,
      userId: userId,
      businessId: businessId?.toString(),
      email: email,
    );

    return UserModel(
      userId: userId,
      name: name,
      email: email,
      role: roleCode,
      businessId: businessId,
    );
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
    final savedRole = await TokenStorage.getUserRole();

    final fromJwt = UserModel.fromJwt(claims, businessId: businessId);
    // JWT may not include role — fall back to the role saved at login time
    final role = fromJwt.role.isNotEmpty ? fromJwt.role : (savedRole ?? '');
    return UserModel(
      userId: fromJwt.userId,
      name: fromJwt.name,
      email: fromJwt.email,
      role: role,
      businessId: businessId,
    );
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
