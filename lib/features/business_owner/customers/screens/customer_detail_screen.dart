import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _repo = BusinessRepository();
  CustomerModel? _customer;
  List<AppointmentModel> _appointments = [];
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
    if (_tenantId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.getCustomerDetail(_tenantId!, widget.customerId),
        _repo.getCustomerAppointments(_tenantId!, widget.customerId),
      ]);
      if (mounted) {
        setState(() {
          _customer = results[0] as CustomerModel;
          _appointments = results[1] as List<AppointmentModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
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
      appBar: AppBar(title: Text(_customer?.fullName ?? 'Customer Details')),
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final c = _customer!;
    return ListView(
      children: [
        // Header
        Container(
          color: QDColors.surface,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: QDColors.primary,
                child: Text(c.initials,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              Text(c.fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: QDColors.textPrimary)),
              if (c.mobileNumber != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _call(c.mobileNumber!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 14, color: QDColors.primary),
                      const SizedBox(width: 4),
                      Text(c.mobileNumber!,
                          style: const TextStyle(color: QDColors.primary, fontWeight: FontWeight.w500, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('Visits', '${c.totalVisits ?? 0}', QDColors.primary),
                  _dividerV(),
                  _stat('Total Spent', QDCurrency.compact(c.totalSpent ?? 0), QDColors.success),
                  _dividerV(),
                  _stat('Last Visit',
                      c.lastVisitDate != null
                          ? '${c.lastVisitDate!.day}/${c.lastVisitDate!.month}'
                          : 'N/A',
                      QDColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Info section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.email != null) ...[
                _infoRow(Icons.email_outlined, c.email!),
                const SizedBox(height: 8),
              ],
              if (c.gender != null) ...[
                _infoRow(Icons.person_outline, c.gender!),
                const SizedBox(height: 8),
              ],
              if (c.dateOfBirth != null) ...[
                _infoRow(Icons.cake_outlined,
                    '${c.dateOfBirth!.day}/${c.dateOfBirth!.month}/${c.dateOfBirth!.year}'),
                const SizedBox(height: 8),
              ],
              if (c.notes != null && c.notes!.isNotEmpty) ...[
                _infoRow(Icons.notes_outlined, c.notes!),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),

        // Appointment history
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Appointment History (${_appointments.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        if (_appointments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No appointment history', style: TextStyle(color: QDColors.textSecondary)),
            ),
          )
        else
          ..._appointments.map((a) {
            final sc = _statusColor(a.status);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: QDColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: QDColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.serviceName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${QDDateUtils.formatDate(a.appointmentDate)} · ${QDDateUtils.formatTime(a.startTime)}',
                          style: const TextStyle(color: QDColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(a.status,
                            style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      if (a.servicePrice != null) ...[
                        const SizedBox(height: 4),
                        Text('₹${a.servicePrice!.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: QDColors.textSecondary)),
      ],
    );
  }

  Widget _dividerV() {
    return Container(width: 1, height: 36, color: QDColors.divider);
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: QDColors.textHint),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: QDColors.textSecondary, fontSize: 14))),
      ],
    );
  }
}
