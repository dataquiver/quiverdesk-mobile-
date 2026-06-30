import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../auth/token_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  static const _devBaseUrl = 'http://10.0.2.2:7080'; // Android emulator → localhost
  static const _prodBaseUrl = 'https://api.quiverdesk.com';

  // Toggle this for release builds
  static const _isProduction = false;
  static String get baseUrl => _isProduction ? _prodBaseUrl : _devBaseUrl;

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(dio));

    if (!_isProduction) {
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ));
    }

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken != null) {
          final response = await _dio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );
          final newToken = response.data['data']['accessToken'] as String?;
          if (newToken != null) {
            await TokenStorage.saveTokens(accessToken: newToken);
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retry = await _dio.fetch(err.requestOptions);
            _isRefreshing = false;
            return handler.resolve(retry);
          }
        }
      } catch (_) {
        await TokenStorage.clearAll();
      }
      _isRefreshing = false;
    }
    handler.next(err);
  }
}
