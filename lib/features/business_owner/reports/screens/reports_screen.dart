import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/themes.dart';
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
            color: QDColors.primary,
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
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
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
                      color: QDColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('Period:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: sel ? QDColors.primary : QDColors.background,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: sel ? QDColors.primary : QDColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          e.value,
                                          style: TextStyle(
                                            color: sel ? Colors.white : QDColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
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
                    const Divider(height: 1),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Key metrics
                            Row(
                              children: [
                                Expanded(child: _metricCard(
                                  'Revenue',
                                  QDCurrency.compact(_d('totalRevenue')),
                                  Icons.currency_rupee,
                                  QDColors.success,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _metricCard(
                                  'Appointments',
                                  '${_i('totalAppointments')}',
                                  Icons.calendar_today,
                                  QDColors.primary,
                                )),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _metricCard(
                                  'New Customers',
                                  '${_i('newCustomers')}',
                                  Icons.person_add_outlined,
                                  QDColors.secondary,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _metricCard(
                                  'Avg Invoice',
                                  QDCurrency.compact(_d('avgInvoiceValue')),
                                  Icons.receipt_outlined,
                                  QDColors.accent,
                                )),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Revenue chart
                            if ((_data?['revenueByDay'] as List?)?.isNotEmpty ?? false) ...[
                              const Text('Revenue Trend',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Container(
                                height: 200,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: QDColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: QDColors.border),
                                ),
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _chartData(),
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    titlesData: const FlTitlesData(
                                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Top services
                            if ((_data?['topServices'] as List?)?.isNotEmpty ?? false) ...[
                              const Text('Top Services',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              ...((_data!['topServices'] as List<dynamic>).map((s) {
                                final name = s['serviceName'] as String? ?? '';
                                final count = s['count'] as int? ?? 0;
                                final rev = (s['revenue'] as num?)?.toDouble() ?? 0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: QDColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: QDColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(name,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      ),
                                      Text('$count appts  ',
                                          style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                                      Text(QDCurrency.compact(rev),
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: QDColors.success, fontSize: 14)),
                                    ],
                                  ),
                                );
                              })),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: QDColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(label, style: const TextStyle(fontSize: 11, color: QDColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
