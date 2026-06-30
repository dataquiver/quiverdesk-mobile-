import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/models/dashboard_model.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/models/service_model.dart';
import '../../../core/models/staff_member_model.dart';

class BusinessRepository {
  final _dio = ApiClient.instance;

  Future<BusinessDashboardModel> getDashboard(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.dashboard(tenantId));
    return BusinessDashboardModel.fromJson(_data(res));
  }

  Future<List<AppointmentModel>> getAppointments(
    int tenantId, {
    String? status,
    String? date,
    int page = 1,
  }) async {
    final res = await _dio.get(
      ApiEndpoints.appointments(tenantId),
      queryParameters: {
        if (status != null && status != 'ALL') 'status': status,
        if (date != null) 'date': date,
        'page': page,
        'pageSize': 50,
      },
    );
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AppointmentModel> getAppointmentDetail(int tenantId, int id) async {
    final res = await _dio.get(ApiEndpoints.appointmentDetail(tenantId, id));
    return AppointmentModel.fromJson(_data(res));
  }

  Future<AppointmentModel> createAppointment(int tenantId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.appointments(tenantId), data: data);
    return AppointmentModel.fromJson(_data(res));
  }

  Future<void> updateAppointmentStatus(int tenantId, int id, String status) async {
    await _dio.patch(
      '${ApiEndpoints.appointmentDetail(tenantId, id)}/status',
      data: {'status': status},
    );
  }

  Future<List<CustomerModel>> getCustomers(int tenantId, {String? search}) async {
    final res = await _dio.get(
      ApiEndpoints.customers(tenantId),
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'pageSize': 100,
      },
    );
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerModel> getCustomerDetail(int tenantId, int id) async {
    final res = await _dio.get(ApiEndpoints.customerDetail(tenantId, id));
    return CustomerModel.fromJson(_data(res));
  }

  Future<List<AppointmentModel>> getCustomerAppointments(int tenantId, int customerId) async {
    final res = await _dio.get(
      '${ApiEndpoints.customerDetail(tenantId, customerId)}/appointments',
    );
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<InvoiceModel>> getInvoices(int tenantId, {String? status}) async {
    final res = await _dio.get(
      ApiEndpoints.invoices(tenantId),
      queryParameters: {
        if (status != null && status != 'ALL') 'status': status,
        'pageSize': 50,
      },
    );
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceModel>> getServices(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.services(tenantId));
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StaffMemberModel>> getStaff(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.staff(tenantId));
    final body = _data(res);
    final list = (body['items'] as List<dynamic>? ?? body as List<dynamic>? ?? []);
    return list.map((e) => StaffMemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getReports(int tenantId, {String period = 'THIS_MONTH'}) async {
    final res = await _dio.get(
      ApiEndpoints.reports(tenantId),
      queryParameters: {'period': period},
    );
    return _data(res) as Map<String, dynamic>;
  }

  dynamic _data(Response res) {
    final body = res.data as Map<String, dynamic>;
    if (body['success'] == false) throw body['message'] ?? 'Error';
    return body['data'] ?? body;
  }
}
