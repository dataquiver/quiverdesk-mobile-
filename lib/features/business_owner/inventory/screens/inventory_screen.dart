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

  Future<void> _showAddSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddInventorySheet(tenantId: _tenantId!),
    );
    if (created == true) _load();
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
      floatingActionButton: _tenantId != null
          ? FloatingActionButton(
              onPressed: _showAddSheet,
              backgroundColor: QDPalette.primary600,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
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

// ── Add Inventory Sheet ────────────────────────────────────────────────────────

class _AddInventorySheet extends StatefulWidget {
  final int tenantId;
  const _AddInventorySheet({required this.tenantId});

  @override
  State<_AddInventorySheet> createState() => _AddInventorySheetState();
}

class _AddInventorySheetState extends State<_AddInventorySheet> {
  final _repo = BusinessRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _reorderCtrl = TextEditingController(text: '5');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _qtyCtrl.dispose();
    _reorderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _repo.createInventoryItem(widget.tenantId, {
        'itemName': _nameCtrl.text.trim(),
        'unit': _unitCtrl.text.trim(),
        'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
        'reorderLevel': int.tryParse(_reorderCtrl.text) ?? 5,
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
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: QDPalette.neutral200, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Add Inventory Item',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: QDPalette.neutral900)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: QDSpace.x3),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitCtrl,
                          decoration: const InputDecoration(labelText: 'Unit (e.g. ml, pcs)'),
                        ),
                      ),
                      const SizedBox(width: QDSpace.x3),
                      Expanded(
                        child: TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          validator: (v) => int.tryParse(v ?? '') == null ? 'Enter number' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: QDSpace.x3),
                  TextFormField(
                    controller: _reorderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reorder Level',
                      helperText: 'Alert when stock falls to this level',
                    ),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Enter number' : null,
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
                          : const Icon(Icons.add_rounded),
                      label: Text(_saving ? 'Saving...' : 'Add Item'),
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
