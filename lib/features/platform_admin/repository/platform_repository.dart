import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/business_model.dart';
import '../../../core/models/dashboard_model.dart';

class PlatformRepository {
  final _dio = ApiClient.instance;

  Future<PlatformDashboardModel> getDashboard() async {
    final res = await _dio.get(ApiEndpoints.platformDashboard);
    return PlatformDashboardModel.fromJson(_data(res));
  }

  Future<List<BusinessModel>> getBusinesses({String? search, int page = 1}) async {
    final res = await _dio.get(
      ApiEndpoints.platformBusinesses,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'pageSize': 50,
      },
    );
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => BusinessModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BusinessModel> getBusinessDetail(int id) async {
    final res = await _dio.get(ApiEndpoints.platformBusinessDetail(id));
    return BusinessModel.fromJson(_data(res));
  }

  dynamic _data(Response res) {
    final body = res.data as Map<String, dynamic>;
    if (body['success'] == false) throw body['message'] ?? 'Error';
    return body['data'] ?? body;
  }
}
