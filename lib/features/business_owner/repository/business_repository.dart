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
    return BusinessDashboardModel.fromJson(_mapData(res));
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
    final body = _anyData(res);
    final list = _toList(body);
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AppointmentModel> getAppointmentDetail(int tenantId, int id) async {
    final res = await _dio.get(ApiEndpoints.appointmentDetail(tenantId, id));
    return AppointmentModel.fromJson(_mapData(res));
  }

  Future<AppointmentModel> createAppointment(int tenantId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.appointments(tenantId), data: data);
    return AppointmentModel.fromJson(_mapData(res));
  }

  Future<void> updateAppointmentStatus(int tenantId, int id, String status) async {
    await _dio.put(
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
    final body = _anyData(res);
    return _toList(body).map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerModel> getCustomerDetail(int tenantId, int id) async {
    final res = await _dio.get(ApiEndpoints.customerDetail(tenantId, id));
    return CustomerModel.fromJson(_mapData(res));
  }

  Future<List<AppointmentModel>> getCustomerAppointments(int tenantId, int customerId) async {
    final res = await _dio.get(
      '${ApiEndpoints.customerDetail(tenantId, customerId)}/appointments',
    );
    final body = _anyData(res);
    return _toList(body).map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<InvoiceModel>> getInvoices(int tenantId, {String? status}) async {
    final res = await _dio.get(
      ApiEndpoints.invoices(tenantId),
      queryParameters: {
        if (status != null && status != 'ALL') 'status': status,
        'pageSize': 50,
      },
    );
    final body = _anyData(res);
    return _toList(body).map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceModel>> getServices(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.services(tenantId));
    final body = _anyData(res);
    return _toList(body).map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerModel> createCustomer(int tenantId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.customers(tenantId), data: data);
    return CustomerModel.fromJson(_mapData(res));
  }

  Future<InvoiceModel> collectPayment(int tenantId, int invoiceId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.invoicePayment(tenantId, invoiceId), data: data);
    return InvoiceModel.fromJson(_mapData(res));
  }

  Future<Map<String, dynamic>> createInventoryItem(int tenantId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.inventory(tenantId), data: data);
    return _mapData(res);
  }

  Future<void> submitAppointmentFeedback(int tenantId, int appointmentId, Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.appointmentFeedback(tenantId, appointmentId), data: data);
  }

  Future<ServiceModel> createService(int tenantId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.services(tenantId), data: data);
    return ServiceModel.fromJson(_mapData(res));
  }

  Future<void> updateService(int tenantId, int serviceId, Map<String, dynamic> data) async {
    await _dio.put(ApiEndpoints.serviceDetail(tenantId, serviceId), data: data);
  }

  Future<void> deleteService(int tenantId, int serviceId) async {
    await _dio.delete(ApiEndpoints.serviceDetail(tenantId, serviceId));
  }

  Future<List<StaffMemberModel>> getStaff(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.staff(tenantId));
    final body = _anyData(res);
    return _toList(body).map((e) => StaffMemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StaffMemberModel> addStaff(int tenantId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.staff(tenantId), data: data);
    return StaffMemberModel.fromJson(_mapData(res));
  }

  Future<void> removeStaff(int tenantId, int personTenantRoleId) async {
    await _dio.delete(ApiEndpoints.staffDetail(tenantId, personTenantRoleId));
  }

  Future<List<Map<String, dynamic>>> getInventory(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.inventory(tenantId));
    final body = _anyData(res);
    return _toList(body).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMemberships(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.memberships(tenantId));
    final body = _anyData(res);
    return _toList(body).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getFeedback(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.feedback(tenantId));
    final body = _anyData(res);
    return _toList(body).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCrmFollowUps(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.crmFollowUps(tenantId));
    final body = _anyData(res);
    return _toList(body).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCrmCampaigns(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.crmCampaigns(tenantId));
    final body = _anyData(res);
    return _toList(body).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getAvailableSlots(int tenantId,
      {required String date, required int serviceId, int? staffId}) async {
    final res = await _dio.get(
      '${ApiEndpoints.appointments(tenantId)}/available-slots',
      queryParameters: {
        'date': date,
        'serviceId': serviceId,
        'staffId': staffId?.toString() ?? 'any',
      },
    );
    return _mapData(res);
  }

  Future<List<String>> getServiceCategories(int tenantId) async {
    final res = await _dio.get('${ApiEndpoints.services(tenantId)}/categories');
    return _toList(_anyData(res)).cast<String>();
  }

  Future<Map<String, dynamic>?> getSubscription(int tenantId) async {
    try {
      final res = await _dio.get(ApiEndpoints.subscription(tenantId));
      final data = _mapData(res);
      // API returns null body when the business has no subscription yet;
      // an empty map must not render as a phantom "UNKNOWN" plan.
      return data.isEmpty ? null : data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getReports(int tenantId, {String period = 'THIS_MONTH'}) async {
    final res = await _dio.get(
      ApiEndpoints.reports(tenantId),
      queryParameters: {'period': period},
    );
    return _mapData(res);
  }

  // ── Subscription payments (Razorpay) ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSubscriptionPlanOptions(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.subscriptionPlanOptions(tenantId));
    return _toList(_anyData(res)).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createPaymentOrder(
    int tenantId, {
    required String planCode,
    required String billingCycle,
  }) async {
    final res = await _dio.post(ApiEndpoints.paymentCreateOrder(tenantId), data: {
      'planCode': planCode,
      'billingCycle': billingCycle,
    });
    return _mapData(res);
  }

  Future<Map<String, dynamic>> verifyPayment(
    int tenantId, {
    required int paymentOrderId,
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    final res = await _dio.post(ApiEndpoints.paymentVerify(tenantId), data: {
      'paymentOrderId': paymentOrderId,
      'gatewayOrderId': gatewayOrderId,
      'gatewayPaymentId': gatewayPaymentId,
      'gatewaySignature': gatewaySignature,
    });
    return _mapData(res);
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(int tenantId) async {
    final res = await _dio.get(ApiEndpoints.paymentHistory(tenantId));
    return _toList(_anyData(res)).cast<Map<String, dynamic>>();
  }

  Future<void> cancelSubscription(int tenantId) async {
    await _dio.post(ApiEndpoints.paymentCancelSubscription(tenantId));
  }

  // Returns data as Map, unwrapping {data: ...} wrapper if present.
  Map<String, dynamic> _mapData(Response res) {
    final body = res.data;
    if (body is Map<String, dynamic>) {
      if (body['success'] == false) throw body['message'] ?? 'Error';
      final inner = body['data'];
      return (inner is Map<String, dynamic>) ? inner : body;
    }
    return {};
  }

  // Returns the raw response data (could be Map or List).
  dynamic _anyData(Response res) {
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      throw body['message'] ?? 'Error';
    }
    if (body is Map<String, dynamic>) {
      return body['data'] ?? body;
    }
    return body;
  }

  // Converts any response shape to a List.
  List<dynamic> _toList(dynamic data) {
    if (data is List) return data;
    if (data is Map) return (data['items'] ?? data['data'] ?? []) as List<dynamic>;
    return [];
  }
}
