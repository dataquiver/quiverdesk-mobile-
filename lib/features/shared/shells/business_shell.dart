import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/themes.dart';

class BusinessShell extends StatelessWidget {
  final Widget child;
  const BusinessShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.businessDashboard,
    AppRoutes.appointments,
    AppRoutes.customers,
    AppRoutes.billing,
    AppRoutes.reports,
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
      builder: (_) => _MoreSheet(),
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
          if (i == 5) {
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Billing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
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

class _MoreSheet extends StatelessWidget {
  static const _items = [
    _MoreItem(icon: Icons.design_services_outlined, label: 'Services', route: AppRoutes.businessServices),
    _MoreItem(icon: Icons.badge_outlined, label: 'Staff', route: AppRoutes.businessStaff),
    _MoreItem(icon: Icons.inventory_2_outlined, label: 'Inventory', route: AppRoutes.businessInventory),
    _MoreItem(icon: Icons.contacts_outlined, label: 'CRM', route: AppRoutes.businessCrm),
    _MoreItem(icon: Icons.card_membership_outlined, label: 'Memberships', route: AppRoutes.businessMemberships),
    _MoreItem(icon: Icons.star_outline, label: 'Feedback', route: AppRoutes.businessFeedback),
    _MoreItem(icon: Icons.subscriptions_outlined, label: 'Subscription', route: AppRoutes.businessSubscription),
    _MoreItem(icon: Icons.lock_outline, label: 'Change Password', route: AppRoutes.changePassword),
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
              child: Text('More Options',
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
