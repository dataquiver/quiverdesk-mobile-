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
  static String staff(int tenantId) => '/api/business/$tenantId/staff';
  static String invoices(int tenantId) => '/api/business/$tenantId/invoices';
  static String reports(int tenantId) => '/api/business/$tenantId/reports';
  static String subscription(int tenantId) => '/api/business/$tenantId/subscription';

  // STAFF
  static String staffDayView(int tenantId) => '/api/staff/$tenantId/my-day';
  static String staffAppointments(int tenantId) => '/api/staff/$tenantId/appointments';
  static String staffAppointmentDetail(int tenantId, int id) => '/api/staff/$tenantId/appointments/$id';

  // PLATFORM ADMIN
  static const platformDashboard = '/api/platform/dashboard';
  static const platformBusinesses = '/api/platform/tenants/businesses';
  static String platformBusinessDetail(int id) => '/api/platform/tenants/businesses/$id';

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
