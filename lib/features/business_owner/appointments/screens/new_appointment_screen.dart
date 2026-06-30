import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
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
      if (mounted) {
        setState(() {
          _loadingData = false;
          _loadError = 'No business context';
        });
      }
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
      if (mounted) {
        setState(() { _loadingData = false; _loadError = e.toString(); });
      }
    }
  }

  Future<void> _addNewCustomer() async {
    if (_tenantId == null) return;
    final created = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickAddCustomerSheet(tenantId: _tenantId!, repo: _repo),
    );
    if (created != null && mounted) {
      setState(() {
        _customers = [created, ..._customers];
        _selectedCustomer = created;
      });
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
    if (_selectedCustomer == null ||
        _selectedService == null ||
        _selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.createAppointment(_tenantId!, {
        'customerPersonId': _selectedCustomer!.personId,
        'assignedToPersonTenantRoleId': _selectedStaff!.personTenantRoleId,
        'services': [{'serviceId': _selectedService!.serviceId, 'quantity': 1}],
        'appointmentDate': _selectedDate.toIso8601String().split('T').first,
        'startTime': _timeStr(_selectedTime),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment created!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              backgroundColor: QDPalette.error500),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('New Appointment')),
      body: _loadingData
          ? const Center(
              child: CircularProgressIndicator(color: QDPalette.primary500))
          : _loadError != null
              ? Center(
                  child: Text(_loadError!,
                      style: const TextStyle(color: QDPalette.error500)))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(QDSpace.screenPad),
                    children: [
                      Row(
                        children: [
                          const Expanded(child: _LabelText('Customer *')),
                          GestureDetector(
                            onTap: _addNewCustomer,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    size: 15, color: QDPalette.primary600),
                                SizedBox(width: 4),
                                Text('New Customer',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: QDPalette.primary600,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _dropdown<CustomerModel>(
                        hint: 'Select customer',
                        value: _selectedCustomer,
                        items: _customers,
                        display: (c) =>
                            '${c.fullName}${c.mobileNumber != null ? " (${c.mobileNumber})" : ""}',
                        onChanged: (v) =>
                            setState(() => _selectedCustomer = v),
                      ),
                      const SizedBox(height: QDSpace.x4),

                      _label('Service *'),
                      _dropdown<ServiceModel>(
                        hint: 'Select service',
                        value: _selectedService,
                        items: _services,
                        display: (s) =>
                            '${s.serviceName} – ₹${s.price.toStringAsFixed(0)}',
                        onChanged: (v) =>
                            setState(() => _selectedService = v),
                      ),
                      const SizedBox(height: QDSpace.x4),

                      _label('Staff *'),
                      _dropdown<StaffMemberModel>(
                        hint: 'Assign staff',
                        value: _selectedStaff,
                        items: _staff,
                        display: (s) => s.fullName,
                        onChanged: (v) => setState(() => _selectedStaff = v),
                      ),
                      const SizedBox(height: QDSpace.x4),

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
                          const SizedBox(width: QDSpace.x3),
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
                      const SizedBox(height: QDSpace.x4),

                      _label('Notes (optional)'),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Any special instructions...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: QDSpace.x6),

                      QDButton(
                        label: 'Book Appointment',
                        isLoading: _submitting,
                        icon: Icons.event_available_rounded,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: QDSpace.x4),
                    ],
                  ),
                ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _LabelText(text),
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
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.input),
        border: Border.all(color: QDPalette.neutral200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(color: QDPalette.neutral400, fontSize: 14)),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(display(e), overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: QDPalette.neutral800)),
                  ))
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
          color: QDPalette.surfaceCard,
          borderRadius: BorderRadius.circular(QDRadius.input),
          border: Border.all(color: QDPalette.neutral200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: QDPalette.primary500),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: QDPalette.neutral800)),
          ],
        ),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String text;
  const _LabelText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: QDPalette.neutral500));
  }
}

// ── Quick Add Customer Sheet (inline in New Appointment) ──────────────────────

class _QuickAddCustomerSheet extends StatefulWidget {
  final int tenantId;
  final BusinessRepository repo;
  const _QuickAddCustomerSheet({required this.tenantId, required this.repo});

  @override
  State<_QuickAddCustomerSheet> createState() => _QuickAddCustomerSheetState();
}

class _QuickAddCustomerSheetState extends State<_QuickAddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final parts = _nameCtrl.text.trim().split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
      final customer = await widget.repo.createCustomer(widget.tenantId, {
        'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        'mobileNumber': _mobileCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, customer);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: QDPalette.error500),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: QDPalette.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(QDRadius.sheet)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(QDSpace.screenPad, 20, QDSpace.screenPad, QDSpace.screenPad),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: QDPalette.neutral200, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Quick Add Customer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: QDPalette.neutral900)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name required' : null,
                  ),
                  const SizedBox(height: QDSpace.x3),
                  TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: QDSpace.x5),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.person_add_rounded),
                      label: Text(_saving ? 'Creating...' : 'Create & Select'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QDPalette.primary600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QDRadius.sm)),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
