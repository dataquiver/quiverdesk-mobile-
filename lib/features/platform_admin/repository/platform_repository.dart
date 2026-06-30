import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/business_model.dart';
import '../../../core/models/dashboard_model.dart';

class PlatformRepository {
  final _dio = ApiClient.instance;

  Future<PlatformDashboardModel> getDashboard() async {
    final res = await _dio.get(ApiEndpoints.platformDashboard);
    return PlatformDashboardModel.fromJson(_mapData(res.data));
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
    final data = res.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = (data['items'] ?? data['data'] ?? []) as List<dynamic>;
    } else {
      list = [];
    }
    return list.map((e) => BusinessModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BusinessModel> getBusinessDetail(int id) async {
    final res = await _dio.get(ApiEndpoints.platformBusinessDetail(id));
    return BusinessModel.fromJson(_mapData(res.data));
  }

  Map<String, dynamic> _mapData(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == false) throw body['message'] ?? 'Error';
      return (body['data'] as Map<String, dynamic>?) ?? body;
    }
    return {};
  }
}
