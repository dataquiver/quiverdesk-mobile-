import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/invoice_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/staff_repository.dart';

class StaffBillingScreen extends StatefulWidget {
  const StaffBillingScreen({super.key});

  @override
  State<StaffBillingScreen> createState() => _StaffBillingScreenState();
}

class _StaffBillingScreenState extends State<StaffBillingScreen> {
  final _repo = StaffRepository();
  List<InvoiceModel> _invoices = [];
  bool _loading = true;
  String? _error;
  int? _tenantId;

  @override
  void initState() {
    super.initState();
    _init();
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
      final raw = await _repo.getInvoices(_tenantId!);
      if (mounted) {
        setState(() {
          _invoices = raw.map((e) => InvoiceModel.fromJson(e)).toList();
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
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _invoices.isEmpty
                  ? const QDEmptyState(
                      title: 'No Invoices',
                      subtitle: 'No billing records found for you.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: QDPalette.primary500,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        itemCount: _invoices.length,
                        itemBuilder: (_, i) => _InvoiceCard(invoice: _invoices[i]),
                      ),
                    ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.isPaid;
    final sc = isPaid ? QDPalette.success500 : QDPalette.warning500;
    final bg = isPaid ? QDPalette.successBg : QDPalette.warningBg;

    return Container(
      margin: const EdgeInsets.only(bottom: QDSpace.cardGap),
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(QDRadius.iconChip)),
                child: Icon(Icons.receipt_outlined, color: sc, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: QDPalette.neutral800)),
                    if (invoice.customerPhone != null)
                      Text(invoice.customerPhone!,
                          style: const TextStyle(
                              fontSize: 12, color: QDPalette.neutral400)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(QDCurrency.format(invoice.totalAmount),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: QDPalette.neutral900, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  QDStatusChip.fromStatus(invoice.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '#${invoice.invoiceId} · ${QDDateUtils.formatDate(invoice.invoiceDate)}',
            style: const TextStyle(color: QDPalette.neutral400, fontSize: 12),
          ),
          if (invoice.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: QDPalette.neutral100),
            const SizedBox(height: 8),
            ...invoice.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.serviceName,
                            style: const TextStyle(
                                color: QDPalette.neutral500, fontSize: 12)),
                      ),
                      Text(QDCurrency.format(item.total),
                          style: const TextStyle(
                              color: QDPalette.neutral700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
            if (invoice.items.length > 3)
              Text('+${invoice.items.length - 3} more items',
                  style: const TextStyle(
                      fontSize: 11, color: QDPalette.neutral400)),
          ],
        ],
      ),
    );
  }
}
