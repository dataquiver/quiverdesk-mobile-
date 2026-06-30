import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repo = BusinessRepository();
  List<Map<String, dynamic>>? _items;
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
      final data = await _repo.getInventory(_tenantId!);
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Inventory')),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : (_items?.isEmpty ?? true)
                  ? const QDEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No inventory items',
                      subtitle: 'Your inventory will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ItemCard(item: _items![i]),
                      ),
                    ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final qty = (item['quantity'] as num?)?.toInt() ?? 0;
    final reorder = (item['reorderLevel'] as num?)?.toInt() ?? 0;
    final isLow = qty <= reorder;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLow ? QDColors.warning : QDColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (isLow ? QDColors.warning : QDColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: isLow ? QDColors.warning : QDColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['itemName'] as String? ?? item['name'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${item['unit'] ?? ''} · Reorder at $reorder',
                    style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$qty', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              if (isLow)
                const Text('LOW', style: TextStyle(
                    color: QDColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
