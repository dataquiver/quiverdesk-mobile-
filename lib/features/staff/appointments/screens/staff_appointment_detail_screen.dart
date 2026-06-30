import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/design_system/design_system.dart';
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
  State<StaffAppointmentDetailScreen> createState() =>
      _StaffAppointmentDetailScreenState();
}

class _StaffAppointmentDetailScreenState
    extends State<StaffAppointmentDetailScreen> {
  final _repo = StaffRepository();
  AppointmentModel? _data;
  bool _isLoading = true;
  String? _error;
  bool _updating = false;
  int? _tenantId;

  static const _transitions = <String, List<String>>{
    'BOOKED':     ['CONFIRMED'],
    'SCHEDULED':  ['CONFIRMED'],
    'CONFIRMED':  ['IN_PROGRESS'],
    'IN_PROGRESS':['COMPLETED'],
    'COMPLETED':  [],
    'CANCELLED':  [],
  };

  static const _actionLabels = <String, String>{
    'CONFIRMED':   'Confirm Appointment',
    'IN_PROGRESS': 'Start Service',
    'COMPLETED':   'Mark as Completed',
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
      if (mounted) {
        setState(() {
          _data = _data!.copyWith(status: newStatus);
          _updating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${newStatus.replaceAll('_', ' ')}'),
          backgroundColor: QDPalette.success500,
          behavior: SnackBarBehavior.floating,
        ));
        if (newStatus == 'COMPLETED') _showRatingDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: QDPalette.error500,
        ));
      }
    }
  }

  Future<void> _showRatingDialog() async {
    if (_tenantId == null || _data == null) return;
    int rating = 5;
    final commentCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Customer Rating'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How did it go? Record the customer\'s feedback.',
                  style: TextStyle(color: QDPalette.neutral500, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setInner(() => rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: QDPalette.warning500,
                      size: 36,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Optional comment...',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (_tenantId == null) return;
                try {
                  await _repo.submitFeedback(_tenantId!, widget.appointmentId, {
                    'rating': rating,
                    if (commentCtrl.text.trim().isNotEmpty) 'comment': commentCtrl.text.trim(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback saved'),
                          backgroundColor: QDPalette.success500),
                    );
                  }
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: QDPalette.primary600,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Save Rating'),
            ),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
  }

  void _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

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
                width: 20, height: 20,
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
    final statusColor = QDStatusChip.colorFor(a.status);
    final nextStatuses = _transitions[a.status] ?? [];

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
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: statusColor, shape: BoxShape.circle),
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

        // Customer
        _section('Customer', [
          _row(Icons.person_outline_rounded, 'Name', a.customerName),
          if (a.customerPhone != null) ...[
            _divider(),
            _rowWithCall('Phone', a.customerPhone!),
          ],
        ]),
        const SizedBox(height: QDSpace.cardGap),

        // Service details
        _section('Service Details', [
          _row(Icons.spa_outlined, 'Service', a.serviceName),
          _divider(),
          _row(Icons.calendar_today_outlined, 'Date',
              QDDateUtils.formatDate(a.appointmentDate)),
          _divider(),
          _row(Icons.access_time_outlined, 'Time',
              QDDateUtils.formatTime(a.startTime)),
          if (a.durationMinutes != null) ...[
            _divider(),
            _row(Icons.timer_outlined, 'Duration',
                '${a.durationMinutes} min'),
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
                      color: QDPalette.neutral500, fontSize: 14, height: 1.5)),
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
                    i < a.rating!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: QDPalette.warning500,
                    size: 24,
                  ),
                ),
              ),
            ),
          ]),
        ],

        // Action buttons
        if (nextStatuses.isNotEmpty) ...[
          const SizedBox(height: QDSpace.sectionGap),
          ...nextStatuses.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton.icon(
              onPressed: _updating ? null : () => _updateStatus(s),
              icon: Icon(_icon(s), size: 20),
              label: Text(_actionLabels[s] ?? s),
              style: ElevatedButton.styleFrom(
                backgroundColor: QDStatusChip.colorFor(s),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(QDRadius.sm)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          )),
        ],

        if (a.status == 'COMPLETED') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showRatingDialog,
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Add Customer Rating'),
            style: OutlinedButton.styleFrom(
              foregroundColor: QDPalette.warning500,
              side: const BorderSide(color: QDPalette.warning500),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(QDRadius.sm)),
            ),
          ),
        ],

        const SizedBox(height: QDSpace.x6),
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
              style: const TextStyle(color: QDPalette.neutral400, fontSize: 13)),
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

  Widget _rowWithCall(String label, String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: QDSpace.screenPad, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 18, color: QDPalette.neutral300),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: QDPalette.neutral400, fontSize: 13)),
          const Spacer(),
          Text(phone,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: QDPalette.neutral800)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _call(phone),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: QDPalette.successBg,
                borderRadius: BorderRadius.circular(QDRadius.xs),
              ),
              child: const Icon(Icons.call_rounded,
                  size: 16, color: QDPalette.success500),
            ),
          ),
        ],
      ),
    );
  }
}
