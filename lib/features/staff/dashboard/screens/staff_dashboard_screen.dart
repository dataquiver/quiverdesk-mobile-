import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../app/routes.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        backgroundColor: QDPalette.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(QDDateUtils.greetingByTime(),
                style: const TextStyle(
                    fontSize: 12,
                    color: QDPalette.neutral400,
                    fontWeight: FontWeight.w500)),
            const Text('My Day',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: QDPalette.neutral900)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: QDPalette.neutral100),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
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
                  color: QDPalette.primary500,
                  child: ListView(
                    padding: const EdgeInsets.all(QDSpace.screenPad),
                    children: [
                      Text(
                        QDDateUtils.formatDate(DateTime.now()),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: QDPalette.neutral900,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _data?.staffName ?? '',
                        style: const TextStyle(
                            fontSize: 14, color: QDPalette.neutral500),
                      ),
                      const SizedBox(height: QDSpace.x5),

                      // Progress card — indigo gradient
                      Container(
                        padding: const EdgeInsets.all(QDSpace.cardPad),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [QDPalette.primary600, QDPalette.primary800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(QDRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: QDPalette.primary700.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Progress",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_data?.completedToday ?? 0} / ${_data?.totalToday ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_data?.remainingToday ?? 0} remaining',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_data?.totalToday ?? 0) > 0
                                    ? _data!.completedToday / _data!.totalToday
                                    : 0,
                                backgroundColor: Colors.white24,
                                color: Colors.white,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: QDSpace.sectionGap),

                      // Next appointment
                      if (_data?.nextAppointment != null) ...[
                        const Text('Next Up',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: QDPalette.neutral800)),
                        const SizedBox(height: QDSpace.cardGap),
                        _nextCard(_data!.nextAppointment!),
                        const SizedBox(height: QDSpace.sectionGap),
                      ],

                      // Today's appointments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Today's Appointments",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: QDPalette.neutral800)),
                          GestureDetector(
                            onTap: () =>
                                context.go(AppRoutes.staffAppointments),
                            child: const Text('View All',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: QDPalette.primary600,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: QDSpace.cardGap),
                      if (_data?.todayAppointments.isEmpty ?? true)
                        Container(
                          padding: const EdgeInsets.all(QDSpace.x6),
                          decoration: BoxDecoration(
                            color: QDPalette.surfaceCard,
                            borderRadius: BorderRadius.circular(QDRadius.card),
                            border: Border.all(color: QDPalette.neutral100),
                            boxShadow: QDShadow.card,
                          ),
                          child: const Center(
                            child: Text('No appointments today',
                                style: TextStyle(
                                    color: QDPalette.neutral400)),
                          ),
                        )
                      else
                        ...(_data!.todayAppointments.map((a) => _apptCard(a))),
                      const SizedBox(height: QDSpace.screenPad),
                    ],
                  ),
                ),
    );
  }

  Widget _nextCard(AppointmentModel a) {
    return Container(
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.primary300, width: 1.5),
        boxShadow: QDShadow.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: QDPalette.primary50,
                  borderRadius: BorderRadius.circular(QDRadius.xs),
                  border: Border.all(color: QDPalette.primary100),
                ),
                child: const Text('Next',
                    style: TextStyle(
                        color: QDPalette.primary600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(
                QDDateUtils.relativeTime(a.appointmentDate, a.startTime),
                style: const TextStyle(
                    color: QDPalette.primary500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.customerName,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: QDPalette.neutral900,
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text(a.serviceName,
              style: const TextStyle(
                  color: QDPalette.neutral500, fontSize: 14)),
          const SizedBox(height: 4),
          Text(QDDateUtils.formatTime(a.startTime),
              style: const TextStyle(
                  color: QDPalette.primary500,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _apptCard(AppointmentModel a) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/staff/appointments/${a.appointmentId}');
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
              height: 64,
              decoration: BoxDecoration(
                color: QDStatusChip.colorFor(a.status),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(QDRadius.card)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: QDPalette.neutral800)),
                    const SizedBox(height: 2),
                    Text(a.serviceName,
                        style: const TextStyle(
                            color: QDPalette.neutral500, fontSize: 13)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(QDDateUtils.formatTime(a.startTime),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: QDPalette.neutral800)),
                  const SizedBox(height: 4),
                  QDStatusChip.fromStatus(a.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
