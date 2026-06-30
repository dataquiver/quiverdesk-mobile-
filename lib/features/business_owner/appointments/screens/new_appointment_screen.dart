import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/staff_member_model.dart';
import '../../../../core/widgets/qd_button.dart';
import '../../repository/business_repository.dart';

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final _repo = BusinessRepository();
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  int? _tenantId;
  bool _loadingData = true;
  bool _submitting = false;
  String? _loadError;

  List<CustomerModel> _customers = [];
  List<ServiceModel> _services = [];
  List<StaffMemberModel> _staff = [];

  CustomerModel? _selectedCustomer;
  ServiceModel? _selectedService;
  StaffMemberModel? _selectedStaff;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final idStr = await TokenStorage.getBusinessId();
    _tenantId = idStr != null ? int.tryParse(idStr) : null;
    if (_tenantId == null) {
      if (mounted) setState(() { _loadingData = false; _loadError = 'No business context'; });
      return;
    }
    try {
      final results = await Future.wait([
        _repo.getCustomers(_tenantId!),
        _repo.getServices(_tenantId!),
        _repo.getStaff(_tenantId!),
      ]);
      if (mounted) {
        setState(() {
          _customers = results[0] as List<CustomerModel>;
          _services = results[1] as List<ServiceModel>;
          _staff = results[2] as List<StaffMemberModel>;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loadingData = false; _loadError = e.toString(); });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime);
    if (t != null && mounted) setState(() => _selectedTime = t);
  }

  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null || _selectedService == null || _selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: QDColors.error),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.createAppointment(_tenantId!, {
        'customerId': _selectedCustomer!.personId,
        'serviceId': _selectedService!.serviceId,
        'staffId': _selectedStaff!.personId,
        'appointmentDate': _selectedDate.toIso8601String().split('T').first,
        'startTime': _timeStr(_selectedTime),
        'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment created!'),
            backgroundColor: QDColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: QDColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('New Appointment')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: QDColors.primary))
          : _loadError != null
              ? Center(child: Text(_loadError!, style: const TextStyle(color: QDColors.error)))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Customer
                      _label('Customer *'),
                      _dropdown<CustomerModel>(
                        hint: 'Select customer',
                        value: _selectedCustomer,
                        items: _customers,
                        display: (c) => '${c.fullName} ${c.mobileNumber != null ? "(${c.mobileNumber})" : ""}',
                        onChanged: (v) => setState(() => _selectedCustomer = v),
                      ),
                      const SizedBox(height: 16),

                      // Service
                      _label('Service *'),
                      _dropdown<ServiceModel>(
                        hint: 'Select service',
                        value: _selectedService,
                        items: _services,
                        display: (s) => '${s.serviceName} – ₹${s.price.toStringAsFixed(0)}',
                        onChanged: (v) => setState(() => _selectedService = v),
                      ),
                      const SizedBox(height: 16),

                      // Staff
                      _label('Staff *'),
                      _dropdown<StaffMemberModel>(
                        hint: 'Assign staff',
                        value: _selectedStaff,
                        items: _staff,
                        display: (s) => s.fullName,
                        onChanged: (v) => setState(() => _selectedStaff = v),
                      ),
                      const SizedBox(height: 16),

                      // Date + Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Date *'),
                                _dateTile(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  Icons.calendar_today_outlined,
                                  _pickDate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Time *'),
                                _dateTile(
                                  _selectedTime.format(context),
                                  Icons.access_time_outlined,
                                  _pickTime,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      _label('Notes (optional)'),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Any special instructions...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 28),

                      QDButton(
                        label: 'Book Appointment',
                        isLoading: _submitting,
                        icon: Icons.event_available,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: QDColors.textSecondary)),
      );

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) display,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: QDColors.textHint)),
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(display(e), overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateTile(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: QDColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QDColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: QDColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: QDColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
