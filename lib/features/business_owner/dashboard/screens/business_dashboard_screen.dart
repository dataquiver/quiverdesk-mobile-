import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/models/dashboard_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_stat_card.dart';
import '../../repository/business_repository.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final _repo = BusinessRepository();
  BusinessDashboardModel? _data;
  bool _isLoading = true;
  String? _error;
  int? _tenantId;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final idStr = await TokenStorage.getBusinessId();
    final name = await TokenStorage.getUserName() ?? '';
    _tenantId = idStr != null ? int.tryParse(idStr) : null;
    if (mounted) setState(() => _userName = name);
    await _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) {
      setState(() { _isLoading = false; _error = 'No business context found'; });
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _repo.getDashboard(_tenantId!);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _statusColor(String s) => switch (s.toUpperCase()) {
    'SCHEDULED' => QDColors.scheduled,
    'CONFIRMED' => QDColors.confirmed,
    'IN_PROGRESS' => QDColors.inProgress,
    'COMPLETED' => QDColors.completed,
    'CANCELLED' => QDColors.cancelled,
    _ => QDColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(QDDateUtils.greetingByTime(),
                style: const TextStyle(fontSize: 13, color: QDColors.textSecondary, fontWeight: FontWeight.w400)),
            Text(_data?.businessName ?? 'QuiverDesk',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Greeting
                      Text(
                        'Hello, ${_userName.split(' ').first}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: QDColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        QDDateUtils.formatDate(DateTime.now()),
                        style: const TextStyle(fontSize: 14, color: QDColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Stats row 1
                      Row(
                        children: [
                          Expanded(
                            child: QDStatCard(
                              label: "Today's Appointments",
                              value: '${_data?.todayAppointments ?? 0}',
                              icon: Icons.calendar_today,
                              color: QDColors.primary,
                              onTap: () => context.go(AppRoutes.appointments),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QDStatCard(
                              label: "Today's Revenue",
                              value: QDCurrency.compact(_data?.todayRevenue ?? 0),
                              icon: Icons.currency_rupee,
                              color: QDColors.success,
                              onTap: () => context.go(AppRoutes.billing),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: QDStatCard(
                              label: 'Pending Invoices',
                              value: '${_data?.pendingInvoices ?? 0}',
                              icon: Icons.receipt_long_outlined,
                              color: QDColors.warning,
                              onTap: () => context.go(AppRoutes.billing),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QDStatCard(
                              label: 'New Customers',
                              value: '${_data?.newCustomersThisMonth ?? 0}',
                              icon: Icons.person_add_outlined,
                              color: QDColors.secondary,
                              onTap: () => context.go(AppRoutes.customers),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text('Quick Actions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _quickAction(
                            icon: Icons.add_circle_outline,
                            label: 'New\nAppointment',
                            color: QDColors.primary,
                            onTap: () => context.push(AppRoutes.newAppointment),
                          ),
                          const SizedBox(width: 10),
                          _quickAction(
                            icon: Icons.person_add_outlined,
                            label: 'Add\nCustomer',
                            color: QDColors.secondary,
                            onTap: () => context.go(AppRoutes.customers),
                          ),
                          const SizedBox(width: 10),
                          _quickAction(
                            icon: Icons.receipt_outlined,
                            label: 'View\nInvoices',
                            color: QDColors.warning,
                            onTap: () => context.go(AppRoutes.billing),
                          ),
                          const SizedBox(width: 10),
                          _quickAction(
                            icon: Icons.bar_chart,
                            label: 'Reports',
                            color: QDColors.accent,
                            onTap: () => context.go(AppRoutes.reports),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Upcoming appointments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Today's Schedule",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.appointments),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_data?.upcomingAppointments.isEmpty ?? true)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: QDColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: QDColors.border),
                          ),
                          child: const Center(
                            child: Text('No appointments today',
                                style: TextStyle(color: QDColors.textSecondary)),
                          ),
                        )
                      else
                        ...(_data!.upcomingAppointments.map((a) => _appointmentCard(a))),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newAppointment),
        tooltip: 'New Appointment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: QDColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QDColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: QDColors.textSecondary, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appointmentCard(AppointmentModel a) {
    final statusColor = _statusColor(a.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/business/appointments/${a.appointmentId}'),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(a.serviceName,
                      style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    '${QDDateUtils.formatTime(a.startTime)} · ${a.staffName}',
                    style: const TextStyle(color: QDColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                a.status,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
