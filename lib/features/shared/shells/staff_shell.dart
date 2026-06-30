import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/themes.dart';

class StaffShell extends StatelessWidget {
  final Widget child;
  const StaffShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.staffDashboard,
    AppRoutes.staffAppointments,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i]),
        selectedItemColor: QDColors.primary,
        unselectedItemColor: QDColors.textHint,
        backgroundColor: QDColors.surface,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'My Day',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Appointments',
          ),
        ],
      ),
    );
  }
}
