import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _repo = BusinessRepository();
  List<Map<String, dynamic>>? _items;
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
      final data = await _repo.getFeedback(_tenantId!);
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double get _avgRating {
    if (_items == null || _items!.isEmpty) return 0;
    final sum = _items!.fold<double>(0, (s, e) => s + ((e['rating'] as num?)?.toDouble() ?? 0));
    return sum / _items!.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Customer Feedback')),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : (_items?.isEmpty ?? true)
                  ? const QDEmptyState(
                      icon: Icons.star_outline,
                      title: 'No feedback yet',
                      subtitle: 'Customer ratings will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _RatingBanner(avg: _avgRating, count: _items!.length),
                          const SizedBox(height: 16),
                          ...(_items!.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FeedbackCard(item: f),
                          ))),
                        ],
                      ),
                    ),
    );
  }
}

class _RatingBanner extends StatelessWidget {
  final double avg;
  final int count;
  const _RatingBanner({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QDColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QDColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: QDColors.warning, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(avg.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              Text('from $count reviews',
                  style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item['customerName'] as String? ?? 'Customer',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating ? Icons.star : Icons.star_outline,
                  color: QDColors.warning, size: 16,
                )),
              ),
            ],
          ),
          if (item['comment'] != null && (item['comment'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item['comment'] as String,
                style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
