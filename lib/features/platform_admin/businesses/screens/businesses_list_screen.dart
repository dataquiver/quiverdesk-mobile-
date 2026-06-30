import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/themes.dart';
import '../../../../core/models/business_model.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/platform_repository.dart';

class BusinessesListScreen extends StatefulWidget {
  const BusinessesListScreen({super.key});

  @override
  State<BusinessesListScreen> createState() => _BusinessesListScreenState();
}

class _BusinessesListScreenState extends State<BusinessesListScreen> {
  final _repo = PlatformRepository();
  final _searchCtrl = TextEditingController();
  List<BusinessModel> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await _repo.getBusinesses(search: search);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _statusColor(String? s) => switch (s?.toUpperCase()) {
    'ACTIVE' => QDColors.success,
    'TRIAL' => QDColors.warning,
    'EXPIRED' => QDColors.error,
    'SUSPENDED' => QDColors.cancelled,
    _ => QDColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('All Businesses')),
      body: Column(
        children: [
          // Search bar
          Container(
            color: QDColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search businesses...',
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
              onChanged: (v) { if (v.isEmpty) _load(); },
              textInputAction: TextInputAction.search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${_items.length} businesses',
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
                            title: 'No businesses',
                            subtitle: 'No businesses registered on the platform yet.',
                            icon: Icons.business_outlined,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              itemBuilder: (_, i) => _card(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _card(BusinessModel b) {
    final sc = _statusColor(b.subscriptionStatus);
    return GestureDetector(
      onTap: () => context.push('/platform/businesses/${b.tenantId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QDColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QDColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: QDColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  b.businessName.isNotEmpty ? b.businessName[0].toUpperCase() : 'B',
                  style: const TextStyle(
                    color: QDColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.businessName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  if (b.businessType != null)
                    Text(b.businessType!,
                        style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                  if (b.ownerName != null) ...[
                    const SizedBox(height: 2),
                    Text(b.ownerName!,
                        style: const TextStyle(color: QDColors.textHint, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (b.subscriptionStatus != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.subscriptionStatus!,
                      style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 4),
                if (b.subscriptionPlan != null)
                  Text(b.subscriptionPlan!,
                      style: const TextStyle(color: QDColors.textHint, fontSize: 11)),
              ],
            ),
            const Icon(Icons.chevron_right, color: QDColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
