import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
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
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _plans.isEmpty
                  ? const QDEmptyState(
                      title: 'No Plans',
                      subtitle: 'No subscription plans found.',
                      icon: Icons.card_membership_rounded,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: QDPalette.primary500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        itemCount: _plans.length,
                        separatorBuilder: (_, __) => const SizedBox(height: QDSpace.cardGap),
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
                    Text(plan.planName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                            color: QDPalette.neutral900, letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text(plan.planCode,
                        style: const TextStyle(fontSize: 12, color: QDPalette.neutral400,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              QDStatusChip(
                label: plan.isActive ? 'Active' : 'Inactive',
                color: plan.isActive ? QDPalette.success700 : QDPalette.neutral500,
                bgColor: plan.isActive ? QDPalette.successBg : QDPalette.neutral50,
              ),
            ],
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(plan.description!,
                style: const TextStyle(fontSize: 13, color: QDPalette.neutral500, height: 1.4)),
          ],
          const SizedBox(height: 14),
          // Price row
          Row(
            children: [
              _PriceChip(label: 'Monthly', value: QDCurrency.format(plan.monthlyPrice)),
              const SizedBox(width: 16),
              _PriceChip(label: 'Annual', value: QDCurrency.format(plan.annualPrice)),
              const SizedBox(width: 16),
              _PriceChip(label: 'Trial', value: '${plan.trialDays}d'),
            ],
          ),
          const SizedBox(height: 12),
          // Limits
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _LimitChip(label: 'Users', value: '${plan.maxUsers}'),
              _LimitChip(label: 'Staff', value: '${plan.maxStaff}'),
              _LimitChip(label: 'Customers', value: '${plan.maxCustomers}'),
              _LimitChip(label: 'Branches', value: '${plan.maxBranches}'),
              _LimitChip(label: 'Appts/mo', value: '${plan.maxAppointmentsPerMonth}'),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: QDPalette.neutral100),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.activeSubscriberCount} subscribers',
                style: const TextStyle(fontSize: 12, color: QDPalette.neutral400),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  plan.isActive ? 'Deactivate' : 'Activate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: plan.isActive ? QDPalette.error500 : QDPalette.success500,
                  ),
                ),
              ),
            ],
          ),
        ],
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
        Text(label, style: const TextStyle(fontSize: 10, color: QDPalette.neutral400,
            fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: QDPalette.neutral800)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: QDPalette.primary50,
        borderRadius: BorderRadius.circular(QDRadius.xs),
        border: Border.all(color: QDPalette.primary100),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: QDPalette.primary600,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
