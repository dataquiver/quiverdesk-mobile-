import 'package:flutter/material.dart';
import '../../../../core/models/platform_models.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../repository/platform_repository.dart';

class PlatformPlansScreen extends StatefulWidget {
  const PlatformPlansScreen({super.key});

  @override
  State<PlatformPlansScreen> createState() => _PlatformPlansScreenState();
}

class _PlatformPlansScreenState extends State<PlatformPlansScreen> {
  final _repo = PlatformRepository();
  List<PlatformPlanModel> _plans = [];
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
      final plans = await _repo.getPlans();
      setState(() { _plans = plans; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggle(PlatformPlanModel plan) async {
    try {
      if (plan.isActive) {
        await _repo.deactivatePlan(plan.subscriptionPlanId);
      } else {
        await _repo.activatePlan(plan.subscriptionPlanId);
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _plans.isEmpty
                  ? const QDEmptyState(title: 'No Plans', subtitle: 'No subscription plans found.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _plans.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _PlanCard(plan: _plans[i], onToggle: () => _toggle(_plans[i])),
                      ),
                    ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlatformPlanModel plan;
  final VoidCallback onToggle;

  const _PlanCard({required this.plan, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      Text(plan.planName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(plan.planCode, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: plan.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: plan.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.description!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _PriceChip(label: 'Monthly', value: QDCurrency.format(plan.monthlyPrice)),
                const SizedBox(width: 12),
                _PriceChip(label: 'Annual', value: QDCurrency.format(plan.annualPrice)),
                const SizedBox(width: 12),
                _PriceChip(label: 'Trial', value: '${plan.trialDays}d'),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _LimitChip(label: 'Users', value: '${plan.maxUsers}'),
                _LimitChip(label: 'Staff', value: '${plan.maxStaff}'),
                _LimitChip(label: 'Customers', value: '${plan.maxCustomers}'),
                _LimitChip(label: 'Branches', value: '${plan.maxBranches}'),
                _LimitChip(label: 'Appts/mo', value: '${plan.maxAppointmentsPerMonth}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${plan.activeSubscriberCount} subscribers', style: theme.textTheme.bodySmall),
                TextButton(
                  onPressed: onToggle,
                  child: Text(plan.isActive ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  const _PriceChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LimitChip extends StatelessWidget {
  final String label;
  final String value;
  const _LimitChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text('$label: $value', style: TextStyle(fontSize: 11, color: Colors.blue.shade800)),
    );
  }
}
