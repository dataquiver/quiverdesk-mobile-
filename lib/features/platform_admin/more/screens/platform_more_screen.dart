import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../app/themes.dart';

class PlatformMoreScreen extends StatelessWidget {
  const PlatformMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(
        icon: Icons.discount_outlined,
        label: 'Vouchers',
        description: 'Discount codes & promos',
        color: Colors.purple,
        route: AppRoutes.platformVouchers,
      ),
      _MoreItem(
        icon: Icons.extension_outlined,
        label: 'Features',
        description: 'Feature flags & limits',
        color: Colors.teal,
        route: AppRoutes.platformFeatures,
      ),
      _MoreItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        description: 'Platform alerts',
        color: Colors.orange,
        route: AppRoutes.platformNotifications,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.description, style: const TextStyle(color: QDColors.textSecondary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: QDColors.textHint),
              onTap: () => context.go(item.route),
            ),
          );
        },
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final String route;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.route,
  });
}
