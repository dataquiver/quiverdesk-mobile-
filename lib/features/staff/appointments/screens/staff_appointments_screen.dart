import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/staff_repository.dart';

class StaffAppointmentsScreen extends StatefulWidget {
  const StaffAppointmentsScreen({super.key});

  @override
  State<StaffAppointmentsScreen> createState() => _StaffAppointmentsScreenState();
}

class _StaffAppointmentsScreenState extends State<StaffAppointmentsScreen> {
  final _repo = StaffRepository();
  List<AppointmentModel> _items = [];
  bool _isLoading = true;
  String? _error;
  int? _tenantId;
  DateTime _selectedDate = DateTime.now();

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
    if (_tenantId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final items = await _repo.getAppointments(_tenantId!, date: dateStr);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null && mounted) {
      setState(() => _selectedDate = d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: QDPalette.surfaceCard,
            padding: const EdgeInsets.symmetric(
                horizontal: QDSpace.screenPad, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: QDPalette.primary500),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    QDDateUtils.dayLabel(_selectedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: QDPalette.primary600,
                        fontSize: 14),
                  ),
                ),
                const Spacer(),
                Text('${_items.length} appointments',
                    style: const TextStyle(
                        color: QDPalette.neutral400, fontSize: 13)),
              ],
            ),
          ),
          Container(height: 1, color: QDPalette.neutral100),
          Expanded(
            child: _isLoading
                ? const QDLoading()
                : _error != null
                    ? QDError(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? const QDEmptyState(
                            title: 'No appointments',
                            subtitle: 'No appointments assigned to you for this date.',
                            icon: Icons.event_busy_outlined,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: QDPalette.primary500,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(QDSpace.screenPad),
                              itemCount: _items.length,
                              itemBuilder: (_, i) => _card(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _card(AppointmentModel a) {
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
              height: 80,
              decoration: BoxDecoration(
                color: QDStatusChip.colorFor(a.status),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(QDRadius.card)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: QDPalette.neutral800)),
                          const SizedBox(height: 3),
                          Text(a.serviceName,
                              style: const TextStyle(
                                  color: QDPalette.neutral500, fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(QDDateUtils.formatTime(a.startTime),
                              style: const TextStyle(
                                  color: QDPalette.primary500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        QDStatusChip.fromStatus(a.status),
                        if (a.durationMinutes != null) ...[
                          const SizedBox(height: 4),
                          Text('${a.durationMinutes} min',
                              style: const TextStyle(
                                  color: QDPalette.neutral400, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: QDPalette.neutral300, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
