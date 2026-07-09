class ApiEndpoints {
  // AUTH
  static const login = '/api/auth/login';
  static const logout = '/api/auth/logout';
  static const refreshToken = '/api/auth/refresh-token';
  static const changePassword = '/api/auth/change-password';

  // BUSINESS OWNER — tenantId is injected at runtime
  static String dashboard(int tenantId) => '/api/business/$tenantId/dashboard';
  static String appointments(int tenantId) => '/api/business/$tenantId/appointments';
  static String appointmentDetail(int tenantId, int id) => '/api/business/$tenantId/appointments/$id';
  static String customers(int tenantId) => '/api/business/$tenantId/customers';
  static String customerDetail(int tenantId, int id) => '/api/business/$tenantId/customers/$id';
  static String services(int tenantId) => '/api/business/$tenantId/services';
  static String serviceDetail(int tenantId, int id) => '/api/business/$tenantId/services/$id';
  static String staff(int tenantId) => '/api/business/$tenantId/staff';
  static String staffDetail(int tenantId, int id) => '/api/business/$tenantId/staff/$id';
  static String invoices(int tenantId) => '/api/business/$tenantId/invoices';
  static String invoiceDetail(int tenantId, int id) => '/api/business/$tenantId/invoices/$id';
  static String invoicePayment(int tenantId, int id) => '/api/business/$tenantId/invoices/$id/pay';
  static String appointmentFeedback(int tenantId, int id) => '/api/business/$tenantId/appointments/$id/feedback';
  static String reports(int tenantId) => '/api/business/$tenantId/reports';
  static String subscription(int tenantId) => '/api/business/$tenantId/subscription';
  static String subscriptionPlanOptions(int tenantId) => '/api/business/$tenantId/subscription/plans';

  // BUSINESS OWNER — subscription payments (Razorpay)
  static String paymentCreateOrder(int tenantId) => '/api/business/$tenantId/payments/create-order';
  static String paymentVerify(int tenantId) => '/api/business/$tenantId/payments/verify';
  static String paymentHistory(int tenantId) => '/api/business/$tenantId/payments/history';
  static String paymentSubscriptionStatus(int tenantId) => '/api/business/$tenantId/payments/subscription-status';
  static String paymentCancelSubscription(int tenantId) => '/api/business/$tenantId/payments/cancel-subscription';

  // STAFF
  static String staffDayView(int tenantId) => '/api/staff/$tenantId/my-day';
  static String staffAppointments(int tenantId) => '/api/staff/$tenantId/appointments';
  static String staffAppointmentDetail(int tenantId, int id) => '/api/staff/$tenantId/appointments/$id';

  // PLATFORM ADMIN
  static const platformDashboard = '/api/platform/dashboard';
  static const platformBusinesses = '/api/platform/tenants/businesses';
  static String platformBusinessDetail(int id) => '/api/platform/tenants/businesses/$id';
  static String platformSuspendBusiness(int id) => '/api/platform/businesses/$id/suspend';
  static String platformActivateBusiness(int id) => '/api/platform/businesses/$id/activate';
  static String platformChangePlan(int id) => '/api/platform/businesses/$id/change-plan';

  // PLATFORM ADMIN — Plans
  static const platformPlans = '/api/platform/plans';
  static String platformPlanDetail(int id) => '/api/platform/plans/$id';
  static String platformPlanActivate(int id) => '/api/platform/plans/$id/activate';
  static String platformPlanDeactivate(int id) => '/api/platform/plans/$id/deactivate';

  // PLATFORM ADMIN — Features
  static const platformFeatures = '/api/platform/features';
  static String platformFeatureActivate(int id) => '/api/platform/features/$id/activate';
  static String platformFeatureDeactivate(int id) => '/api/platform/features/$id/deactivate';
  static const platformFeaturesMap = '/api/platform/features/map';

  // PLATFORM ADMIN — Payments
  static const platformPayments = '/api/platform/payments';
  static const platformPaymentsStatus = '/api/platform/payments/status';

  // PLATFORM ADMIN — Vouchers
  static const platformVouchers = '/api/platform/vouchers';
  static String platformVoucherActivate(int id) => '/api/platform/vouchers/$id/activate';
  static String platformVoucherDeactivate(int id) => '/api/platform/vouchers/$id/deactivate';
  static String platformVoucherUsages(int id) => '/api/platform/vouchers/$id/usages';

  // PLATFORM ADMIN — Reports
  static const platformReportsGrowth = '/api/platform/reports/business-growth';
  static const platformReportsRevenue = '/api/platform/reports/revenue';
  static const platformReportsPlanRevenue = '/api/platform/reports/plan-revenue';
  static const platformReportsExpiringTrials = '/api/platform/reports/expiring-trials';
  static const platformReportsRenewals = '/api/platform/reports/upcoming-renewals';

  // PLATFORM ADMIN — Notifications
  static const platformNotifications = '/api/platform/notifications';
  static const platformNotificationsSummary = '/api/platform/notifications/summary';
  static String platformNotificationRead(int id) => '/api/platform/notifications/$id/read';
  static String platformNotificationResolve(int id) => '/api/platform/notifications/$id/resolve';
  static const platformNotificationsGenerate = '/api/platform/notifications/generate';

  // STAFF — customers and billing
  static String staffCustomers(int tenantId) => '/api/staff/$tenantId/customers';
  static String staffInvoices(int tenantId) => '/api/staff/$tenantId/invoices';

  // BUSINESS OWNER — additional
  static String inventory(int tenantId) => '/api/business/$tenantId/products';
  static String memberships(int tenantId) => '/api/business/$tenantId/memberships';
  static String feedback(int tenantId) => '/api/business/$tenantId/feedback';
  static String crmFollowUps(int tenantId) => '/api/business/$tenantId/crm';
  static String crmCampaigns(int tenantId) => '/api/business/$tenantId/crm';

  // PUBLIC
  static const onboardBusiness = '/api/platform/tenants/onboard-business';
  static const industries = '/api/public/industries';
  static const businessTypes = '/api/public/business-types';
  static const subscriptionPlans = '/api/public/subscription-plans';
  static const health = '/api/public/health';

  // MOBILE SPECIFIC
  static const registerDevice = '/api/v1/mobile/register-device';
  static const appConfig = '/api/v1/mobile/app-config';
  static const mobileDashboard = '/api/v1/mobile/dashboard';
}
