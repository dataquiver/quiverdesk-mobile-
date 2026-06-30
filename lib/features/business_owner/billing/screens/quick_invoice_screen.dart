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

  Widget _card(InvoiceModel inv) {
    final sc = _statusColor(inv.status);
    final bg = _statusBg(inv.status);
    return Container(
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
