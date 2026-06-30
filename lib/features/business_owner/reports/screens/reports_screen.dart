import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';
import '../../../../app/routes.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = BusinessRepository();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  int? _tenantId;
  String _period = 'THIS_MONTH';

  static const _periods = {
    'TODAY': 'Today',
    'THIS_WEEK': 'This Week',
    'THIS_MONTH': 'This Month',
    'LAST_MONTH': 'Last Month',
    'THIS_YEAR': 'This Year',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final idStr = await TokenStorage.getBusinessId();
    _tenantId = idStr != null ? int.tryParse(idStr) : null;
    await _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _repo.getReports(_tenantId!, period: _period);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double _d(String key) => (_data?[key] as num?)?.toDouble() ?? 0.0;
  int _i(String key) => (_data?[key] as int?) ?? 0;

  List<BarChartGroupData> _chartData() {
    final raw = _data?['revenueByDay'] as List<dynamic>? ?? [];
    return raw.asMap().entries.map((e) {
      final item = e.value as Map<String, dynamic>;
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: QDPalette.primary500,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    // Period selector
                    Container(
                      color: QDPalette.surfaceCard,
                      padding: const EdgeInsets.symmetric(
                          horizontal: QDSpace.screenPad, vertical: 8),
                      child: Row(
                        children: [
                          const Text('Period:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: QDPalette.neutral600)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: _periods.entries.map((e) {
                                  final sel = e.key == _period;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _period = e.key);
                                        _load();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? QDPalette.primary500
                                              : QDPalette.surfaceBackground,
                                          borderRadius: BorderRadius.circular(
                                              QDRadius.xs),
                                          border: Border.all(
                                            color: sel
                                                ? QDPalette.primary500
                                                : QDPalette.neutral200,
                                          ),
                                        ),
                                        child: Text(
                                          e.value,
                                          style: TextStyle(
                                            color: sel
                                                ? Colors.white
                                                : QDPalette.neutral500,
                                            fontSize: 12,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: QDPalette.neutral100),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        color: QDPalette.primary500,
                        child: ListView(
                          padding: const EdgeInsets.all(QDSpace.screenPad),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard(
                                    'Revenue',
                                    QDCurrency.compact(_d('totalRevenue')),
                                    Icons.currency_rupee_rounded,
                                    QDPalette.success500,
                                    QDPalette.successBg,
                                  ),
                                ),
                                const SizedBox(width: QDSpace.cardGap),
                                Expanded(
                                  child: _metricCard(
                                    'Appointments',
                                    '${_i('totalAppointments')}',
                                    Icons.calendar_today_rounded,
                                    QDPalette.primary500,
                                    QDPalette.primary50,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: QDSpace.cardGap),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard(
                                    'New Customers',
                                    '${_i('newCustomers')}',
                                    Icons.person_add_rounded,
                                    QDPalette.info500,
                                    QDPalette.infoBg,
                                  ),
                                ),
                                const SizedBox(width: QDSpace.cardGap),
                                Expanded(
                                  child: _metricCard(
                                    'Avg Invoice',
                                    QDCurrency.compact(_d('avgInvoiceValue')),
                                    Icons.receipt_outlined,
                                    QDPalette.warning500,
                                    QDPalette.warningBg,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: QDSpace.sectionGap),

                            // Revenue chart
                            if ((_data?['revenueByDay'] as List?)?.isNotEmpty ?? false) ...[
                              const Text('Revenue Trend',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: QDPalette.neutral800)),
                              const SizedBox(height: QDSpace.cardGap),
                              Container(
                                height: 200,
                                padding: const EdgeInsets.all(QDSpace.cardPad),
                                decoration: BoxDecoration(
                                  color: QDPalette.surfaceCard,
                                  borderRadius: BorderRadius.circular(QDRadius.card),
                                  border: Border.all(color: QDPalette.neutral100),
                                  boxShadow: QDShadow.card,
                                ),
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _chartData(),
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    titlesData: const FlTitlesData(
                                      leftTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: QDSpace.sectionGap),
                            ],

                            // Top services
                            if ((_data?['topServices'] as List?)?.isNotEmpty ?? false) ...[
                              const Text('Top Services',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: QDPalette.neutral800)),
                              const SizedBox(height: QDSpace.cardGap),
                              ...((_data!['topServices'] as List<dynamic>).map((s) {
                                final name = s['serviceName'] as String? ?? '';
                                final count = s['count'] as int? ?? 0;
                                final rev = (s['revenue'] as num?)?.toDouble() ?? 0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: QDSpace.x2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: QDSpace.cardPad, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: QDPalette.surfaceCard,
                                    borderRadius: BorderRadius.circular(QDRadius.card),
                                    border: Border.all(color: QDPalette.neutral100),
                                    boxShadow: QDShadow.card,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: QDPalette.neutral800)),
                                      ),
                                      Text('$count appts  ',
                                          style: const TextStyle(
                                              color: QDPalette.neutral400,
                                              fontSize: 13)),
                                      Text(QDCurrency.compact(rev),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: QDPalette.success500,
                                              fontSize: 14)),
                                    ],
                                  ),
                                );
                              })),
                            ],
                            const SizedBox(height: QDSpace.screenPad),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _metricCard(
      String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(QDRadius.iconChip),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: QDPalette.neutral900,
                        letterSpacing: -0.5),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: QDPalette.neutral400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
