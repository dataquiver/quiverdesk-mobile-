import 'package:go_router/go_router.dart';
import '../core/auth/token_storage.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/business_owner/dashboard/screens/business_dashboard_screen.dart';
import '../features/business_owner/appointments/screens/appointments_screen.dart';
import '../features/business_owner/appointments/screens/appointment_detail_screen.dart';
import '../features/business_owner/appointments/screens/new_appointment_screen.dart';
import '../features/business_owner/customers/screens/customers_screen.dart';
import '../features/business_owner/customers/screens/customer_detail_screen.dart';
import '../features/business_owner/billing/screens/quick_invoice_screen.dart';
import '../features/business_owner/reports/screens/reports_screen.dart';
import '../features/business_owner/services/screens/services_screen.dart';
import '../features/business_owner/staff/screens/staff_screen.dart';
import '../features/business_owner/inventory/screens/inventory_screen.dart';
import '../features/business_owner/crm/screens/crm_screen.dart';
import '../features/business_owner/memberships/screens/memberships_screen.dart';
import '../features/business_owner/feedback/screens/feedback_screen.dart';
import '../features/business_owner/subscription/screens/subscription_screen.dart';
import '../features/staff/dashboard/screens/staff_dashboard_screen.dart';
import '../features/staff/appointments/screens/staff_appointments_screen.dart';
import '../features/staff/appointments/screens/staff_appointment_detail_screen.dart';
import '../features/platform_admin/dashboard/screens/platform_dashboard_screen.dart';
import '../features/platform_admin/businesses/screens/businesses_list_screen.dart';
import '../features/platform_admin/businesses/screens/business_detail_screen.dart';
import '../features/shared/shells/business_shell.dart';
import '../features/shared/shells/staff_shell.dart';
import '../features/shared/shells/platform_shell.dart';
import '../features/shared/screens/profile_screen.dart';
import '../features/shared/screens/change_password_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const profile = '/profile';
  static const changePassword = '/change-password';

  // Business Owner (shell tabs)
  static const businessDashboard = '/business/dashboard';
  static const appointments = '/business/appointments';
  static const customers = '/business/customers';
  static const billing = '/business/billing';
  static const reports = '/business/reports';

  // Business Owner detail (no shell)
  static const newAppointment = '/business/appointments/new';
  static const appointmentDetail = '/business/appointments/:id';
  static const customerDetail = '/business/customers/:id';
  static const businessServices = '/business/services';
  static const businessStaff = '/business/staff';
  static const businessInventory = '/business/inventory';
  static const businessCrm = '/business/crm';
  static const businessMemberships = '/business/memberships';
  static const businessFeedback = '/business/feedback';
  static const businessSubscription = '/business/subscription';

  // Staff (shell tabs)
  static const staffDashboard = '/staff/dashboard';
  static const staffAppointments = '/staff/appointments';

  // Staff detail (no shell)
  static const staffAppointmentDetail = '/staff/appointments/:id';

  // Platform Admin (shell tabs)
  static const platformDashboard = '/platform/dashboard';
  static const businesses = '/platform/businesses';

  // Platform Admin detail (no shell)
  static const businessAdminDetail = '/platform/businesses/:id';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) async {
    final isAuth = await TokenStorage.hasValidToken();
    final loc = state.matchedLocation;
    final isPublic = loc == AppRoutes.login ||
        loc == AppRoutes.splash ||
        loc == AppRoutes.register;
    if (!isAuth && !isPublic) return AppRoutes.login;
    return null;
  },
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
    GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
    GoRoute(path: AppRoutes.changePassword, builder: (_, __) => const ChangePasswordScreen()),

    // Business Owner shell
    ShellRoute(
      builder: (_, __, child) => BusinessShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.businessDashboard, builder: (_, __) => const BusinessDashboardScreen()),
        GoRoute(path: AppRoutes.appointments, builder: (_, __) => const AppointmentsScreen()),
        GoRoute(path: AppRoutes.customers, builder: (_, __) => const CustomersScreen()),
        GoRoute(path: AppRoutes.billing, builder: (_, __) => const QuickInvoiceScreen()),
        GoRoute(path: AppRoutes.reports, builder: (_, __) => const ReportsScreen()),
      ],
    ),

    // Business Owner detail (no bottom nav)
    GoRoute(path: AppRoutes.newAppointment, builder: (_, __) => const NewAppointmentScreen()),
    GoRoute(
      path: AppRoutes.appointmentDetail,
      builder: (_, state) => AppointmentDetailScreen(
        appointmentId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.customerDetail,
      builder: (_, state) => CustomerDetailScreen(
        customerId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(path: AppRoutes.businessServices, builder: (_, __) => const ServicesScreen()),
    GoRoute(path: AppRoutes.businessStaff, builder: (_, __) => const StaffScreen()),
    GoRoute(path: AppRoutes.businessInventory, builder: (_, __) => const InventoryScreen()),
    GoRoute(path: AppRoutes.businessCrm, builder: (_, __) => const CrmScreen()),
    GoRoute(path: AppRoutes.businessMemberships, builder: (_, __) => const MembershipsScreen()),
    GoRoute(path: AppRoutes.businessFeedback, builder: (_, __) => const FeedbackScreen()),
    GoRoute(path: AppRoutes.businessSubscription, builder: (_, __) => const SubscriptionScreen()),

    // Staff shell
    ShellRoute(
      builder: (_, __, child) => StaffShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.staffDashboard, builder: (_, __) => const StaffDashboardScreen()),
        GoRoute(path: AppRoutes.staffAppointments, builder: (_, __) => const StaffAppointmentsScreen()),
      ],
    ),

    // Staff detail (no bottom nav)
    GoRoute(
      path: AppRoutes.staffAppointmentDetail,
      builder: (_, state) => StaffAppointmentDetailScreen(
        appointmentId: int.parse(state.pathParameters['id']!),
      ),
    ),

    // Platform Admin shell
    ShellRoute(
      builder: (_, __, child) => PlatformShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.platformDashboard, builder: (_, __) => const PlatformDashboardScreen()),
        GoRoute(path: AppRoutes.businesses, builder: (_, __) => const BusinessesListScreen()),
      ],
    ),

    // Platform Admin detail (no bottom nav)
    GoRoute(
      path: AppRoutes.businessAdminDetail,
      builder: (_, state) => BusinessDetailScreen(
        businessId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);
