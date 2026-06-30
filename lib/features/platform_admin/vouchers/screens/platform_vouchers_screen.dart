import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/models/platform_models.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../repository/platform_repository.dart';

class PlatformVouchersScreen extends StatefulWidget {
  const PlatformVouchersScreen({super.key});

  @override
  State<PlatformVouchersScreen> createState() => _PlatformVouchersScreenState();
}

class _PlatformVouchersScreenState extends State<PlatformVouchersScreen> {
  final _repo = PlatformRepository();
  List<PlatformVoucherModel> _vouchers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final vouchers = await _repo.getVouchers();
      if (mounted) setState(() { _vouchers = vouchers; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggle(PlatformVoucherModel v) async {
    try {
      if (v.isActive) {
        await _repo.deactivateVoucher(v.platformVoucherId);
      } else {
        await _repo.activateVoucher(v.platformVoucherId);
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showUsages(PlatformVoucherModel v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _UsagesSheet(voucher: v, repo: _repo),
    );
  }

  void _showCreateForm() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String voucherType = 'PERCENT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(builder: (ctx, setSt) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Voucher Code')),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: voucherType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['PERCENT', 'FLAT', 'TRIAL_EXTENSION', 'UPGRADE_PROMO']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setSt(() => voucherType = v ?? voucherType),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: voucherType == 'PERCENT' ? 'Discount %' : 'Discount Amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Usage Limit (optional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;
                  try {
                    await _repo.createVoucher({
                      'code': codeCtrl.text.trim(),
                      'name': nameCtrl.text.trim(),
                      'voucherType': voucherType,
                      'discountValue': double.tryParse(valueCtrl.text) ?? 0,
                      if (limitCtrl.text.isNotEmpty) 'usageLimit': int.tryParse(limitCtrl.text),
                    });
                    Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Create Voucher'),
              ),
            ],
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: const Text('Vouchers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateForm,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _vouchers.isEmpty
                  ? const QDEmptyState(title: 'No Vouchers', subtitle: 'No vouchers found.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vouchers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _VoucherCard(
                          voucher: _vouchers[i],
                          onToggle: () => _toggle(_vouchers[i]),
                          onViewUsages: () => _showUsages(_vouchers[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final PlatformVoucherModel voucher;
  final VoidCallback onToggle;
  final VoidCallback onViewUsages;
  const _VoucherCard({required this.voucher, required this.onToggle, required this.onViewUsages});

  @override
  Widget build(BuildContext context) {
    final v = voucher;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: QDColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(v.code,
                                style: const TextStyle(
                                    color: QDColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: v.isActive ? QDColors.successLight : QDColors.divider,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              v.isActive ? 'Active' : 'Off',
                              style: TextStyle(
                                color: v.isActive ? QDColors.success : QDColors.textHint,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(v.isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: v.isActive ? QDColors.success : QDColors.textHint, size: 32),
                  onPressed: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                    label: _typeLabel(v.voucherType),
                    value: v.voucherType == 'PERCENT'
                        ? '${v.discountValue.toStringAsFixed(0)}%'
                        : QDCurrency.format(v.discountValue)),
                const SizedBox(width: 10),
                _InfoChip(
                  label: 'Used',
                  value: v.usageLimit != null
                      ? '${v.usageCount}/${v.usageLimit}'
                      : '${v.usageCount}',
                ),
                const SizedBox(width: 10),
                if (v.revenueImpact > 0)
                  _InfoChip(label: 'Impact', value: QDCurrency.format(v.revenueImpact)),
              ],
            ),
            if (v.validFrom != null || v.validTo != null) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (v.validFrom != null) 'From: ${QDDateUtils.formatDate(v.validFrom!)}',
                  if (v.validTo != null) 'To: ${QDDateUtils.formatDate(v.validTo!)}',
                ].join('  '),
                style: const TextStyle(fontSize: 12, color: QDColors.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: onViewUsages,
              child: const Text('View Usages'),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'PERCENT': return '% Off';
      case 'FLAT': return 'Flat Off';
      case 'TRIAL_EXTENSION': return 'Trial';
      case 'UPGRADE_PROMO': return 'Promo';
      default: return t;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: QDColors.textHint)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _UsagesSheet extends StatefulWidget {
  final PlatformVoucherModel voucher;
  final PlatformRepository repo;
  const _UsagesSheet({required this.voucher, required this.repo});

  @override
  State<_UsagesSheet> createState() => _UsagesSheetState();
}

class _UsagesSheetState extends State<_UsagesSheet> {
  List<VoucherUsageModel> _usages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final usages = await widget.repo.getVoucherUsages(widget.voucher.platformVoucherId);
    if (mounted) setState(() { _usages = usages; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usages — ${widget.voucher.code}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_usages.isEmpty)
              const Text('No usages recorded', style: TextStyle(color: QDColors.textSecondary))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _usages.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final u = _usages[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(u.businessName),
                      subtitle: Text(QDDateUtils.formatDate(u.usedOn)),
                      trailing: Text(QDCurrency.format(u.discountApplied),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: QDColors.error)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
