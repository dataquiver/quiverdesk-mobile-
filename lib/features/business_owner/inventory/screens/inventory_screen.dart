import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
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
      backgroundColor: QDPalette.surfaceBackground,
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
                      color: QDPalette.primary500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        itemCount: _items!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: QDSpace.cardGap),
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
    final color = isLow ? QDPalette.warning500 : QDPalette.primary500;
    final bg = isLow ? QDPalette.warningBg : QDPalette.primary50;
    return Container(
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(
            color: isLow ? QDPalette.warning500.withValues(alpha: 0.4) : QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(QDRadius.iconChip),
            ),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['itemName'] as String? ?? item['name'] as String? ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: QDPalette.neutral800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['unit'] ?? ''} · Reorder at $reorder',
                  style: const TextStyle(
                      color: QDPalette.neutral500, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$qty',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: QDPalette.neutral900,
                      letterSpacing: -0.5)),
              if (isLow)
                const Text('LOW',
                    style: TextStyle(
                        color: QDPalette.warning500,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
