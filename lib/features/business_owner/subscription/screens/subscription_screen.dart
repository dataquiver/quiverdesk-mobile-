import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/utils/currency_utils.dart';
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
  Map<String, dynamic>? _subscription;
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

  Future<void> _load() async {
    if (_tenantId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getSubscription(_tenantId!);
      if (mounted) setState(() { _subscription = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Subscription')),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _subscription == null
                  ? const QDEmptyState(
                      icon: Icons.subscriptions_outlined,
                      title: 'No subscription',
                      subtitle: 'Contact platform admin to subscribe',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _CurrentPlanCard(sub: _subscription!),
                          const SizedBox(height: 20),
                          const Text('Features',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          ...((_subscription!['features'] as List<dynamic>? ?? [])
                              .cast<String>()
                              .map((f) => _FeatureRow(feature: f))),
                        ],
                      ),
                    ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  const _CurrentPlanCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final status = sub['status'] as String? ?? sub['subscriptionStatus'] as String?;
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
              'Expires: ${sub['endDate'] ?? sub['expiryDate']}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          if (sub['amount'] != null || sub['price'] != null)
            Text(
              '${QDCurrency.format(((sub['amount'] ?? sub['price']) as num).toDouble())}/month',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
