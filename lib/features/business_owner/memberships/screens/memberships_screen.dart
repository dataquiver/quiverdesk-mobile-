import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class MembershipsScreen extends StatefulWidget {
  const MembershipsScreen({super.key});

  @override
  State<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends State<MembershipsScreen> {
  final _repo = BusinessRepository();
  List<Map<String, dynamic>>? _plans;
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
      final data = await _repo.getMemberships(_tenantId!);
      if (mounted) setState(() { _plans = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Memberships')),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : (_plans?.isEmpty ?? true)
                  ? const QDEmptyState(
                      icon: Icons.card_membership_outlined,
                      title: 'No membership plans',
                      subtitle: 'Create plans to reward loyal customers',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _plans!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _PlanCard(plan: _plans![i]),
                      ),
                    ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final features = (plan['features'] as List<dynamic>? ?? []).cast<String>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan['planName'] as String? ?? plan['name'] as String? ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Text(QDCurrency.format((plan['price'] as num?)?.toDouble() ?? 0),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: QDColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Valid for ${plan['validityDays'] ?? 30} days',
              style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: QDColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(f, style: const TextStyle(fontSize: 13)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
