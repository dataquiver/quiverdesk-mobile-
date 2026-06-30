import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/themes.dart';

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlatformMoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          if (i == 2) {
            _showMore(context);
          } else {
            context.go(_tabs[i]);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: QDColors.primary,
        unselectedItemColor: QDColors.textHint,
        backgroundColor: QDColors.surface,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_outlined),
            activeIcon: Icon(Icons.speed),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Businesses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _PlatformMoreSheet extends StatelessWidget {
  static const _items = [
    _MoreItem(icon: Icons.card_membership_outlined, label: 'Plans', route: AppRoutes.platformPlans),
    _MoreItem(icon: Icons.payments_outlined, label: 'Payments', route: AppRoutes.platformPayments),
    _MoreItem(icon: Icons.confirmation_number_outlined, label: 'Vouchers', route: AppRoutes.platformVouchers),
    _MoreItem(icon: Icons.extension_outlined, label: 'Features', route: AppRoutes.platformFeatures),
    _MoreItem(icon: Icons.bar_chart_outlined, label: 'Reports', route: AppRoutes.platformReports),
    _MoreItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.platformNotifications),
    _MoreItem(icon: Icons.person_outline, label: 'My Profile', route: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: QDColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Platform Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: _items.map((item) => _MoreTile(item: item)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _MoreItem({required this.icon, required this.label, required this.route});
}

class _MoreTile extends StatelessWidget {
  final _MoreItem item;
  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.push(item.route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: QDColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QDColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: QDColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: QDColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
