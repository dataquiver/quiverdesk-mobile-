import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _repo = BusinessRepository();
  AppointmentModel? _data;
  bool _isLoading = true;
  String? _error;
  bool _updating = false;
  int? _tenantId;

  static const _validTransitions = <String, List<String>>{
    'SCHEDULED': ['CONFIRMED', 'CANCELLED'],
    'CONFIRMED': ['IN_PROGRESS', 'CANCELLED'],
    'IN_PROGRESS': ['COMPLETED', 'CANCELLED'],
    'COMPLETED': [],
    'CANCELLED': [],
    'NO_SHOW': [],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: QDColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: QDColors.error),
        );
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
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
    final statusColor = _statusColor(a.status);
    final nextStatuses = _validTransitions[a.status] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: statusColor, size: 10),
              const SizedBox(width: 8),
              Text(
                a.status.replaceAll('_', ' '),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Text(
                QDDateUtils.relativeTime(a.appointmentDate, a.startTime),
                style: const TextStyle(color: QDColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Main card
        _section('Appointment Info', [
          _row(Icons.calendar_today_outlined, 'Date', QDDateUtils.formatDate(a.appointmentDate)),
          _row(Icons.access_time_outlined, 'Time',
              '${QDDateUtils.formatTime(a.startTime)}${a.endTime != null ? ' – ${QDDateUtils.formatTime(a.endTime!)}' : ''}'),
          _row(Icons.spa_outlined, 'Service', a.serviceName),
          _row(Icons.person_outline, 'Staff', a.staffName),
          if (a.durationMinutes != null)
            _row(Icons.timer_outlined, 'Duration', '${a.durationMinutes} min'),
          if (a.servicePrice != null)
            _row(Icons.currency_rupee, 'Price', QDCurrency.format(a.servicePrice!)),
        ]),
        const SizedBox(height: 12),

        // Customer card
        _section('Customer', [
          _row(Icons.person_outlined, 'Name', a.customerName),
          if (a.customerPhone != null) ...[
            _rowWithAction(
              Icons.phone_outlined,
              'Phone',
              a.customerPhone!,
              actionIcon: Icons.call,
              onAction: () => _call(a.customerPhone!),
            ),
          ],
        ]),

        if (a.notes != null && a.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section('Notes', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(a.notes!, style: const TextStyle(color: QDColors.textSecondary, fontSize: 14)),
            ),
          ]),
        ],

        if (a.rating != null) ...[
          const SizedBox(height: 12),
          _section('Rating', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(5, (i) => Icon(
                  i < a.rating! ? Icons.star : Icons.star_outline,
                  color: QDColors.warning,
                  size: 22,
                )),
              ),
            ),
          ]),
        ],

        // Status update buttons
        if (nextStatuses.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Update Status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: nextStatuses.map((s) {
              final color = _statusColor(s);
              return ElevatedButton(
                onPressed: _updating ? null : () => _updateStatus(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(s.replaceAll('_', ' ')),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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

  Widget _rowWithAction(IconData icon, String label, String value,
      {required IconData actionIcon, required VoidCallback onAction}) {
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: QDColors.successLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(actionIcon, size: 16, color: QDColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
