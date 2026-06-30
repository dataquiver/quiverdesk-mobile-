import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
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
    'PAID'    => QDPalette.success500,
    'UNPAID'  => QDPalette.error500,
    'PARTIAL' => QDPalette.warning500,
    _         => QDPalette.neutral400,
  };

  Color _statusBg(String s) => switch (s.toUpperCase()) {
    'PAID'    => QDPalette.successBg,
    'UNPAID'  => QDPalette.errorBg,
    'PARTIAL' => QDPalette.warningBg,
    _         => QDPalette.neutral50,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
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
                    // Summary metrics
                    Container(
                      color: QDPalette.surfaceCard,
                      padding: const EdgeInsets.symmetric(
                          horizontal: QDSpace.screenPad, vertical: 14),
                      child: Row(
                        children: [
                          _metric('Total',
                              QDCurrency.compact(_totalRevenue),
                              QDPalette.neutral800),
                          _vDivider(),
                          _metric('Collected',
                              QDCurrency.compact(_totalPaid),
                              QDPalette.success500),
                          _vDivider(),
                          _metric('Pending',
                              QDCurrency.compact(_totalPending),
                              QDPalette.error500),
                          _vDivider(),
                          _metric('Unpaid\nCount', '$_unpaidCount',
                              QDPalette.warning500),
                        ],
                      ),
                    ),
                    Container(height: 1, color: QDPalette.neutral100),

                    // Filter chips
                    SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: QDSpace.screenPad, vertical: 7),
                        itemCount: _statuses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
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
                            selectedColor: QDPalette.primary100,
                            checkmarkColor: QDPalette.primary600,
                            labelStyle: TextStyle(
                              color: selected
                                  ? QDPalette.primary600
                                  : QDPalette.neutral500,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        },
                      ),
                    ),
                    Container(height: 1, color: QDPalette.neutral100),

                    // List
                    Expanded(
                      child: _items.isEmpty
                          ? const QDEmptyState(
                              title: 'No invoices',
                              subtitle:
                                  'Invoices will appear here after appointments are completed.',
                              icon: Icons.receipt_long_outlined,
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: QDPalette.primary500,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.all(QDSpace.screenPad),
                                itemCount: _items.length,
                                itemBuilder: (_, i) => _card(_items[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _openPayment(InvoiceModel inv) async {
    if (_tenantId == null) return;
    if (inv.isPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice already paid')),
      );
      return;
    }
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectPaymentSheet(
        tenantId: _tenantId!,
        invoice: inv,
        repo: _repo,
      ),
    );
    if (paid == true) _load();
  }

  Widget _card(InvoiceModel inv) {
    final sc = _statusColor(inv.status);
    final bg = _statusBg(inv.status);
    return GestureDetector(
      onTap: () => _openPayment(inv),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(QDRadius.iconChip),
              ),
              child: Icon(Icons.receipt_outlined, color: sc, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: QDPalette.neutral800)),
                  const SizedBox(height: 2),
                  Text(
                    '#${inv.invoiceId} · ${QDDateUtils.formatDate(inv.invoiceDate)}',
                    style: const TextStyle(
                        color: QDPalette.neutral400, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(QDCurrency.format(inv.totalAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: QDPalette.neutral900,
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                QDStatusChip.fromStatus(inv.status),
                if (!inv.isPaid) ...[
                  const SizedBox(height: 4),
                  const Icon(Icons.payments_outlined,
                      size: 14, color: QDPalette.primary500),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: QDPalette.neutral400, height: 1.2)),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
        width: 1,
        height: 36,
        color: QDPalette.neutral100,
        margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}

// ── Collect Payment Sheet ──────────────────────────────────────────────────────

class _CollectPaymentSheet extends StatefulWidget {
  final int tenantId;
  final InvoiceModel invoice;
  final BusinessRepository repo;

  const _CollectPaymentSheet({
    required this.tenantId,
    required this.invoice,
    required this.repo,
  });

  @override
  State<_CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends State<_CollectPaymentSheet> {
  final _amountCtrl = TextEditingController();
  String _method = 'CASH';
  bool _saving = false;

  static const _methods = ['CASH', 'CARD', 'UPI', 'BANK_TRANSFER'];

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.invoice.balance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repo.collectPayment(widget.tenantId, widget.invoice.invoiceId, {
        'amount': amount,
        'paymentMethod': _method,
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
    final inv = widget.invoice;
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
                const Text('Collect Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: QDPalette.neutral900)),
                const SizedBox(height: 6),
                Text('${inv.customerName} · #${inv.invoiceId}',
                    style: const TextStyle(color: QDPalette.neutral400, fontSize: 13)),
                const SizedBox(height: 16),
                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: QDPalette.neutral50,
                    borderRadius: BorderRadius.circular(QDRadius.sm),
                  ),
                  child: Row(
                    children: [
                      _summaryItem('Total', QDCurrency.format(inv.totalAmount), QDPalette.neutral700),
                      _summaryItem('Paid', QDCurrency.format(inv.paidAmount), QDPalette.success500),
                      _summaryItem('Balance', QDCurrency.format(inv.balance), QDPalette.error500),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount to Collect *',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Payment Method',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: QDPalette.neutral500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _methods.map((m) {
                    final selected = m == _method;
                    return ChoiceChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (_) => setState(() => _method = m),
                      selectedColor: QDPalette.primary100,
                      labelStyle: TextStyle(
                        color: selected ? QDPalette.primary700 : QDPalette.neutral600,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: QDSpace.x5),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _collect,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.payments_rounded),
                    label: Text(_saving ? 'Processing...' : 'Collect Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QDPalette.success500,
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
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: QDPalette.neutral400)),
        ],
      ),
    );
  }
}
