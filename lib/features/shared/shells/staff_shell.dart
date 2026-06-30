import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/design_system/design_system.dart';
import '../../../app/routes.dart';

class StaffShell extends StatelessWidget {
  final Widget child;
  const StaffShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.staffDashboard,
    AppRoutes.staffAppointments,
    AppRoutes.staffCustomers,
    AppRoutes.staffBilling,
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexOf(loc);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _StaffBottomNav(
        currentIndex: index,
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(_tabs[i]);
        },
      ),
    );
  }
}

class _StaffBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _StaffBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavDef(Icons.today_outlined,        Icons.today_rounded,         'My Day'),
    _NavDef(Icons.event_note_outlined,   Icons.event_note_rounded,    'Appointments'),
    _NavDef(Icons.people_outline_rounded,Icons.people_rounded,        'Customers'),
    _NavDef(Icons.receipt_long_outlined, Icons.receipt_long_rounded,  'Billing'),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? QDPalette.primary100 : Colors.transparent,
                borderRadius: BorderRadius.circular(QDRadius.full),
              ),
              child: Icon(
                isActive ? def.activeIcon : def.icon,
                size: 22,
                color: isActive ? QDPalette.primary600 : QDPalette.neutral400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              def.label,
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
