import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/themes.dart';
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
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
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
        title: const Text('My Appointments'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month_outlined), onPressed: _pickDate),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: QDColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: QDColors.primary),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    QDDateUtils.dayLabel(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: QDColors.primary, fontSize: 14),
                  ),
                ),
                const Spacer(),
                Text('${_items.length} appointments',
                    style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
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
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
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
    final sc = _statusColor(a.status);
    return GestureDetector(
      onTap: () => context.push('/staff/appointments/${a.appointmentId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: QDColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QDColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: sc,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
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
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(a.serviceName,
                              style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(QDDateUtils.formatTime(a.startTime),
                              style: const TextStyle(
                                  color: QDColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(a.status.replaceAll('_', ' '),
                              style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                        if (a.durationMinutes != null) ...[
                          const SizedBox(height: 4),
                          Text('${a.durationMinutes} min',
                              style: const TextStyle(color: QDColors.textHint, fontSize: 12)),
                        ],
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: QDColors.textHint, size: 18),
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
