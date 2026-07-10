import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  StaffMemberModel? _selectedStaff;   // null = any available staff
  DateTime _selectedDate = DateTime.now();

  // Slot picker — the availability engine decides what is bookable
  Map<String, dynamic>? _slotsData;
  bool _slotsLoading = false;
  String? _selectedSlotStart;
  String? _selectedSlotEnd;

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

  String get _dateIso =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _loadSlots() async {
    if (_tenantId == null || _selectedService == null) return;
    setState(() {
      _slotsLoading = true;
      _slotsData = null;
      _selectedSlotStart = null;
      _selectedSlotEnd = null;
    });
    try {
      final data = await _repo.getAvailableSlots(_tenantId!,
          date: _dateIso,
          serviceId: _selectedService!.serviceId,
          staffId: _selectedStaff?.personTenantRoleId);
      if (mounted) setState(() { _slotsData = data; _slotsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  void _selectDate(DateTime d) {
    setState(() => _selectedDate = d);
    _loadSlots();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer and service')),
      );
      return;
    }
    if (_selectedSlotStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an available time slot')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.createAppointment(_tenantId!, {
        'customerPersonId': _selectedCustomer!.personId,
        // null = backend auto-assigns the least-loaded available staff
        'assignedToPersonTenantRoleId': _selectedStaff?.personTenantRoleId,
        'services': [{'serviceId': _selectedService!.serviceId, 'quantity': 1}],
        'appointmentDate': _dateIso,
        'startTime': '$_selectedSlotStart:00',
        'endTime': '$_selectedSlotEnd:00',
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked!')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.response?.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This slot was just taken! Showing updated availability.'),
          backgroundColor: QDPalette.warning500,
        ));
        _loadSlots();
      } else {
        final msg = e.response?.data is Map
            ? (e.response!.data['message'] as String? ?? 'Booking failed.')
            : 'Booking failed. Check your connection.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: QDPalette.error500),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking failed. Please try again.'),
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
                        onChanged: (v) {
                          setState(() => _selectedService = v);
                          _loadSlots();
                        },
                      ),
                      const SizedBox(height: QDSpace.x4),

                      _label('Staff'),
                      _dropdown<StaffMemberModel?>(
                        hint: 'Any available staff',
                        value: _selectedStaff,
                        items: [null, ..._staff],
                        display: (s) => s?.fullName ?? 'Any available staff',
                        onChanged: (v) {
                          setState(() => _selectedStaff = v);
                          _loadSlots();
                        },
                      ),
                      const SizedBox(height: QDSpace.x4),

                      if (_selectedService != null) ...[
                        _label('Pick a date *'),
                        _dateStrip(),
                        const SizedBox(height: QDSpace.x4),
                        _label('Pick a time *'),
                        _slotGrid(),
                        const SizedBox(height: QDSpace.x4),
                      ],

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

  /// Horizontal strip of the next 14 days.
  Widget _dateStrip() {
    final today = DateTime.now();
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = DateTime(today.year, today.month, today.day).add(Duration(days: i));
          final selected = d.year == _selectedDate.year &&
              d.month == _selectedDate.month && d.day == _selectedDate.day;
          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final label = i == 0 ? 'Today' : i == 1 ? 'Tmrw' : days[d.weekday - 1];
          return GestureDetector(
            onTap: () => _selectDate(d),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: selected ? QDPalette.primary50 : QDPalette.surfaceCard,
                borderRadius: BorderRadius.circular(QDRadius.md),
                border: Border.all(
                    color: selected ? QDPalette.primary500 : QDPalette.neutral200,
                    width: selected ? 1.5 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: selected ? QDPalette.primary600 : QDPalette.neutral400)),
                  const SizedBox(height: 2),
                  Text('${d.day}',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                          color: selected ? QDPalette.primary600 : QDPalette.neutral800)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Grid of engine-approved time slots grouped by period.
  Widget _slotGrid() {
    if (_slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: QDPalette.primary500)),
      );
    }
    final data = _slotsData;
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Select a service to see available times.',
            style: TextStyle(fontSize: 13, color: QDPalette.neutral400)),
      );
    }
    if (data['isBusinessOpen'] != true) {
      return _slotNote(data['closedReason'] as String? ?? 'Business is closed on this day.');
    }
    final slots = (data['slots'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final available = slots.where((s) => s['isAvailable'] == true).length;
    if (available == 0) {
      final next = data['nextAvailableDate'] as String?;
      return _slotNote(next != null
          ? 'No slots on this day. Next available: $next'
          : 'No slots available on this day.');
    }

    Widget period(String name, bool Function(int hour) match) {
      final group = slots.where((s) {
        final hour = int.tryParse((s['startTime'] as String).split(':').first) ?? 0;
        return match(hour);
      }).toList();
      if (group.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: QDPalette.neutral400, letterSpacing: .5)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.map((s) {
              final start = s['startTime'] as String;
              final ok = s['isAvailable'] == true;
              final selected = _selectedSlotStart == start;
              return GestureDetector(
                onTap: ok
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedSlotStart = start;
                          _selectedSlotEnd = s['endTime'] as String;
                        });
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? QDPalette.primary500
                        : ok ? QDPalette.surfaceCard : QDPalette.neutral100,
                    borderRadius: BorderRadius.circular(QDRadius.sm),
                    border: Border.all(
                        color: selected
                            ? QDPalette.primary500
                            : ok ? QDPalette.success500 : QDPalette.neutral200),
                  ),
                  child: Text(
                    _format12h(start),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : ok ? QDPalette.neutral800 : QDPalette.neutral400,
                      decoration: ok ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        period('MORNING', (h) => h < 12),
        period('AFTERNOON', (h) => h >= 12 && h < 17),
        period('EVENING', (h) => h >= 17),
      ],
    );
  }

  Widget _slotNote(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QDPalette.warningBg,
          borderRadius: BorderRadius.circular(QDRadius.md),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: QDPalette.warning500,
                fontWeight: FontWeight.w600)),
      );

  static String _format12h(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display:$m $period';
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
