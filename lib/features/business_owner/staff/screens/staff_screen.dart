import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
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

  Future<void> _confirmDelete(StaffMemberModel s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text('Remove ${s.fullName} from this business?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: QDPalette.error500),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || _tenantId == null) return;
    try {
      await _repo.removeStaff(_tenantId!, s.personTenantRoleId);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: QDPalette.error500),
        );
      }
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QDPalette.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(QDRadius.sheet))),
      builder: (_) =>
          _AddStaffSheet(tenantId: _tenantId!, repo: _repo, onSaved: _load),
    );
  }

  Color _roleColor(String code) => switch (code) {
    'STYLIST'        => QDPalette.primary500,
    'RECEPTIONIST'   => QDPalette.info500,
    'STAFF'          => QDPalette.warning500,
    'ASSISTANT'      => QDPalette.neutral400,
    'BUSINESS_OWNER' => QDPalette.success500,
    'DOCTOR'         => QDPalette.error500,
    _                => QDPalette.neutral400,
  };

  Color _roleBg(String code) => switch (code) {
    'STYLIST'        => QDPalette.primary50,
    'RECEPTIONIST'   => QDPalette.infoBg,
    'STAFF'          => QDPalette.warningBg,
    'ASSISTANT'      => QDPalette.neutral50,
    'BUSINESS_OWNER' => QDPalette.successBg,
    'DOCTOR'         => QDPalette.errorBg,
    _                => QDPalette.neutral50,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton(
        onPressed: _tenantId != null ? _showAddSheet : null,
        child: const Icon(Icons.person_add_rounded),
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
                      color: QDPalette.primary500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        itemCount: _staff!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: QDSpace.cardGap),
                        itemBuilder: (_, i) {
                          final s = _staff![i];
                          final color = _roleColor(s.roleCode);
                          final bg = _roleBg(s.roleCode);
                          return Container(
                            padding: const EdgeInsets.all(QDSpace.cardPad),
                            decoration: BoxDecoration(
                              color: QDPalette.surfaceCard,
                              borderRadius:
                                  BorderRadius.circular(QDRadius.card),
                              border: Border.all(color: QDPalette.neutral100),
                              boxShadow: QDShadow.card,
                            ),
                            child: Row(
                              children: [
                                QDAvatar(name: s.fullName, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: QDPalette.neutral800)),
                                      const SizedBox(height: 2),
                                      Text(
                                          s.mobileNumber ?? s.email ?? '',
                                          style: const TextStyle(
                                              color: QDPalette.neutral500,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(
                                        QDRadius.full),
                                  ),
                                  child: Text(
                                    s.roleName.isNotEmpty
                                        ? s.roleName
                                        : s.roleCode,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded,
                                      color: QDPalette.neutral400, size: 20),
                                  onSelected: (v) {
                                    if (v == 'delete') _confirmDelete(s);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.person_remove_outlined,
                                            size: 16,
                                            color: QDPalette.error500),
                                        SizedBox(width: 8),
                                        Text('Remove',
                                            style: TextStyle(
                                                color: QDPalette.error500)),
                                      ]),
                                    ),
                                  ],
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
  const _AddStaffSheet(
      {required this.tenantId, required this.repo, required this.onSaved});

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

  static const _roles = [
    'STYLIST', 'RECEPTIONIST', 'STAFF', 'ASSISTANT', 'DOCTOR'
  ];

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
          SnackBar(content: Text(e.toString()),
              backgroundColor: QDPalette.error500),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          QDSpace.screenPad, QDSpace.x5, QDSpace.screenPad,
          MediaQuery.of(context).viewInsets.bottom + QDSpace.x5),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Staff Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: QDPalette.neutral900)),
            const SizedBox(height: QDSpace.x5),
            _field(_name, 'Full Name', required: true),
            _field(_email, 'Email',
                keyboardType: TextInputType.emailAddress, required: true),
            _field(_mobile, 'Mobile Number',
                keyboardType: TextInputType.phone),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: QDSpace.x2),
            const Text('Default password: Welcome@123',
                style: TextStyle(fontSize: 12, color: QDPalette.neutral400)),
            const SizedBox(height: QDSpace.x5),
            QDButton(
                label: 'Add Staff', isLoading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboardType, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: QDSpace.x3),
        child: TextFormField(
          controller: c,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null
              : null,
        ),
      );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }
}
