import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_button.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _repo = BusinessRepository();
  late final Razorpay _razorpay;

  Map<String, dynamic>? _subscription;
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;
  int? _tenantId;

  /// Order awaiting a gateway callback: {paymentOrderId, planName}.
  Map<String, dynamic>? _pendingOrder;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _init();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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
      final results = await Future.wait([
        _repo.getSubscription(_tenantId!),
        _repo.getSubscriptionPlanOptions(_tenantId!),
        _repo.getPaymentHistory(_tenantId!),
      ]);
      if (mounted) {
        setState(() {
          _subscription = results[0] as Map<String, dynamic>?;
          _plans = results[1] as List<Map<String, dynamic>>;
          _payments = results[2] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Payment flow ───────────────────────────────────────────────────────────

  Future<void> _startPayment(Map<String, dynamic> plan, String billingCycle) async {
    if (_tenantId == null) return;
    try {
      final order = await _repo.createPaymentOrder(
        _tenantId!,
        planCode: plan['planCode'] as String,
        billingCycle: billingCycle,
      );

      _pendingOrder = {
        'paymentOrderId': order['paymentOrderId'],
        'planName': order['planName'],
      };

      final email = await TokenStorage.getUserEmail();
      final name = await TokenStorage.getUserName();

      _razorpay.open({
        'key': order['keyId'],
        'amount': ((order['totalAmount'] as num) * 100).round(),
        'currency': order['currency'] ?? 'INR',
        'name': 'QuiverDesk',
        'description': '${order['planName']} plan (${(order['billingCycle'] as String).toLowerCase()})',
        'order_id': order['gatewayOrderId'],
        'prefill': {
          if (email != null && email.isNotEmpty) 'email': email,
          if (name != null && name.isNotEmpty) 'name': name,
        },
        'theme': {'color': '#4F46E5'},
      });
    } catch (e) {
      if (mounted) _showFailureSheet(_friendlyError(e));
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final pending = _pendingOrder;
    _pendingOrder = null;
    if (_tenantId == null || pending == null) return;

    setState(() => _verifying = true);
    try {
      final result = await _repo.verifyPayment(
        _tenantId!,
        paymentOrderId: pending['paymentOrderId'] as int,
        gatewayOrderId: response.orderId ?? '',
        gatewayPaymentId: response.paymentId ?? '',
        gatewaySignature: response.signature ?? '',
      );
      if (!mounted) return;
      setState(() => _verifying = false);
      _showSuccessSheet(result);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      _showFailureSheet(
        'Payment is being confirmed. If money was deducted, your plan will '
        'activate automatically within a few minutes.',
      );
      await _load();
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _pendingOrder = null;
    if (!mounted) return;
    // User backing out of the checkout is not an error worth alarming about.
    if (response.code == Razorpay.PAYMENT_CANCELLED) return;
    _showFailureSheet(
      response.message?.isNotEmpty == true
          ? response.message!
          : 'The payment could not be completed. You have not been charged.',
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // External wallet flows complete through the gateway webhook.
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('message')) return 'Could not start the payment. Please try again.';
    return s.length > 140 ? 'Could not start the payment. Please try again.' : s;
  }

  // ── Sheets ─────────────────────────────────────────────────────────────────

  void _openPlanSheet() {
    String billingCycle = 'MONTHLY';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final paidPlans = _plans
              .where((p) => ((p['monthlyPrice'] as num?) ?? 0) > 0)
              .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            builder: (ctx, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Choose a Plan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                _BillingToggle(
                  value: billingCycle,
                  onChanged: (v) => setSheetState(() => billingCycle = v),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: paidPlans.length,
                    itemBuilder: (ctx, i) => _PlanCard(
                      plan: paidPlans[i],
                      billingCycle: billingCycle,
                      isCurrent: _isCurrentPlan(paidPlans[i]),
                      onPay: () {
                        Navigator.pop(ctx);
                        _startPayment(paidPlans[i], billingCycle);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isCurrentPlan(Map<String, dynamic> plan) {
    final currentCode = (_subscription?['planCode'] as String?)?.toUpperCase();
    return currentCode != null &&
        currentCode == (plan['planCode'] as String).toUpperCase();
  }

  void _showSuccessSheet(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: QDColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: QDColors.success, size: 42),
            ),
            const SizedBox(height: 16),
            const Text('Payment Successful',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('${result['planName'] ?? 'Your'} plan is now active.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 18),
            _ReceiptRow(label: 'Invoice', value: result['invoiceNumber'] as String?),
            _ReceiptRow(label: 'Transaction ID', value: result['transactionId'] as String?),
            _ReceiptRow(
              label: 'Valid till',
              value: _formatDate(result['subscriptionExpiryDate'] as String?),
            ),
            const SizedBox(height: 22),
            QDButton(label: 'Done', width: double.infinity, onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  void _showFailureSheet(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: QDColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: QDColors.error, size: 42),
            ),
            const SizedBox(height: 16),
            const Text('Payment Failed',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 22),
            QDButton(
              label: 'Try Again',
              width: double.infinity,
              onPressed: () {
                Navigator.pop(ctx);
                _openPlanSheet();
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelAutoRenew() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel auto-renewal?'),
        content: Text(
          'Your plan stays active until ${_formatDate(_subscription?['expiryDate'] as String?)}. '
          'After that it will not renew automatically.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Turn Off', style: TextStyle(color: QDColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || _tenantId == null) return;
    try {
      await _repo.cancelSubscription(_tenantId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-renewal turned off.')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    }
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Subscription')),
      body: Stack(
        children: [
          _loading
              ? const QDLoading()
              : _error != null
                  ? QDError(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_subscription != null)
                            _CurrentPlanCard(
                              sub: _subscription!,
                              onCancelAutoRenew: _confirmCancelAutoRenew,
                            )
                          else
                            const QDEmptyState(
                              icon: Icons.subscriptions_outlined,
                              title: 'No subscription',
                              subtitle: 'Choose a plan to get started',
                            ),
                          const SizedBox(height: 16),
                          QDButton(
                            label: _subscription == null ? 'Choose a Plan' : 'Upgrade Plan',
                            icon: Icons.rocket_launch_outlined,
                            width: double.infinity,
                            onPressed: _plans.isEmpty ? null : _openPlanSheet,
                          ),
                          if (_subscription?['features'] != null &&
                              (_subscription!['features'] as List).isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text('Features',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            ...(_subscription!['features'] as List<dynamic>)
                                .cast<String>()
                                .map((f) => _FeatureRow(feature: f)),
                          ],
                          if (_payments.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text('Payment History',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            ..._payments.map((p) => _PaymentTile(payment: p, formatDate: _formatDate)),
                          ],
                        ],
                      ),
                    ),
          if (_verifying)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Confirming payment…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _BillingToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(String cycle, String label) {
      final selected = value == cycle;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(cycle),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? QDColors.primary : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          option('MONTHLY', 'Monthly'),
          option('ANNUAL', 'Annual (save more)'),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String billingCycle;
  final bool isCurrent;
  final VoidCallback onPay;

  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.isCurrent,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final monthly = ((plan['monthlyPrice'] as num?) ?? 0).toDouble();
    final annual = ((plan['annualPrice'] as num?) ?? 0).toDouble();
    final isAnnual = billingCycle == 'ANNUAL' && annual > 0;
    final price = isAnnual ? annual : monthly;
    final savings = (monthly > 0 && annual > 0)
        ? (((monthly * 12 - annual) / (monthly * 12)) * 100).round()
        : 0;
    final recommended = plan['isRecommended'] == true;
    final features = (plan['features'] as List<dynamic>? ?? []).cast<String>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recommended ? QDColors.primary : Colors.grey.shade200,
          width: recommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan['planName'] as String? ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: QDColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Recommended',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: QDColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(QDCurrency.format(price),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text('/${isAnnual ? 'year' : 'month'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(width: 8),
              if (isAnnual && savings > 0)
                Text('Save $savings%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: QDColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          ...features.take(4).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 15, color: QDColors.success),
                    const SizedBox(width: 6),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 12.5))),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          QDButton(
            label: isCurrent ? 'Current Plan' : 'Pay ${QDCurrency.format(price * 1.18)} (incl. GST)',
            width: double.infinity,
            onPressed: isCurrent ? null : onPay,
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  final String Function(String?) formatDate;
  const _PaymentTile({required this.payment, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final status = (payment['status'] as String? ?? '').toUpperCase();
    final statusColor = status == 'PAID'
        ? QDColors.success
        : status == 'REFUNDED'
            ? Colors.grey
            : QDColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment['planName'] as String? ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${formatDate((payment['paidOn'] ?? payment['createdOn']) as String?)}'
                  '${payment['invoiceNumber'] != null && (payment['invoiceNumber'] as String).isNotEmpty ? ' · ${payment['invoiceNumber']}' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(QDCurrency.format(((payment['totalAmount'] as num?) ?? 0).toDouble()),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? value;
  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty || value == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final VoidCallback onCancelAutoRenew;
  const _CurrentPlanCard({required this.sub, required this.onCancelAutoRenew});

  @override
  Widget build(BuildContext context) {
    final status = sub['status'] as String? ?? sub['subscriptionStatus'] as String?;
    final autoRenew = sub['autoRenew'] == true;
    final price = ((sub['monthlyPrice'] ?? sub['amount'] ?? sub['price']) as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [QDColors.primary, QDColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sub['planName'] as String? ?? sub['plan'] as String? ?? 'Current Plan',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status ?? 'UNKNOWN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sub['endDate'] != null || sub['expiryDate'] != null)
            Text(
              'Expires: ${_SubscriptionScreenState._formatDate((sub['endDate'] ?? sub['expiryDate']) as String?)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          if (price != null && price > 0)
            Text(
              '${QDCurrency.format(price)}/month',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(autoRenew ? Icons.autorenew : Icons.block,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('Auto-renew ${autoRenew ? 'on' : 'off'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              if (autoRenew && price != null && price > 0)
                GestureDetector(
                  onTap: onCancelAutoRenew,
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: QDColors.success, size: 20),
          const SizedBox(width: 12),
          Text(feature, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
