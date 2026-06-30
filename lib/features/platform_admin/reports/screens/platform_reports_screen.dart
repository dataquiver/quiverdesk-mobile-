import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/platform_models.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../repository/platform_repository.dart';

enum _ReportTab { growth, revenue, plans, trials, renewals }

class PlatformReportsScreen extends StatefulWidget {
  const PlatformReportsScreen({super.key});

  @override
  State<PlatformReportsScreen> createState() => _PlatformReportsScreenState();
}

class _PlatformReportsScreenState extends State<PlatformReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = PlatformRepository();

  List<BusinessGrowthItem> _growth = [];
  List<RevenueReportItem> _revenue = [];
  List<PlanWiseRevenueItem> _planRevenue = [];
  List<ExpiringTrialItem> _trials = [];
  List<UpcomingRenewalItem> _renewals = [];

  bool _loading = false;
  String? _error;
  _ReportTab _activeTab = _ReportTab.growth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tab = _ReportTab.values[_tabController.index];
        setState(() => _activeTab = tab);
        _loadTab(tab);
      }
    });
    _loadTab(_ReportTab.growth);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTab(_ReportTab tab) async {
    setState(() { _loading = true; _error = null; });
    try {
      switch (tab) {
        case _ReportTab.growth:
          _growth = await _repo.getBusinessGrowth();
        case _ReportTab.revenue:
          _revenue = await _repo.getRevenueReport();
        case _ReportTab.plans:
          _planRevenue = await _repo.getPlanWiseRevenue();
        case _ReportTab.trials:
          _trials = await _repo.getExpiringTrials();
        case _ReportTab.renewals:
          _renewals = await _repo.getUpcomingRenewals();
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Growth'),
            Tab(text: 'Revenue'),
            Tab(text: 'Plans'),
            Tab(text: 'Trials'),
            Tab(text: 'Renewals'),
          ],
        ),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: () => _loadTab(_activeTab))
              : TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _GrowthTab(items: _growth),
                    _RevenueTab(items: _revenue),
                    _PlansTab(items: _planRevenue),
                    _TrialsTab(items: _trials),
                    _RenewalsTab(items: _renewals),
                  ],
                ),
    );
  }
}

// ── Growth tab ─────────────────────────────────────────────────────────────
class _GrowthTab extends StatelessWidget {
  final List<BusinessGrowthItem> items;
  const _GrowthTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const QDEmptyState(title: 'No Data', subtitle: 'No growth data available.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(child: Text(item.month, style: const TextStyle(fontWeight: FontWeight.w600))),
                _Stat(label: 'New', value: '${item.newBusinesses}', color: Colors.green),
                const SizedBox(width: 16),
                _Stat(label: 'Total', value: '${item.totalBusinesses}', color: Colors.blue),
                const SizedBox(width: 16),
                _Stat(label: 'Churned', value: '${item.churnedBusinesses}', color: Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Revenue tab ────────────────────────────────────────────────────────────
class _RevenueTab extends StatelessWidget {
  final List<RevenueReportItem> items;
  const _RevenueTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const QDEmptyState(title: 'No Data', subtitle: 'No revenue data available.');
    final total = items.fold(0.0, (s, e) => s + e.revenue);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text('Total Revenue', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(QDCurrency.format(total),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.month, style: const TextStyle(fontWeight: FontWeight.w600))),
                      _Stat(label: 'Total', value: QDCurrency.format(item.revenue), color: Colors.blue),
                      const SizedBox(width: 12),
                      _Stat(label: 'New', value: QDCurrency.format(item.newRevenue), color: Colors.green),
                      const SizedBox(width: 12),
                      _Stat(label: 'Renewal', value: QDCurrency.format(item.renewalRevenue), color: Colors.orange),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Plans tab ──────────────────────────────────────────────────────────────
class _PlansTab extends StatelessWidget {
  final List<PlanWiseRevenueItem> items;
  const _PlansTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const QDEmptyState(title: 'No Data', subtitle: 'No plan data available.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.planName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${item.subscriberCount} subscribers', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stat(label: 'Monthly', value: QDCurrency.format(item.monthlyRevenue), color: Colors.blue),
                    const SizedBox(width: 24),
                    _Stat(label: 'Annual', value: QDCurrency.format(item.annualRevenue), color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Trials tab ─────────────────────────────────────────────────────────────
class _TrialsTab extends StatelessWidget {
  final List<ExpiringTrialItem> items;
  const _TrialsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const QDEmptyState(title: 'No Expiring Trials', subtitle: 'No trials expiring soon.');
    final fmt = DateFormat('dd MMM yyyy');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        final urgent = item.daysLeft <= 7;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: urgent ? Colors.red.shade100 : Colors.orange.shade100,
              child: Text('${item.daysLeft}d',
                  style: TextStyle(fontSize: 12, color: urgent ? Colors.red : Colors.orange, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.businessName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item.ownerName),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Expires', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(fmt.format(item.trialExpiryDate), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Renewals tab ───────────────────────────────────────────────────────────
class _RenewalsTab extends StatelessWidget {
  final List<UpcomingRenewalItem> items;
  const _RenewalsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const QDEmptyState(title: 'No Upcoming Renewals', subtitle: 'No renewals due soon.');
    final fmt = DateFormat('dd MMM yyyy');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text('${item.daysUntilRenewal}d',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.businessName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item.planName),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(QDCurrency.format(item.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(fmt.format(item.renewalDate), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
