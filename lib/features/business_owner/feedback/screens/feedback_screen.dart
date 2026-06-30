import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
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
    final sum = _items!.fold<double>(
        0, (s, e) => s + ((e['rating'] as num?)?.toDouble() ?? 0));
    return sum / _items!.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('Customer Feedback')),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : (_items?.isEmpty ?? true)
                  ? const QDEmptyState(
                      icon: Icons.star_outline_rounded,
                      title: 'No feedback yet',
                      subtitle: 'Customer ratings will appear here after appointments are completed.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: QDPalette.primary500,
                      child: ListView(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        children: [
                          _RatingBanner(
                              avg: _avgRating, count: _items!.length),
                          const SizedBox(height: QDSpace.cardGap),
                          ...(_items!.map((f) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: QDSpace.cardGap),
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
        color: QDPalette.warningBg,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.warning500.withValues(alpha: 0.3)),
        boxShadow: QDShadow.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: QDPalette.warning500, size: 44),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(avg.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: QDPalette.neutral900,
                      letterSpacing: -1)),
              Text('from $count reviews',
                  style: const TextStyle(
                      color: QDPalette.neutral500, fontSize: 13)),
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
    final comment = item['comment'] as String?;
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
              QDAvatar(
                  name: item['customerName'] as String? ?? 'Customer',
                  size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    item['customerName'] as String? ?? 'Customer',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: QDPalette.neutral800)),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: QDPalette.warning500,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: QDPalette.neutral50,
                borderRadius: BorderRadius.circular(QDRadius.xs),
              ),
              child: Text(comment,
                  style: const TextStyle(
                      color: QDPalette.neutral600,
                      fontSize: 13,
                      height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}
