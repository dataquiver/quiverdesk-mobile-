import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/invoice_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';

class StaffBillingScreen extends StatefulWidget {
  const StaffBillingScreen({super.key});

  @override
  State<StaffBillingScreen> createState() => _StaffBillingScreenState();
}

class _StaffBillingScreenState extends State<StaffBillingScreen> {
  final _dio = ApiClient.instance;
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
    setState(() => _tenantId = bizId != null ? int.tryParse(bizId) : null);
    _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(ApiEndpoints.staffInvoices(_tenantId!));
      final body = res.data;
      List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = (body['items'] ?? body['data'] ?? body['invoices'] ?? []) as List<dynamic>;
      } else {
        list = [];
      }
      setState(() {
        _invoices = list.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
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
        title: const Text('Billing'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _invoices.isEmpty
                  ? const QDEmptyState(title: 'No Invoices', subtitle: 'No billing records found.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final fmt = DateFormat('dd MMM yyyy');
    final isPaid = invoice.isPaid;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (invoice.customerPhone != null)
                        Text(invoice.customerPhone!,
                            style: const TextStyle(fontSize: 12, color: QDColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? QDColors.successLight : QDColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    invoice.status,
                    style: TextStyle(
                      color: isPaid ? QDColors.success : QDColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmt.format(invoice.invoiceDate),
                    style: const TextStyle(fontSize: 12, color: QDColors.textHint)),
                Text(QDCurrency.format(invoice.totalAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            if (invoice.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              ...invoice.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.serviceName, style: const TextStyle(fontSize: 12, color: QDColors.textSecondary)),
                        Text(QDCurrency.format(item.total), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  )),
              if (invoice.items.length > 3)
                Text('+${invoice.items.length - 3} more items',
                    style: const TextStyle(fontSize: 11, color: QDColors.textHint)),
            ],
          ],
        ),
      ),
    );
  }
}
