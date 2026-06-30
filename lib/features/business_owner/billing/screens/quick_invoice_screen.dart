import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/invoice_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';
import '../../../../app/routes.dart';

class QuickInvoiceScreen extends StatefulWidget {
  const QuickInvoiceScreen({super.key});

  @override
  State<QuickInvoiceScreen> createState() => _QuickInvoiceScreenState();
}

class _QuickInvoiceScreenState extends State<QuickInvoiceScreen> {
  final _repo = BusinessRepository();
  List<InvoiceModel> _items = [];
  bool _isLoading = true;
  String? _error;
  int? _tenantId;
  String _selectedStatus = 'ALL';

  static const _statuses = ['ALL', 'UNPAID', 'PARTIAL', 'PAID'];

  // Summary metrics
  double get _totalRevenue => _items.fold(0, (s, i) => s + i.totalAmount);
  double get _totalPaid => _items.fold(0, (s, i) => s + i.paidAmount);
  double get _totalPending => _items.fold(0, (s, i) => s + i.balance);
  int get _unpaidCount => _items.where((i) => !i.isPaid).length;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final idStr = await TokenStorage.getBusinessId();
    _tenantId = idStr != null ? int.tryParse(idStr) : null;
    await _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await _repo.getInvoices(
        _tenantId!,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      );
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _statusColor(String s) => switch (s.toUpperCase()) {
    'PAID' => QDColors.success,
    'UNPAID' => QDColors.error,
    'PARTIAL' => QDColors.warning,
    _ => QDColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    // Summary cards
                    Container(
                      color: QDColors.surface,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _metric('Total', QDCurrency.compact(_totalRevenue), QDColors.textPrimary),
                          _divider(),
                          _metric('Collected', QDCurrency.compact(_totalPaid), QDColors.success),
                          _divider(),
                          _metric('Pending', QDCurrency.compact(_totalPending), QDColors.error),
                          _divider(),
                          _metric('Unpaid\nCount', '$_unpaidCount', QDColors.warning),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Filter chips
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: _statuses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final s = _statuses[i];
                          final selected = s == _selectedStatus;
                          return FilterChip(
                            label: Text(s == 'ALL' ? 'All' : s),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedStatus = s);
                              _load();
                            },
                            selectedColor: QDColors.primaryLight,
                            labelStyle: TextStyle(
                              color: selected ? QDColors.primary : QDColors.textSecondary,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // List
                    Expanded(
                      child: _items.isEmpty
                          ? const QDEmptyState(
                              title: 'No invoices',
                              subtitle: 'Invoices will appear here after appointments are completed.',
                              icon: Icons.receipt_long_outlined,
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

  Widget _card(InvoiceModel inv) {
    final sc = _statusColor(inv.status);
    return Container(
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
              color: sc.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_outlined, color: sc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '#${inv.invoiceId} · ${QDDateUtils.formatDate(inv.invoiceDate)}',
                  style: const TextStyle(color: QDColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(QDCurrency.format(inv.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: QDColors.textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(inv.status,
                    style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: QDColors.textSecondary, height: 1.2)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: QDColors.divider, margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}
