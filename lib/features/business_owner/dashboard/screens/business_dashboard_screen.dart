import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../app/routes.dart';
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
    'SCHEDULED'   => QDPalette.info500,
    'CONFIRMED'   => QDPalette.success500,
    'IN_PROGRESS' => QDPalette.warning500,
    'COMPLETED'   => QDPalette.success700,
    'CANCELLED'   => QDPalette.neutral400,
    _             => QDPalette.neutral300,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: QDPalette.primary500,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(QDSpace.screenPad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting
                              Text(
                                'Hello, ${_userName.split(' ').first}! 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: QDPalette.neutral900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                QDDateUtils.formatDate(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: QDPalette.neutral400,
                                ),
                              ),
                              const SizedBox(height: QDSpace.x5),

                              // Stats 2×2
                              Row(
                                children: [
                                  Expanded(
                                    child: QDStatCard(
                                      label: "Today's Appointments",
                                      value: '${_data?.todayAppointments ?? 0}',
                                      icon: Icons.calendar_today_rounded,
                                      color: QDPalette.primary500,
                                      onTap: () => context.go(AppRoutes.appointments),
                                    ),
                                  ),
                                  const SizedBox(width: QDSpace.cardGap),
                                  Expanded(
                                    child: QDStatCard(
                                      label: "Today's Revenue",
                                      value: QDCurrency.compact(_data?.todayRevenue ?? 0),
                                      icon: Icons.currency_rupee_rounded,
                                      color: QDPalette.success500,
                                      onTap: () => context.go(AppRoutes.billing),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: QDSpace.cardGap),
                              Row(
                                children: [
                                  Expanded(
                                    child: QDStatCard(
                                      label: 'Pending Invoices',
                                      value: '${_data?.pendingInvoices ?? 0}',
                                      icon: Icons.receipt_long_rounded,
                                      color: QDPalette.warning500,
                                      onTap: () => context.go(AppRoutes.billing),
                                    ),
                                  ),
                                  const SizedBox(width: QDSpace.cardGap),
                                  Expanded(
                                    child: QDStatCard(
                                      label: 'New Customers',
                                      value: '${_data?.newCustomersThisMonth ?? 0}',
                                      icon: Icons.person_add_rounded,
                                      color: QDPalette.info500,
                                      onTap: () => context.go(AppRoutes.customers),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: QDSpace.sectionGap),

                              // Quick Actions
                              const Text('Quick Actions',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                      color: QDPalette.neutral800, letterSpacing: -0.2)),
                              const SizedBox(height: QDSpace.cardGap),
                              _buildQuickActions(),
                              const SizedBox(height: QDSpace.sectionGap),

                              // Today's schedule
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Today's Schedule",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                          color: QDPalette.neutral800, letterSpacing: -0.2)),
                                  GestureDetector(
                                    onTap: () => context.go(AppRoutes.appointments),
                                    child: const Text('View All',
                                        style: TextStyle(fontSize: 13, color: QDPalette.primary600,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: QDSpace.cardGap),
                              if (_data?.upcomingAppointments.isEmpty ?? true)
                                _emptySchedule()
                              else
                                ...(_data!.upcomingAppointments.map(_appointmentCard)),
                              const SizedBox(height: QDSpace.x4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.newAppointment);
        },
        backgroundColor: QDPalette.primary500,
        foregroundColor: Colors.white,
        elevation: 2,
        tooltip: 'New Appointment',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: QDPalette.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(QDDateUtils.greetingByTime(),
              style: const TextStyle(fontSize: 12, color: QDPalette.neutral400,
                  fontWeight: FontWeight.w500)),
          Text(_data?.businessName ?? 'QuiverDesk',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: QDPalette.neutral900)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: QDPalette.neutral600),
          onPressed: () => context.push(AppRoutes.profile),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: QDPalette.neutral100),
      ),
    );
  }

  Widget _buildQuickActions() {
    const items = [
      _QuickActionDef(Icons.add_circle_rounded,  'New\nAppt.',   QDPalette.primary500),
      _QuickActionDef(Icons.person_add_rounded,  'Add\nCustomer',QDPalette.success500),
      _QuickActionDef(Icons.receipt_outlined,    'Invoices',     QDPalette.warning500),
      _QuickActionDef(Icons.bar_chart_rounded,   'Reports',      QDPalette.info500),
    ];

    final taps = [
      () => context.push(AppRoutes.newAppointment),
      () => context.go(AppRoutes.customers),
      () => context.go(AppRoutes.billing),
      () => context.go(AppRoutes.reports),
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? QDSpace.x2 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                taps[i]();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: QDPalette.surfaceCard,
                  borderRadius: BorderRadius.circular(QDRadius.card),
                  border: Border.all(color: QDPalette.neutral100),
                  boxShadow: QDShadow.card,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(QDRadius.iconChip),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: QDPalette.neutral500,
                            height: 1.3, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _emptySchedule() {
    return Container(
      padding: const EdgeInsets.all(QDSpace.x6),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: const Center(
        child: Text('No appointments scheduled for today',
            style: TextStyle(color: QDPalette.neutral400, fontSize: 14)),
      ),
    );
  }

  Widget _appointmentCard(AppointmentModel a) {
    final statusColor = _statusColor(a.status);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/business/appointments/${a.appointmentId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: QDSpace.x2),
        decoration: BoxDecoration(
          color: QDPalette.surfaceCard,
          borderRadius: BorderRadius.circular(QDRadius.card),
          border: Border.all(color: QDPalette.neutral100),
          boxShadow: QDShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(QDRadius.card)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                            color: QDPalette.neutral800)),
                    const SizedBox(height: 2),
                    Text(a.serviceName,
                        style: const TextStyle(color: QDPalette.neutral500, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      '${QDDateUtils.formatTime(a.startTime)} · ${a.staffName}',
                      style: const TextStyle(color: QDPalette.neutral400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: QDStatusChip.fromStatus(a.status),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionDef {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickActionDef(this.icon, this.label, this.color);
}
