import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/business_model.dart';
import '../../../core/models/dashboard_model.dart';
import '../../../core/models/platform_models.dart';

class PlatformRepository {
  final _dio = ApiClient.instance;

  // ── Dashboard ──────────────────────────────────────────────────────────────

  Future<PlatformDashboardModel> getDashboard() async {
    final res = await _dio.get(ApiEndpoints.platformDashboard);
    return PlatformDashboardModel.fromJson(_mapData(res.data));
  }

  // ── Businesses ─────────────────────────────────────────────────────────────

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

  Future<void> suspendBusiness(int id, String reason) async {
    await _dio.post(ApiEndpoints.platformSuspendBusiness(id), data: {'tenantId': id, 'reason': reason});
  }

  Future<void> activateBusiness(int id, {String? notes}) async {
    await _dio.post(ApiEndpoints.platformActivateBusiness(id), data: {'tenantId': id, 'notes': notes});
  }

  Future<void> changePlan(int id, String newPlanCode, {String? notes}) async {
    await _dio.post(ApiEndpoints.platformChangePlan(id), data: {'tenantId': id, 'newPlanCode': newPlanCode, 'notes': notes});
  }

  // ── Plans ──────────────────────────────────────────────────────────────────

  Future<List<PlatformPlanModel>> getPlans() async {
    final res = await _dio.get(ApiEndpoints.platformPlans);
    final list = _listData(res.data);
    return list.map((e) => PlatformPlanModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createPlan(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.platformPlans, data: data);
  }

  Future<void> updatePlan(int id, Map<String, dynamic> data) async {
    await _dio.put(ApiEndpoints.platformPlanDetail(id), data: data);
  }

  Future<void> activatePlan(int id) async {
    await _dio.patch(ApiEndpoints.platformPlanActivate(id));
  }

  Future<void> deactivatePlan(int id) async {
    await _dio.patch(ApiEndpoints.platformPlanDeactivate(id));
  }

  // ── Features ───────────────────────────────────────────────────────────────

  Future<List<PlatformFeatureModel>> getFeatures() async {
    final res = await _dio.get(ApiEndpoints.platformFeatures);
    final list = _listData(res.data);
    return list.map((e) => PlatformFeatureModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createFeature(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.platformFeatures, data: data);
  }

  Future<void> activateFeature(int id) async {
    await _dio.patch(ApiEndpoints.platformFeatureActivate(id));
  }

  Future<void> deactivateFeature(int id) async {
    await _dio.patch(ApiEndpoints.platformFeatureDeactivate(id));
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  Future<List<PlatformPaymentModel>> getPayments({String? status}) async {
    final res = await _dio.get(
      ApiEndpoints.platformPayments,
      queryParameters: {if (status != null && status.isNotEmpty) 'status': status},
    );
    final list = _listData(res.data);
    return list.map((e) => PlatformPaymentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createPayment(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.platformPayments, data: data);
  }

  Future<void> updatePaymentStatus(Map<String, dynamic> data) async {
    await _dio.put(ApiEndpoints.platformPaymentsStatus, data: data);
  }

  // ── Vouchers ───────────────────────────────────────────────────────────────

  Future<List<PlatformVoucherModel>> getVouchers() async {
    final res = await _dio.get(ApiEndpoints.platformVouchers);
    final list = _listData(res.data);
    return list.map((e) => PlatformVoucherModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createVoucher(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.platformVouchers, data: data);
  }

  Future<void> activateVoucher(int id) async {
    await _dio.patch(ApiEndpoints.platformVoucherActivate(id));
  }

  Future<void> deactivateVoucher(int id) async {
    await _dio.patch(ApiEndpoints.platformVoucherDeactivate(id));
  }

  Future<List<VoucherUsageModel>> getVoucherUsages(int id) async {
    final res = await _dio.get(ApiEndpoints.platformVoucherUsages(id));
    final list = _listData(res.data);
    return list.map((e) => VoucherUsageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<List<BusinessGrowthItem>> getBusinessGrowth({int months = 12}) async {
    final res = await _dio.get(ApiEndpoints.platformReportsGrowth, queryParameters: {'months': months});
    final list = _listData(res.data);
    return list.map((e) => BusinessGrowthItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RevenueReportItem>> getRevenueReport({int months = 12}) async {
    final res = await _dio.get(ApiEndpoints.platformReportsRevenue, queryParameters: {'months': months});
    final list = _listData(res.data);
    return list.map((e) => RevenueReportItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PlanWiseRevenueItem>> getPlanWiseRevenue() async {
    final res = await _dio.get(ApiEndpoints.platformReportsPlanRevenue);
    final list = _listData(res.data);
    return list.map((e) => PlanWiseRevenueItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ExpiringTrialItem>> getExpiringTrials({int daysAhead = 30}) async {
    final res = await _dio.get(ApiEndpoints.platformReportsExpiringTrials, queryParameters: {'daysAhead': daysAhead});
    final list = _listData(res.data);
    return list.map((e) => ExpiringTrialItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UpcomingRenewalItem>> getUpcomingRenewals({int daysAhead = 30}) async {
    final res = await _dio.get(ApiEndpoints.platformReportsRenewals, queryParameters: {'daysAhead': daysAhead});
    final list = _listData(res.data);
    return list.map((e) => UpcomingRenewalItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<List<PlatformNotificationModel>> getNotifications({bool unresolvedOnly = true}) async {
    final res = await _dio.get(ApiEndpoints.platformNotifications, queryParameters: {'unresolvedOnly': unresolvedOnly});
    final list = _listData(res.data);
    return list.map((e) => PlatformNotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NotificationSummaryModel> getNotificationSummary() async {
    final res = await _dio.get(ApiEndpoints.platformNotificationsSummary);
    return NotificationSummaryModel.fromJson(_mapData(res.data));
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.post(ApiEndpoints.platformNotificationRead(id));
  }

  Future<void> resolveNotification(int id) async {
    await _dio.post(ApiEndpoints.platformNotificationResolve(id));
  }

  Future<void> generateAlerts() async {
    await _dio.post(ApiEndpoints.platformNotificationsGenerate);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _mapData(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == false) throw body['message'] ?? 'Error';
      return (body['data'] as Map<String, dynamic>?) ?? body;
    }
    return {};
  }

  List<dynamic> _listData(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      if (body['data'] is List) return body['data'] as List;
      if (body['items'] is List) return body['items'] as List;
    }
    return [];
  }
}
