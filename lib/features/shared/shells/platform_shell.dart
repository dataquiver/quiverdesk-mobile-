import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/design_system/design_system.dart';
import '../../../app/routes.dart';
import '../../../app/themes.dart';
import '../../../core/auth/token_storage.dart';

class PlatformShell extends StatelessWidget {
  final Widget child;
  const PlatformShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.platformDashboard,
    AppRoutes.businesses,
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexOf(loc);
    return i < 0 ? 0 : i;
  }

  void _showMore(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const _PlatformMoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _QDBottomNav(
        currentIndex: index,
        onDashboard: () => context.go(_tabs[0]),
        onBusinesses: () => context.go(_tabs[1]),
        onMore: () => _showMore(context),
      ),
    );
  }
}

// ── Premium Bottom Navigation Bar ──────────────────────────────────────────

class _QDBottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onDashboard;
  final VoidCallback onBusinesses;
  final VoidCallback onMore;

  const _QDBottomNav({
    required this.currentIndex,
    required this.onDashboard,
    required this.onBusinesses,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: QDPalette.surfaceCard,
        border: Border(top: BorderSide(color: QDPalette.neutral100, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.speed_outlined,
                activeIcon: Icons.speed_rounded,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: onDashboard,
              ),
              _NavItem(
                icon: Icons.business_outlined,
                activeIcon: Icons.business_rounded,
                label: 'Businesses',
                isActive: currentIndex == 1,
                onTap: onBusinesses,
              ),
              _NavItem(
                icon: Icons.apps_outlined,
                activeIcon: Icons.apps_rounded,
                label: 'More',
                isActive: false,
                onTap: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? QDPalette.primary100
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(QDRadius.full),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? QDPalette.primary600 : QDPalette.neutral400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? QDPalette.primary600 : QDPalette.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Platform More Bottom Sheet ──────────────────────────────────────────────

class _PlatformMoreSheet extends StatefulWidget {
  const _PlatformMoreSheet();

  @override
  State<_PlatformMoreSheet> createState() => _PlatformMoreSheetState();
}

class _PlatformMoreSheetState extends State<_PlatformMoreSheet> {
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name  = await TokenStorage.getUserName();
    final email = await TokenStorage.getUserEmail();
    if (mounted) setState(() { _userName = name; _userEmail = email; });
  }

  static const _featureItems = [
    _MoreItem(icon: Icons.card_membership_rounded, label: 'Plans',         route: AppRoutes.platformPlans),
    _MoreItem(icon: Icons.account_balance_wallet_rounded, label: 'Payments', route: AppRoutes.platformPayments),
    _MoreItem(icon: Icons.local_offer_rounded,     label: 'Vouchers',      route: AppRoutes.platformVouchers),
    _MoreItem(icon: Icons.extension_rounded,       label: 'Features',      route: AppRoutes.platformFeatures),
    _MoreItem(icon: Icons.bar_chart_rounded,       label: 'Reports',       route: AppRoutes.platformReports),
    _MoreItem(icon: Icons.notifications_rounded,   label: 'Notifications', route: AppRoutes.platformNotifications),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.25),
      decoration: const BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QDRadius.sheet),
        ),
        boxShadow: QDShadow.modal,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: QDPalette.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Admin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: QDPalette.neutral900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage platform settings',
                        style: TextStyle(
                          fontSize: 13,
                          color: QDPalette.neutral400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3-col feature grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: _featureItems
                  .map((item) => _FeatureTile(item: item))
                  .toList(),
            ),
          ),
          const SizedBox(height: QDSpace.x3),

          // Divider
          const Divider(height: 1, color: QDPalette.neutral100),

          // My Profile — full-width row
          _ProfileRow(
            name: _userName,
            email: _userEmail,
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.profile);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ── Feature Tile ─────────────────────────────────────────────────────────────

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _MoreItem({required this.icon, required this.label, required this.route});
}

class _FeatureTile extends StatelessWidget {
  final _MoreItem item;
  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final fc = QDPalette.featureColor(item.label);
    return Material(
      color: QDPalette.surfaceCard,
      borderRadius: BorderRadius.circular(QDRadius.card),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(QDRadius.card),
        splashColor: fc.background,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(QDRadius.card),
            border: Border.all(color: QDPalette.neutral100),
            boxShadow: QDShadow.card,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: fc.background,
                  borderRadius: BorderRadius.circular(QDRadius.iconChip),
                ),
                child: Icon(item.icon, color: fc.icon, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: QDPalette.neutral700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Row ──────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final String? name;
  final String? email;
  final VoidCallback onTap;

  const _ProfileRow({this.name, this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'Platform Admin';
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: QDSpace.screenPad, vertical: 14),
        child: Row(
          children: [
            QDAvatar(name: displayName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: QDPalette.neutral800,
                    ),
                  ),
                  if (email != null)
                    Text(
                      email!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: QDPalette.neutral400,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: QDPalette.neutral300, size: 20),
          ],
        ),
      ),
    );
  }
}
