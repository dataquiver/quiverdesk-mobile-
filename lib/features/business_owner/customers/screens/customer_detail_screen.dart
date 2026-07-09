import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/design_system/design_system.dart';
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
      final customer = await _repo.getCustomerDetail(_tenantId!, widget.customerId);
      // History failing must not take down the whole profile.
      List<AppointmentModel> appointments = [];
      try {
        appointments = await _repo.getCustomerAppointments(_tenantId!, widget.customerId);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _customer = customer;
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load this customer. Pull to retry.';
          _isLoading = false;
        });
      }
    }
  }

  void _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _sms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _whatsApp(String phone, {String? message}) async {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) digits = '91$digits';
    final uri = Uri.parse(
        'https://wa.me/$digits${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _contactActions(CustomerModel c) {
    if (c.mobileNumber == null || c.mobileNumber!.isEmpty) {
      return const SizedBox.shrink();
    }
    final phone = c.mobileNumber!;
    Widget action(IconData icon, String label, Color color, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(QDRadius.card),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: QDPalette.surfaceCard,
              borderRadius: BorderRadius.circular(QDRadius.card),
              border: Border.all(color: QDPalette.neutral100),
              boxShadow: QDShadow.card,
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: QDPalette.neutral700)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          QDSpace.screenPad, QDSpace.x3, QDSpace.screenPad, 0),
      child: Row(
        children: [
          action(Icons.call_rounded, 'Call', QDPalette.success500,
              () => _call(phone)),
          action(Icons.chat_rounded, 'WhatsApp', const Color(0xFF25D366),
              () => _whatsApp(phone, message: 'Hi ${c.fullName}! ')),
          action(Icons.sms_outlined, 'SMS', QDPalette.info500,
              () => _sms(phone)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: Text(_customer?.fullName ?? 'Customer Details'),
      ),
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
          color: QDPalette.surfaceCard,
          padding: const EdgeInsets.all(QDSpace.x5),
          child: Column(
            children: [
              QDAvatar(name: c.fullName, size: 72, radius: QDRadius.md),
              const SizedBox(height: 12),
              Text(c.fullName,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: QDPalette.neutral900,
                      letterSpacing: -0.3)),
              if (c.mobileNumber != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _call(c.mobileNumber!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: QDPalette.successBg,
                      borderRadius: BorderRadius.circular(QDRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_rounded,
                            size: 14, color: QDPalette.success500),
                        const SizedBox(width: 5),
                        Text(c.mobileNumber!,
                            style: const TextStyle(
                                color: QDPalette.success500,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('Visits', '${c.totalVisits ?? 0}', QDPalette.primary500),
                  Container(width: 1, height: 36, color: QDPalette.neutral100),
                  _stat('Total Spent',
                      QDCurrency.compact(c.totalSpent ?? 0), QDPalette.success500),
                  Container(width: 1, height: 36, color: QDPalette.neutral100),
                  _stat(
                    'Last Visit',
                    c.lastVisitDate != null
                        ? '${c.lastVisitDate!.day}/${c.lastVisitDate!.month}'
                        : 'N/A',
                    QDPalette.neutral400,
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: QDPalette.neutral100),

        // Quick contact actions
        _contactActions(c),

        // Info section
        if (c.email != null || c.gender != null || c.dateOfBirth != null || c.notes != null)
          Padding(
            padding: const EdgeInsets.all(QDSpace.screenPad),
            child: Container(
              decoration: BoxDecoration(
                color: QDPalette.surfaceCard,
                borderRadius: BorderRadius.circular(QDRadius.card),
                border: Border.all(color: QDPalette.neutral100),
                boxShadow: QDShadow.card,
              ),
              child: Column(
                children: [
                  if (c.email != null) ...[
                    _infoRow(Icons.email_outlined, 'Email', c.email!),
                    Container(height: 1, color: QDPalette.neutral50),
                  ],
                  if (c.gender != null) ...[
                    _infoRow(Icons.person_outline_rounded, 'Gender', c.gender!),
                    Container(height: 1, color: QDPalette.neutral50),
                  ],
                  if (c.dateOfBirth != null) ...[
                    _infoRow(Icons.cake_outlined, 'Birthday',
                        '${c.dateOfBirth!.day}/${c.dateOfBirth!.month}/${c.dateOfBirth!.year}'),
                    Container(height: 1, color: QDPalette.neutral50),
                  ],
                  if (c.notes != null && c.notes!.isNotEmpty)
                    _infoRow(Icons.notes_rounded, 'Notes', c.notes!),
                ],
              ),
            ),
          ),

        // Appointment history
        Padding(
          padding: const EdgeInsets.fromLTRB(QDSpace.screenPad, 8, QDSpace.screenPad, 8),
          child: Text(
            'Appointment History (${_appointments.length})',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: QDPalette.neutral800),
          ),
        ),
        if (_appointments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(QDSpace.x6),
            child: Center(
              child: Text('No appointment history',
                  style: TextStyle(color: QDPalette.neutral400)),
            ),
          )
        else
          ..._appointments.map((a) {
            return Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: QDSpace.screenPad, vertical: 4),
              padding: const EdgeInsets.all(QDSpace.cardPad),
              decoration: BoxDecoration(
                color: QDPalette.surfaceCard,
                borderRadius: BorderRadius.circular(QDRadius.card),
                border: Border.all(color: QDPalette.neutral100),
                boxShadow: QDShadow.card,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.serviceName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: QDPalette.neutral800)),
                        const SizedBox(height: 3),
                        Text(
                          '${QDDateUtils.formatDate(a.appointmentDate)} · ${QDDateUtils.formatTime(a.startTime)}',
                          style: const TextStyle(
                              color: QDPalette.neutral400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      QDStatusChip.fromStatus(a.status),
                      if (a.servicePrice != null) ...[
                        const SizedBox(height: 4),
                        Text('₹${a.servicePrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: QDPalette.neutral800)),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: QDSpace.x6),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: QDPalette.neutral400)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String text) {
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
            child: Text(text,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: QDPalette.neutral700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
