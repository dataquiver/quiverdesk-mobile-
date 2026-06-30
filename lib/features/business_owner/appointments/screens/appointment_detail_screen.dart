import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/design_system/design_system.dart';
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
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
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
      final data = await _repo.getAppointmentDetail(
          _tenantId!, widget.appointmentId);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_tenantId == null || _data == null) return;
    setState(() => _updating = true);
    try {
      await _repo.updateAppointmentStatus(
          _tenantId!, widget.appointmentId, newStatus);
      if (mounted) {
        setState(() {
          _data = _data!.copyWith(status: newStatus);
          _updating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: QDPalette.success500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              backgroundColor: QDPalette.error500),
        );
      }
    }
  }

  void _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
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
        title: const Text('Appointment Details'),
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: QDPalette.primary500),
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
      padding: const EdgeInsets.all(QDSpace.screenPad),
      children: [
        // Status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(QDRadius.card),
            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                a.status.replaceAll('_', ' '),
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
              const Spacer(),
              Text(
                QDDateUtils.relativeTime(a.appointmentDate, a.startTime),
                style: const TextStyle(
                    color: QDPalette.neutral400, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: QDSpace.cardGap),

        // Appointment info
        _section('Appointment Info', [
          _row(Icons.calendar_today_outlined, 'Date',
              QDDateUtils.formatDate(a.appointmentDate)),
          _divider(),
          _row(Icons.access_time_outlined, 'Time',
              '${QDDateUtils.formatTime(a.startTime)}${a.endTime != null ? ' – ${QDDateUtils.formatTime(a.endTime!)}' : ''}'),
          _divider(),
          _row(Icons.spa_outlined, 'Service', a.serviceName),
          _divider(),
          _row(Icons.person_outline_rounded, 'Staff', a.staffName),
          if (a.durationMinutes != null) ...[
            _divider(),
            _row(Icons.timer_outlined, 'Duration', '${a.durationMinutes} min'),
          ],
          if (a.servicePrice != null) ...[
            _divider(),
            _row(Icons.currency_rupee_rounded, 'Price',
                QDCurrency.format(a.servicePrice!)),
          ],
        ]),
        const SizedBox(height: QDSpace.cardGap),

        // Customer
        _section('Customer', [
          _row(Icons.person_outlined, 'Name', a.customerName),
          if (a.customerPhone != null) ...[
            _divider(),
            _rowWithAction(
              Icons.phone_outlined,
              'Phone',
              a.customerPhone!,
              actionIcon: Icons.call_rounded,
              onAction: () => _call(a.customerPhone!),
            ),
          ],
        ]),

        if (a.notes != null && a.notes!.isNotEmpty) ...[
          const SizedBox(height: QDSpace.cardGap),
          _section('Notes', [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: QDSpace.screenPad, vertical: 10),
              child: Text(a.notes!,
                  style: const TextStyle(
                      color: QDPalette.neutral500,
                      fontSize: 14,
                      height: 1.5)),
            ),
          ]),
        ],

        if (a.rating != null) ...[
          const SizedBox(height: QDSpace.cardGap),
          _section('Rating', [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: QDSpace.screenPad, vertical: 10),
              child: Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < a.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: QDPalette.warning500,
                    size: 24,
                  ),
                ),
              ),
            ),
          ]),
        ],

        // Status update
        if (nextStatuses.isNotEmpty) ...[
          const SizedBox(height: QDSpace.sectionGap),
          const Text('Update Status',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: QDPalette.neutral800)),
          const SizedBox(height: QDSpace.cardGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nextStatuses.map((s) {
              final color = _statusColor(s);
              return ElevatedButton(
                onPressed: _updating ? null : () => _updateStatus(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(QDRadius.sm)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: Text(s.replaceAll('_', ' ')),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: QDSpace.x6),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                QDSpace.screenPad, 12, QDSpace.screenPad, 8),
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: QDPalette.neutral400,
                    fontSize: 11,
                    letterSpacing: 0.5)),
          ),
          Container(height: 1, color: QDPalette.neutral100),
          ...children,
        ],
      ),
    );
  }

  Widget _divider() => Container(
      margin: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad),
      height: 1,
      color: QDPalette.neutral50);

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: QDSpace.screenPad, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: QDPalette.neutral300),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: QDPalette.neutral400, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: QDPalette.neutral800)),
          ),
        ],
      ),
    );
  }

  Widget _rowWithAction(
    IconData icon,
    String label,
    String value, {
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: QDSpace.screenPad, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: QDPalette.neutral300),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: QDPalette.neutral400, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: QDPalette.neutral800)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: QDPalette.successBg,
                borderRadius: BorderRadius.circular(QDRadius.xs),
              ),
              child: Icon(actionIcon, size: 16, color: QDPalette.success500),
            ),
          ),
        ],
      ),
    );
  }
}
