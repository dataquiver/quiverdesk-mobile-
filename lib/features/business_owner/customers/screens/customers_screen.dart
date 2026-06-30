import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';
import '../../../../app/routes.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repo = BusinessRepository();
  final _searchCtrl = TextEditingController();
  List<CustomerModel> _items = [];
  bool _isLoading = true;
  String? _error;
  int? _tenantId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final idStr = await TokenStorage.getBusinessId();
    _tenantId = idStr != null ? int.tryParse(idStr) : null;
    await _load();
  }

  Future<void> _load({String? search}) async {
    if (_tenantId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await _repo.getCustomers(_tenantId!, search: search);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _showAddSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCustomerSheet(tenantId: _tenantId!),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      floatingActionButton: _tenantId != null
          ? FloatingActionButton(
              onPressed: _showAddSheet,
              backgroundColor: QDPalette.primary600,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add_rounded),
            )
          : null,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: QDPalette.surfaceCard,
            padding: const EdgeInsets.fromLTRB(
                QDSpace.screenPad, 8, QDSpace.screenPad, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (v) => _load(search: v.trim()),
              onChanged: (v) {
                setState(() {});
                if (v.isEmpty) _load();
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          Container(
            color: QDPalette.surfaceCard,
            padding: const EdgeInsets.symmetric(
                horizontal: QDSpace.screenPad, vertical: 8),
            child: Row(
              children: [
                Text('${_items.length} customers',
                    style: const TextStyle(
                        color: QDPalette.neutral400, fontSize: 13)),
              ],
            ),
          ),
          Container(height: 1, color: QDPalette.neutral100),

          Expanded(
            child: _isLoading
                ? const QDLoading()
                : _error != null
                    ? QDError(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? _emptyWithCTA()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: QDPalette.primary500,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(QDSpace.screenPad),
                              itemCount: _items.length,
                              itemBuilder: (_, i) => _card(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _emptyWithCTA() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 56, color: QDPalette.neutral200),
          const SizedBox(height: 16),
          const Text('No customers yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: QDPalette.neutral600)),
          const SizedBox(height: 6),
          const Text('Tap + to add your first customer',
              style: TextStyle(color: QDPalette.neutral400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _card(CustomerModel c) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/business/customers/${c.personId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: QDSpace.x2),
        padding: const EdgeInsets.all(QDSpace.cardPad),
        decoration: BoxDecoration(
          color: QDPalette.surfaceCard,
          borderRadius: BorderRadius.circular(QDRadius.card),
          border: Border.all(color: QDPalette.neutral100),
          boxShadow: QDShadow.card,
        ),
        child: Row(
          children: [
            QDAvatar(name: c.fullName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: QDPalette.neutral800)),
                  const SizedBox(height: 2),
                  if (c.mobileNumber != null)
                    Text(c.mobileNumber!,
                        style: const TextStyle(
                            color: QDPalette.neutral500, fontSize: 13)),
                  if (c.lastVisitDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last visit: ${c.lastVisitDate!.day}/${c.lastVisitDate!.month}/${c.lastVisitDate!.year}',
                      style: const TextStyle(
                          color: QDPalette.neutral400, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (c.totalVisits != null)
                  Text(
                    '${c.totalVisits} visits',
                    style: const TextStyle(
                        color: QDPalette.primary600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                if (c.totalSpent != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${c.totalSpent!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: QDPalette.success500,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 2),
                const Icon(Icons.chevron_right_rounded,
                    color: QDPalette.neutral300, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Customer Sheet ─────────────────────────────────────────────────────────

class _AddCustomerSheet extends StatefulWidget {
  final int tenantId;
  const _AddCustomerSheet({required this.tenantId});

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _repo = BusinessRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final parts = _nameCtrl.text.trim().split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
      await _repo.createCustomer(widget.tenantId, {
        'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        'mobileNumber': _mobileCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
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
                  // Handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: QDPalette.neutral200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('New Customer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: QDPalette.neutral900)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
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
                      labelText: 'Mobile Number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Mobile required' : null,
                  ),
                  const SizedBox(height: QDSpace.x3),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      prefixIcon: Icon(Icons.email_outlined),
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
                      label: Text(_saving ? 'Saving...' : 'Add Customer'),
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
