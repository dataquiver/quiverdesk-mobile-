import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/models/dashboard_model.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/staff_repository.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _repo = StaffRepository();
  StaffDashboardModel? _data;
  bool _isLoading = true;
  String? _error;
  int? _tenantId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final idStr = await TokenStorage.getBusinessId();
    _tenantId = idStr != null ? int.tryParse(idStr) : null;
    await _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) {
      setState(() { _isLoading = false; _error = 'No business context'; });
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _repo.getDayView(_tenantId!);
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
            const Text('My Day', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                      // Date + staff name
                      Text(
                        QDDateUtils.formatDate(DateTime.now()),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: QDColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _data?.staffName ?? '',
                        style: const TextStyle(fontSize: 14, color: QDColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Progress card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: QDColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Progress",
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_data?.completedToday ?? 0} / ${_data?.totalToday ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_data?.remainingToday ?? 0} remaining',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_data?.totalToday ?? 0) > 0
                                    ? (_data!.completedToday) / _data!.totalToday
                                    : 0,
                                backgroundColor: Colors.white24,
                                color: Colors.white,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Next appointment
                      if (_data?.nextAppointment != null) ...[
                        const Text('Next Up',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _nextCard(_data!.nextAppointment!),
                        const SizedBox(height: 20),
                      ],

                      // Today's list
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Today's Appointments",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.staffAppointments),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_data?.todayAppointments.isEmpty ?? true)
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
                        ...(_data!.todayAppointments.map((a) => _apptCard(a))),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _nextCard(AppointmentModel a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: QDColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Next', style: TextStyle(color: QDColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(
                QDDateUtils.relativeTime(a.appointmentDate, a.startTime),
                style: const TextStyle(color: QDColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.customerName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: QDColors.textPrimary)),
          const SizedBox(height: 4),
          Text(a.serviceName, style: const TextStyle(color: QDColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(QDDateUtils.formatTime(a.startTime),
              style: const TextStyle(color: QDColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _apptCard(AppointmentModel a) {
    final sc = _statusColor(a.status);
    return GestureDetector(
      onTap: () => context.push('/staff/appointments/${a.appointmentId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QDColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QDColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: sc,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(a.serviceName, style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(QDDateUtils.formatTime(a.startTime),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: QDColors.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.status.replaceAll('_', ' '),
                      style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: QDColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
