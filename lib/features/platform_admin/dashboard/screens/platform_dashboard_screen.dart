import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../app/themes.dart';
import '../../../../core/models/dashboard_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/platform_repository.dart';

class PlatformDashboardScreen extends StatefulWidget {
  const PlatformDashboardScreen({super.key});

  @override
  State<PlatformDashboardScreen> createState() => _PlatformDashboardScreenState();
}

class _PlatformDashboardScreenState extends State<PlatformDashboardScreen> {
  final _repo = PlatformRepository();
  PlatformDashboardModel? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _repo.getDashboard();
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform Admin',
                style: TextStyle(fontSize: 13, color: QDColors.textSecondary, fontWeight: FontWeight.w400)),
            Text('QuiverDesk', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      Container(
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
                            const Text('Monthly Recurring Revenue',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                              QDCurrency.format(_data?.mrr ?? 0, showDecimals: true),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_data?.newThisMonth ?? 0} new businesses this month',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats grid
                      const Text('Overview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _statCard(
                            'Total Businesses',
                            '${_data?.totalBusinesses ?? 0}',
                            Icons.business,
                            QDColors.primary,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard(
                            'Active Subscriptions',
                            '${_data?.activeSubscriptions ?? 0}',
                            Icons.verified_outlined,
                            QDColors.success,
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _statCard(
                            'Trial Accounts',
                            '${_data?.trialAccounts ?? 0}',
                            Icons.access_time,
                            QDColors.warning,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard(
                            'Expiring Soon',
                            '${_data?.expiringSoon ?? 0}',
                            Icons.warning_amber_outlined,
                            QDColors.error,
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick actions
                      const Text('Quick Actions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _actionTile(
                        icon: Icons.business_outlined,
                        title: 'Manage Businesses',
                        subtitle: '${_data?.totalBusinesses ?? 0} businesses registered',
                        onTap: () => context.go(AppRoutes.businesses),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: QDColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: QDColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: QDColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QDColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: QDColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_outlined, color: QDColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: QDColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
