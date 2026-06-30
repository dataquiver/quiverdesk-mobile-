import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/platform_models.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../repository/platform_repository.dart';

class PlatformPaymentsScreen extends StatefulWidget {
  const PlatformPaymentsScreen({super.key});

  @override
  State<PlatformPaymentsScreen> createState() => _PlatformPaymentsScreenState();
}

class _PlatformPaymentsScreenState extends State<PlatformPaymentsScreen> {
  final _repo = PlatformRepository();
  List<PlatformPaymentModel> _payments = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _repo.getPayments(status: _statusFilter.isEmpty ? null : _statusFilter);
      setState(() { _payments = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAID': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'FAILED': return Colors.red;
      case 'REFUNDED': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Payments'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: ['', 'PENDING', 'PAID', 'FAILED', 'REFUNDED'].map((s) {
                final label = s.isEmpty ? 'All' : s;
                final selected = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) { setState(() => _statusFilter = s); _load(); },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _payments.isEmpty
                  ? const QDEmptyState(title: 'No Payments', subtitle: 'No payment records found.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _PaymentCard(
                          payment: _payments[i],
                          statusColor: _statusColor(_payments[i].status),
                        ),
                      ),
                    ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PlatformPaymentModel payment;
  final Color statusColor;
  const _PaymentCard({required this.payment, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
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
                      Text(payment.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(payment.invoiceNumber, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(payment.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Plan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(payment.planName, style: const TextStyle(fontSize: 13)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(QDCurrency.format(payment.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due: ${payment.dueDate != null ? fmt.format(payment.dueDate!) : "—"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Paid: ${payment.paidOn != null ? fmt.format(payment.paidOn!) : "—"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
