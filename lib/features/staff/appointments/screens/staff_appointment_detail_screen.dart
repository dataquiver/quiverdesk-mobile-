import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/staff_repository.dart';

class StaffAppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  const StaffAppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<StaffAppointmentDetailScreen> createState() => _StaffAppointmentDetailScreenState();
}

class _StaffAppointmentDetailScreenState extends State<StaffAppointmentDetailScreen> {
  final _repo = StaffRepository();
  AppointmentModel? _data;
  bool _isLoading = true;
  String? _error;
  bool _updating = false;
  int? _tenantId;

  static const _transitions = <String, List<String>>{
    'SCHEDULED': ['CONFIRMED'],
    'CONFIRMED': ['IN_PROGRESS'],
    'IN_PROGRESS': ['COMPLETED'],
    'COMPLETED': [],
    'CANCELLED': [],
  };

  static const _actionLabels = <String, String>{
    'CONFIRMED': 'Confirm Appointment',
    'IN_PROGRESS': 'Start Service',
    'COMPLETED': 'Mark as Completed',
  };

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
      final data = await _repo.getAppointmentDetail(_tenantId!, widget.appointmentId);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_tenantId == null || _data == null) return;
    setState(() => _updating = true);
    try {
      await _repo.updateAppointmentStatus(_tenantId!, widget.appointmentId, newStatus);
      if (mounted) setState(() { _data = _data!.copyWith(status: newStatus); _updating = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: QDColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: QDColors.error,
        ));
      }
    }
  }

  void _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
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
        title: const Text('Appointment Details'),
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _data!;
    final sc = _statusColor(a.status);
    final nextStatuses = _transitions[a.status] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sc.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: sc, size: 10),
              const SizedBox(width: 8),
              Text(a.status.replaceAll('_', ' '),
                  style: TextStyle(color: sc, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text(QDDateUtils.relativeTime(a.appointmentDate, a.startTime),
                  style: const TextStyle(color: QDColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Customer card
        _section('Customer', [
          _row(Icons.person_outline, 'Name', a.customerName),
          if (a.customerPhone != null) _phoneRow(a.customerPhone!),
        ]),
        const SizedBox(height: 12),

        // Service card
        _section('Service Details', [
          _row(Icons.spa_outlined, 'Service', a.serviceName),
          _row(Icons.calendar_today_outlined, 'Date', QDDateUtils.formatDate(a.appointmentDate)),
          _row(Icons.access_time_outlined, 'Time', QDDateUtils.formatTime(a.startTime)),
          if (a.durationMinutes != null)
            _row(Icons.timer_outlined, 'Duration', '${a.durationMinutes} min'),
        ]),

        if (a.notes != null && a.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section('Notes', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(a.notes!, style: const TextStyle(color: QDColors.textSecondary, fontSize: 14)),
            ),
          ]),
        ],

        // Action buttons
        if (nextStatuses.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...nextStatuses.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton.icon(
              onPressed: _updating ? null : () => _updateStatus(s),
              icon: Icon(_icon(s), size: 20),
              label: Text(_actionLabels[s] ?? s),
              style: ElevatedButton.styleFrom(
                backgroundColor: _statusColor(s),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  IconData _icon(String s) => switch (s) {
    'CONFIRMED' => Icons.check_circle_outline,
    'IN_PROGRESS' => Icons.play_circle_outline,
    'COMPLETED' => Icons.task_alt,
    _ => Icons.update,
  };

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: QDColors.textSecondary, fontSize: 12)),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: QDColors.textHint),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: QDColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _phoneRow(String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 18, color: QDColors.textHint),
          const SizedBox(width: 10),
          const Text('Phone', style: TextStyle(color: QDColors.textSecondary, fontSize: 13)),
          const Spacer(),
          GestureDetector(
            onTap: () => _call(phone),
            child: Row(
              children: [
                Text(phone,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: QDColors.primary)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: QDColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.call, size: 14, color: QDColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
