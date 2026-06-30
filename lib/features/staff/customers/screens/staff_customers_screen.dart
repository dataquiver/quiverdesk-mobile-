import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/staff_repository.dart';

class StaffCustomersScreen extends StatefulWidget {
  const StaffCustomersScreen({super.key});

  @override
  State<StaffCustomersScreen> createState() => _StaffCustomersScreenState();
}

class _StaffCustomersScreenState extends State<StaffCustomersScreen> {
  final _repo = StaffRepository();
  List<CustomerModel> _customers = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  int? _tenantId;
  String _search = '';

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
    final bizId = await TokenStorage.getBusinessId();
    _tenantId = bizId != null ? int.tryParse(bizId) : null;
    await _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await _repo.getCustomers(_tenantId!);
      final all = raw.map((e) => CustomerModel.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _customers = _search.isEmpty
              ? all
              : all.where((c) =>
                  c.fullName.toLowerCase().contains(_search.toLowerCase()) ||
                  (c.mobileNumber?.contains(_search) ?? false)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
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
                          setState(() => _search = '');
                          _load();
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) {
                setState(() => _search = v);
                _load();
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          Container(height: 1, color: QDPalette.neutral100),
          Expanded(
            child: _loading
                ? const QDLoading()
                : _error != null
                    ? QDError(message: _error!, onRetry: _load)
                    : _customers.isEmpty
                        ? const QDEmptyState(
                            title: 'No Customers',
                            subtitle: 'No customers found.',
                            icon: Icons.people_outline_rounded,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: QDPalette.primary500,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(QDSpace.screenPad),
                              itemCount: _customers.length,
                              itemBuilder: (_, i) => _CustomerCard(customer: _customers[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: QDSpace.cardGap),
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Row(
        children: [
          QDAvatar(name: customer.fullName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: QDPalette.neutral800)),
                if (customer.mobileNumber != null)
                  Text(customer.mobileNumber!,
                      style: const TextStyle(
                          color: QDPalette.neutral500, fontSize: 13)),
                if (customer.email != null)
                  Text(customer.email!,
                      style: const TextStyle(
                          color: QDPalette.neutral400, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (customer.totalVisits != null)
                Text('${customer.totalVisits} visits',
                    style: const TextStyle(
                        color: QDPalette.primary600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              if (customer.totalSpent != null)
                Text(QDCurrency.format(customer.totalSpent!),
                    style: const TextStyle(
                        color: QDPalette.success500,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
