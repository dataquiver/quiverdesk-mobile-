import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/widgets/qd_empty_state.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: QDColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (v) => _load(search: v.trim()),
              onChanged: (v) {
                if (v.isEmpty) _load();
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${_items.length} customers',
                    style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const QDLoading()
                : _error != null
                    ? QDError(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? const QDEmptyState(
                            title: 'No customers yet',
                            subtitle: 'Customers will appear here once you start adding them.',
                            icon: Icons.people_outline,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _card(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _card(CustomerModel c) {
    return GestureDetector(
      onTap: () => context.push('/business/customers/${c.personId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QDColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QDColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: QDColors.primary.withValues(alpha: 0.1),
              child: Text(
                c.initials,
                style: const TextStyle(
                  color: QDColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  if (c.mobileNumber != null)
                    Text(c.mobileNumber!,
                        style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                  if (c.lastVisitDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last visit: ${c.lastVisitDate!.day}/${c.lastVisitDate!.month}/${c.lastVisitDate!.year}',
                      style: const TextStyle(color: QDColors.textHint, fontSize: 12),
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
                        color: QDColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                if (c.totalSpent != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${c.totalSpent!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: QDColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                const Icon(Icons.chevron_right, color: QDColors.textHint, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
