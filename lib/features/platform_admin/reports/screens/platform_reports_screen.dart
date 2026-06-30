import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/design_system/design_system.dart';
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

class _PlatformReportsScreenState extends State<PlatformReportsScreen>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: QDPalette.surfaceBackground,
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

BoxDecoration get _cardDecor => BoxDecoration(
      color: QDPalette.surfaceCard,
      borderRadius: BorderRadius.circular(QDRadius.card),
      border: Border.all(color: QDPalette.neutral100),
      boxShadow: QDShadow.card,
    );

// ── Growth tab ─────────────────────────────────────────────────────────────
class _GrowthTab extends StatelessWidget {
  final List<BusinessGrowthItem> items;
  const _GrowthTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const QDEmptyState(title: 'No Data', subtitle: 'No growth data available.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(QDSpace.screenPad),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: QDSpace.x2),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(QDSpace.cardPad),
          decoration: _cardDecor,
          child: Row(
            children: [
              Expanded(
                child: Text(item.month,
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        color: QDPalette.neutral800)),
              ),
              _Stat(label: 'New', value: '${item.newBusinesses}', color: QDPalette.success500),
              const SizedBox(width: 16),
              _Stat(label: 'Total', value: '${item.totalBusinesses}', color: QDPalette.primary500),
              const SizedBox(width: 16),
              _Stat(label: 'Churned', value: '${item.churnedBusinesses}', color: QDPalette.error500),
            ],
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
    if (items.isEmpty) {
      return const QDEmptyState(title: 'No Data', subtitle: 'No revenue data available.');
    }
    final total = items.fold(0.0, (s, e) => s + e.revenue);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(QDSpace.screenPad),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: QDPalette.primary50,
            borderRadius: BorderRadius.circular(QDRadius.card),
            border: Border.all(color: QDPalette.primary100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text('Total Revenue',
                      style: TextStyle(fontSize: 12, color: QDPalette.primary600,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(QDCurrency.format(total),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          color: QDPalette.primary700, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: QDSpace.x2),
            itemBuilder: (_, i) {
              final item = items[i];
              return Container(
                padding: const EdgeInsets.all(QDSpace.cardPad),
                decoration: _cardDecor,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.month,
                          style: const TextStyle(fontWeight: FontWeight.w600,
                              color: QDPalette.neutral800)),
                    ),
                    _Stat(label: 'Total', value: QDCurrency.format(item.revenue),
                        color: QDPalette.primary500),
                    const SizedBox(width: 12),
                    _Stat(label: 'New', value: QDCurrency.format(item.newRevenue),
                        color: QDPalette.success500),
                    const SizedBox(width: 12),
                    _Stat(label: 'Renewal', value: QDCurrency.format(item.renewalRevenue),
                        color: QDPalette.warning500),
                  ],
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
    if (items.isEmpty) {
      return const QDEmptyState(title: 'No Data', subtitle: 'No plan data available.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(QDSpace.screenPad),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: QDSpace.x2),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(QDSpace.cardPad),
          decoration: _cardDecor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.planName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                          color: QDPalette.neutral900)),
                  Text('${item.subscriberCount} subscribers',
                      style: const TextStyle(fontSize: 12, color: QDPalette.neutral400)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Stat(label: 'Monthly', value: QDCurrency.format(item.monthlyRevenue),
                      color: QDPalette.primary500),
                  const SizedBox(width: 24),
                  _Stat(label: 'Annual', value: QDCurrency.format(item.annualRevenue),
                      color: QDPalette.success500),
                ],
              ),
            ],
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
    if (items.isEmpty) {
      return const QDEmptyState(
          title: 'No Expiring Trials', subtitle: 'No trials expiring soon.');
    }
    final fmt = DateFormat('dd MMM yyyy');
    return ListView.separated(
      padding: const EdgeInsets.all(QDSpace.screenPad),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: QDSpace.x2),
      itemBuilder: (_, i) {
        final item = items[i];
        final urgent = item.daysLeft <= 7;
        final chipColor = urgent ? QDPalette.error500 : QDPalette.warning500;
        final chipBg = urgent ? QDPalette.errorBg : QDPalette.warningBg;
        return Container(
          padding: const EdgeInsets.all(QDSpace.cardPad),
          decoration: _cardDecor,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(QDRadius.iconChip),
                ),
                child: Center(
                  child: Text('${item.daysLeft}d',
                      style: TextStyle(fontSize: 13, color: chipColor,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.businessName,
                        style: const TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 14, color: QDPalette.neutral800)),
                    const SizedBox(height: 2),
                    Text(item.ownerName,
                        style: const TextStyle(fontSize: 12, color: QDPalette.neutral500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Expires',
                      style: TextStyle(fontSize: 10, color: QDPalette.neutral400)),
                  const SizedBox(height: 2),
                  Text(fmt.format(item.trialExpiryDate),
                      style: const TextStyle(fontSize: 12, color: QDPalette.neutral700,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
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
    if (items.isEmpty) {
      return const QDEmptyState(
          title: 'No Upcoming Renewals', subtitle: 'No renewals due soon.');
    }
    final fmt = DateFormat('dd MMM yyyy');
    return ListView.separated(
      padding: const EdgeInsets.all(QDSpace.screenPad),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: QDSpace.x2),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(QDSpace.cardPad),
          decoration: _cardDecor,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: QDPalette.primary50,
                  borderRadius: BorderRadius.circular(QDRadius.iconChip),
                ),
                child: Center(
                  child: Text('${item.daysUntilRenewal}d',
                      style: const TextStyle(fontSize: 13, color: QDPalette.primary600,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.businessName,
                        style: const TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 14, color: QDPalette.neutral800)),
                    const SizedBox(height: 2),
                    Text(item.planName,
                        style: const TextStyle(fontSize: 12, color: QDPalette.neutral500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(QDCurrency.format(item.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                          color: QDPalette.neutral900, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(fmt.format(item.renewalDate),
                      style: const TextStyle(fontSize: 11, color: QDPalette.neutral400)),
                ],
              ),
            ],
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
        Text(label,
            style: const TextStyle(fontSize: 10, color: QDPalette.neutral400,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
