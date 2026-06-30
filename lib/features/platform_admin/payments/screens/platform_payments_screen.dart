import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/design_system/design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: const Text('Platform Payments'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Column(
            children: [
              Container(height: 1, color: QDPalette.neutral100),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ],
          ),
        ),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _payments.isEmpty
                  ? const QDEmptyState(
                      title: 'No Payments',
                      subtitle: 'No payment records found.',
                      icon: Icons.account_balance_wallet_rounded,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: QDPalette.primary500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        itemCount: _payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: QDSpace.x2),
                        itemBuilder: (_, i) => _PaymentCard(payment: _payments[i]),
                      ),
                    ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PlatformPaymentModel payment;
  const _PaymentCard({required this.payment});

  Color get _statusColor => switch (payment.status.toUpperCase()) {
    'PAID'     => QDPalette.success500,
    'PENDING'  => QDPalette.warning500,
    'FAILED'   => QDPalette.error500,
    'REFUNDED' => QDPalette.info500,
    _          => QDPalette.neutral400,
  };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.businessName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                            color: QDPalette.neutral800)),
                    const SizedBox(height: 2),
                    Text(payment.invoiceNumber,
                        style: const TextStyle(fontSize: 12, color: QDPalette.neutral400)),
                  ],
                ),
              ),
              QDStatusChip.fromStatus(payment.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Plan', style: TextStyle(fontSize: 11, color: QDPalette.neutral400,
                    fontWeight: FontWeight.w500)),
                Text(payment.planName,
                    style: const TextStyle(fontSize: 13, color: QDPalette.neutral700,
                        fontWeight: FontWeight.w500)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Amount', style: TextStyle(fontSize: 11, color: QDPalette.neutral400,
                    fontWeight: FontWeight.w500)),
                Text(QDCurrency.format(payment.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                        color: QDPalette.neutral900, letterSpacing: -0.3)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: QDPalette.neutral100),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due: ${payment.dueDate != null ? fmt.format(payment.dueDate!) : "—"}',
                style: const TextStyle(fontSize: 12, color: QDPalette.neutral400),
              ),
              Text(
                'Paid: ${payment.paidOn != null ? fmt.format(payment.paidOn!) : "—"}',
                style: const TextStyle(fontSize: 12, color: QDPalette.neutral400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
