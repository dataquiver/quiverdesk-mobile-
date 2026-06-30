import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';

class StaffCustomersScreen extends StatefulWidget {
  const StaffCustomersScreen({super.key});

  @override
  State<StaffCustomersScreen> createState() => _StaffCustomersScreenState();
}

class _StaffCustomersScreenState extends State<StaffCustomersScreen> {
  final _dio = ApiClient.instance;
  List<CustomerModel> _customers = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
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
    final bizId = await TokenStorage.getBusinessId();
    setState(() => _tenantId = bizId != null ? int.tryParse(bizId) : null);
    _load();
  }

  Future<void> _load({String? search}) async {
    if (_tenantId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(
        ApiEndpoints.staffCustomers(_tenantId!),
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'pageSize': 50,
        },
      );
      final body = res.data;
      List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = (body['items'] ?? body['data'] ?? body['customers'] ?? []) as List<dynamic>;
      } else {
        list = [];
      }
      setState(() {
        _customers = list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load())],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onChanged: (v) => _load(search: v),
            ),
          ),
          Expanded(
            child: _loading
                ? const QDLoading()
                : _error != null
                    ? QDError(message: _error!, onRetry: () => _load())
                    : _customers.isEmpty
                        ? const QDEmptyState(title: 'No Customers', subtitle: 'No customers found.')
                        : RefreshIndicator(
                            onRefresh: () => _load(),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _customers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: QDColors.primaryLight,
              child: Text(customer.initials,
                  style: const TextStyle(color: QDColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (customer.mobileNumber != null)
                    Text(customer.mobileNumber!,
                        style: const TextStyle(fontSize: 13, color: QDColors.textSecondary)),
                  if (customer.email != null)
                    Text(customer.email!,
                        style: const TextStyle(fontSize: 12, color: QDColors.textHint)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (customer.totalVisits != null)
                  Text('${customer.totalVisits} visits',
                      style: const TextStyle(fontSize: 12, color: QDColors.textSecondary)),
                if (customer.totalSpent != null)
                  Text(QDCurrency.format(customer.totalSpent!),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: QDColors.success)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
