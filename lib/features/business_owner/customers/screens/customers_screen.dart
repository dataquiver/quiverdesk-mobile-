import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
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
      backgroundColor: QDPalette.surfaceBackground,
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
                        ? const QDEmptyState(
                            title: 'No customers yet',
                            subtitle:
                                'Customers will appear here once you start adding them.',
                            icon: Icons.people_outline_rounded,
                          )
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
