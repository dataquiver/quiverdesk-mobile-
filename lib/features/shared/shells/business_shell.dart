import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/design_system/design_system.dart';
import '../../../app/routes.dart';
import '../../../core/auth/token_storage.dart';

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
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const _BusinessMoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _QDBottomNav(
        currentIndex: index,
        onTap: (i) {
          if (i == 5) {
            _showMore(context);
          } else {
            context.go(_tabs[i]);
          }
        },
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────

class _QDBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _QDBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavDef(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    _NavDef(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Appointments'),
    _NavDef(Icons.people_outline_rounded, Icons.people_rounded, 'Customers'),
    _NavDef(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Billing'),
    _NavDef(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Reports'),
    _NavDef(Icons.apps_outlined, Icons.apps_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QDPalette.surfaceCard,
        border: Border(top: BorderSide(color: QDPalette.neutral100)),
        boxShadow: [
          BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: List.generate(
              _items.length,
              (i) => _NavItem(
                def: _items[i],
                isActive: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDef(this.icon, this.activeIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final _NavDef def;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.def, required this.isActive, required this.onTap});

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
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? QDPalette.primary100 : Colors.transparent,
                borderRadius: BorderRadius.circular(QDRadius.full),
              ),
              child: Icon(
                isActive ? def.activeIcon : def.icon,
                size: 20,
                color: isActive ? QDPalette.primary600 : QDPalette.neutral400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              def.label,
              style: TextStyle(
                fontSize: 10,
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

// ── Business More Sheet ───────────────────────────────────────────────────────

class _BusinessMoreSheet extends StatefulWidget {
  const _BusinessMoreSheet();

  @override
  State<_BusinessMoreSheet> createState() => _BusinessMoreSheetState();
}

class _BusinessMoreSheetState extends State<_BusinessMoreSheet> {
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await TokenStorage.getUserName();
    final email = await TokenStorage.getUserEmail();
    if (mounted) setState(() { _userName = name; _userEmail = email; });
  }

  static const _items = [
    _MoreItem(Icons.design_services_rounded,  'Services',        AppRoutes.businessServices),
    _MoreItem(Icons.badge_rounded,            'Staff',           AppRoutes.businessStaff),
    _MoreItem(Icons.inventory_2_rounded,      'Inventory',       AppRoutes.businessInventory),
    _MoreItem(Icons.contacts_rounded,         'CRM',             AppRoutes.businessCrm),
    _MoreItem(Icons.card_membership_rounded,  'Memberships',     AppRoutes.businessMemberships),
    _MoreItem(Icons.star_rounded,             'Feedback',        AppRoutes.businessFeedback),
    _MoreItem(Icons.subscriptions_rounded,    'Subscription',    AppRoutes.businessSubscription),
    _MoreItem(Icons.lock_rounded,             'Change Password', AppRoutes.changePassword),
    _MoreItem(Icons.person_rounded,           'My Profile',      AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
      decoration: const BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(QDRadius.sheet)),
        boxShadow: QDShadow.modal,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: QDPalette.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: QDSpace.screenPad),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('More Options',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                          color: QDPalette.neutral900, letterSpacing: -0.3)),
                  SizedBox(height: 2),
                  Text('Business management tools',
                      style: TextStyle(fontSize: 13, color: QDPalette.neutral400)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: _items.map((item) => _FeatureTile(item: item)).toList(),
            ),
          ),
          const SizedBox(height: QDSpace.x3),
          const Divider(height: 1, color: QDPalette.neutral100),
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

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _MoreItem(this.icon, this.label, this.route);
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: fc.background,
                  borderRadius: BorderRadius.circular(QDRadius.iconChip),
                ),
                child: Icon(item.icon, color: fc.icon, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
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

class _ProfileRow extends StatelessWidget {
  final String? name;
  final String? email;
  final VoidCallback onTap;

  const _ProfileRow({this.name, this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'Business Owner';
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad, vertical: 14),
        child: Row(
          children: [
            QDAvatar(name: displayName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: QDPalette.neutral800)),
                  if (email != null)
                    Text(email!,
                        style: const TextStyle(fontSize: 12, color: QDPalette.neutral400)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: QDPalette.neutral300, size: 20),
          ],
        ),
      ),
    );
  }
}
