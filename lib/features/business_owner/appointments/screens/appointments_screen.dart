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
import '../../repository/business_repository.dart';
import '../../../../app/routes.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _repo = BusinessRepository();
  List<AppointmentModel> _items = [];
  bool _isLoading = true;
  String? _error;
  int? _tenantId;

  String _selectedStatus = 'ALL';
  DateTime _selectedDate = DateTime.now();

  static const _statuses = [
    'ALL', 'SCHEDULED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
  ];

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
      final items = await _repo.getAppointments(
        _tenantId!,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        date: dateStr,
      );
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) {
      setState(() => _selectedDate = d);
      _load();
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
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
            tooltip: 'Pick date',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date strip
          Container(
            color: QDPalette.surfaceCard,
            padding: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: QDPalette.primary500),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    QDDateUtils.dayLabel(_selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: QDPalette.primary500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text('${_items.length} found',
                    style: const TextStyle(
                        color: QDPalette.neutral400, fontSize: 13)),
              ],
            ),
          ),
          Container(height: 1, color: QDPalette.neutral100),

          // Status filter chips
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: QDSpace.screenPad, vertical: 7),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final selected = s == _selectedStatus;
                return FilterChip(
                  label: Text(s == 'ALL' ? 'All' : s.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedStatus = s);
                    _load();
                  },
                  selectedColor: QDPalette.primary100,
                  checkmarkColor: QDPalette.primary600,
                  labelStyle: TextStyle(
                    color: selected ? QDPalette.primary600 : QDPalette.neutral500,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          Container(height: 1, color: QDPalette.neutral100),

          // List
          Expanded(
            child: _isLoading
                ? const QDLoading()
                : _error != null
                    ? QDError(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? QDEmptyState(
                            title: 'No appointments',
                            subtitle:
                                'No appointments found for the selected filters.',
                            icon: Icons.event_busy_outlined,
                            actionLabel: 'New Appointment',
                            onAction: () =>
                                context.push(AppRoutes.newAppointment),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: QDPalette.primary500,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.all(QDSpace.screenPad),
                              itemCount: _items.length,
                              itemBuilder: (_, i) => _card(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.newAppointment);
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _card(AppointmentModel a) {
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
              height: 80,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(QDRadius.card)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(QDSpace.cardPad),
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
                          Text(
                            '${QDDateUtils.formatTime(a.startTime)} · ${a.staffName}',
                            style: const TextStyle(
                                color: QDPalette.neutral400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        QDStatusChip.fromStatus(a.status),
                        if (a.servicePrice != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '₹${a.servicePrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: QDPalette.neutral800,
                                fontSize: 14),
                          ),
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
