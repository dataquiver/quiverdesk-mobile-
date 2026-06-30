import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../app/routes.dart';
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
      backgroundColor: QDPalette.surfaceBackground,
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: QDPalette.primary500,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(QDSpace.screenPad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MrrCard(data: _data),
                              const SizedBox(height: QDSpace.sectionGap),
                              _SectionHeader(title: 'Overview'),
                              const SizedBox(height: QDSpace.cardGap),
                              _buildStatsGrid(),
                              const SizedBox(height: QDSpace.sectionGap),
                              _SectionHeader(title: 'Quick Actions'),
                              const SizedBox(height: QDSpace.cardGap),
                              _ActionTile(
                                icon: Icons.business_rounded,
                                iconColor: QDPalette.primary500,
                                title: 'Manage Businesses',
                                subtitle: '${_data?.totalBusinesses ?? 0} businesses registered',
                                onTap: () => context.go(AppRoutes.businesses),
                              ),
                              const SizedBox(height: QDSpace.x4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: QDPalette.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Admin',
              style: TextStyle(fontSize: 12, color: QDPalette.neutral400, fontWeight: FontWeight.w500)),
          Text('QuiverDesk',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: QDPalette.neutral900)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: QDPalette.neutral600),
          onPressed: () => context.push(AppRoutes.profile),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: QDPalette.neutral100),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'Total Businesses',
              value: '${_data?.totalBusinesses ?? 0}',
              icon: Icons.business_rounded,
              color: QDPalette.primary500,
            )),
            const SizedBox(width: QDSpace.cardGap),
            Expanded(child: _StatCard(
              label: 'Active Subscriptions',
              value: '${_data?.activeSubscriptions ?? 0}',
              icon: Icons.verified_rounded,
              color: QDPalette.success500,
            )),
          ],
        ),
        const SizedBox(height: QDSpace.cardGap),
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'Trial Accounts',
              value: '${_data?.trialAccounts ?? 0}',
              icon: Icons.hourglass_top_rounded,
              color: QDPalette.warning500,
            )),
            const SizedBox(width: QDSpace.cardGap),
            Expanded(child: _StatCard(
              label: 'Expiring Soon',
              value: '${_data?.expiringSoon ?? 0}',
              icon: Icons.warning_amber_rounded,
              color: QDPalette.error500,
            )),
          ],
        ),
      ],
    );
  }
}

// ── MRR Card ─────────────────────────────────────────────────────────────────

class _MrrCard extends StatelessWidget {
  final PlatformDashboardModel? data;
  const _MrrCard({this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QDSpace.x5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [QDPalette.primary600, QDPalette.primary800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(QDRadius.md),
        boxShadow: [
          BoxShadow(
            color: QDPalette.primary700.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Monthly Recurring Revenue',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            QDCurrency.format(data?.mrr ?? 0, showDecimals: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data?.newThisMonth ?? 0} new businesses this month',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(QDRadius.iconChip),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: QDPalette.neutral900, letterSpacing: -0.5, height: 1)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 12, color: QDPalette.neutral400,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: QDPalette.neutral800, letterSpacing: -0.2)),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: const TextStyle(fontSize: 13, color: QDPalette.primary600,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QDPalette.surfaceCard,
      borderRadius: BorderRadius.circular(QDRadius.card),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(QDRadius.card),
        splashColor: QDPalette.primary50,
        child: Container(
          padding: const EdgeInsets.all(QDSpace.cardPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(QDRadius.card),
            border: Border.all(color: QDPalette.neutral100),
            boxShadow: QDShadow.card,
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(QDRadius.iconChip),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: QDSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                            color: QDPalette.neutral800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: QDPalette.neutral400, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: QDPalette.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
