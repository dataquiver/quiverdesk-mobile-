import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/staff_member_model.dart';
import '../../../../core/widgets/qd_button.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _repo = BusinessRepository();
  List<StaffMemberModel>? _staff;
  bool _loading = true;
  String? _error;
  int? _tenantId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = await TokenStorage.getBusinessId();
    _tenantId = id != null ? int.tryParse(id) : null;
    await _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getStaff(_tenantId!);
      if (mounted) setState(() { _staff = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QDColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddStaffSheet(tenantId: _tenantId!, repo: _repo, onSaved: _load),
    );
  }

  static const _roleColors = {
    'STYLIST': QDColors.primary,
    'RECEPTIONIST': QDColors.secondary,
    'STAFF': QDColors.warning,
    'ASSISTANT': QDColors.textSecondary,
    'BUSINESS_OWNER': QDColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton(
        onPressed: _tenantId != null ? _showAddSheet : null,
        backgroundColor: QDColors.primary,
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : (_staff?.isEmpty ?? true)
                  ? const QDEmptyState(
                      icon: Icons.group_outlined,
                      title: 'No staff members',
                      subtitle: 'Add your first staff member',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _staff!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = _staff![i];
                          final color = _roleColors[s.roleCode] ?? QDColors.textSecondary;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: QDColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: QDColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.15),
                                  child: Text(s.initials,
                                      style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.fullName,
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(s.mobileNumber ?? s.email ?? '',
                                          style: const TextStyle(
                                              color: QDColors.textSecondary, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(s.roleName.isNotEmpty ? s.roleName : s.roleCode,
                                      style: TextStyle(
                                          fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _AddStaffSheet extends StatefulWidget {
  final int tenantId;
  final BusinessRepository repo;
  final VoidCallback onSaved;
  const _AddStaffSheet({required this.tenantId, required this.repo, required this.onSaved});

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  String _role = 'STYLIST';
  bool _loading = false;

  static const _roles = ['STYLIST', 'RECEPTIONIST', 'STAFF', 'ASSISTANT', 'DOCTOR'];

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await widget.repo.addStaff(widget.tenantId, {
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'mobileNumber': _mobile.text.trim(),
        'roleCode': _role,
        'password': 'Welcome@123',
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: QDColors.error),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Staff Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _field(_name, 'Full Name', required: true),
            _field(_email, 'Email', keyboardType: TextInputType.emailAddress, required: true),
            _field(_mobile, 'Mobile Number', keyboardType: TextInputType.phone),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 8),
            const Text('Default password: Welcome@123',
                style: TextStyle(fontSize: 12, color: QDColors.textSecondary)),
            const SizedBox(height: 20),
            QDButton(label: 'Add Staff', isLoading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboardType, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: required ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null : null,
        ),
      );

  @override
  void dispose() { _name.dispose(); _email.dispose(); _mobile.dispose(); super.dispose(); }
}
