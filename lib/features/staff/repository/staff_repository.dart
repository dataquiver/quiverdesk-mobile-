import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/dashboard_model.dart';

class StaffRepository {
  final _dio = ApiClient.instance;

  Future<StaffDashboardModel> getDayView(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.staffDayView(tenantId));
    return StaffDashboardModel.fromJson(_data(res));
  }

  Future<List<AppointmentModel>> getAppointments(int tenantId, {String? date}) async {
    final res = await _dio.get(
      ApiEndpoints.staffAppointments(tenantId),
      queryParameters: {
        if (date != null) 'date': date,
        'pageSize': 50,
      },
    );
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AppointmentModel> getAppointmentDetail(int tenantId, int id) async {
    final res = await _dio.get(ApiEndpoints.staffAppointmentDetail(tenantId, id));
    return AppointmentModel.fromJson(_data(res));
  }

  Future<void> updateAppointmentStatus(int tenantId, int id, String status) async {
    await _dio.patch(
      '${ApiEndpoints.staffAppointmentDetail(tenantId, id)}/status',
      data: {'status': status},
    );
  }

  dynamic _data(Response res) {
    final body = res.data as Map<String, dynamic>;
    if (body['success'] == false) throw body['message'] ?? 'Error';
    return body['data'] ?? body;
  }
}
