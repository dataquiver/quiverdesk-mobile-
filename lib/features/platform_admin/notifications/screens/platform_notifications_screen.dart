import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/platform_models.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../repository/platform_repository.dart';

class PlatformNotificationsScreen extends StatefulWidget {
  const PlatformNotificationsScreen({super.key});

  @override
  State<PlatformNotificationsScreen> createState() => _PlatformNotificationsScreenState();
}

class _PlatformNotificationsScreenState extends State<PlatformNotificationsScreen> {
  final _repo = PlatformRepository();
  List<PlatformNotificationModel> _notifications = [];
  NotificationSummaryModel? _summary;
  bool _loading = true;
  String? _error;
  bool _unresolvedOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.getNotifications(unresolvedOnly: _unresolvedOnly),
        _repo.getNotificationSummary(),
      ]);
      setState(() {
        _notifications = results[0] as List<PlatformNotificationModel>;
        _summary = results[1] as NotificationSummaryModel;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markRead(PlatformNotificationModel n) async {
    try {
      await _repo.markNotificationRead(n.platformNotificationId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _resolve(PlatformNotificationModel n) async {
    try {
      await _repo.resolveNotification(n.platformNotificationId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateAlerts() async {
    try {
      await _repo.generateAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerts generated.')));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'CRITICAL': return Colors.red;
      case 'WARNING': return Colors.orange;
      case 'INFO': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _typeIcon(String t) {
    switch (t) {
      case 'TRIAL_EXPIRING': return '⏰';
      case 'SUBSCRIPTION_EXPIRING': return '📅';
      case 'FAILED_PAYMENT': return '❌';
      case 'NEW_BUSINESS': return '🎉';
      case 'BUSINESS_INACTIVE': return '😴';
      default: return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate Alerts',
            onPressed: _generateAlerts,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    if (_summary != null) _SummaryBar(summary: _summary!),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('Show unresolved only', style: TextStyle(fontSize: 13)),
                          const Spacer(),
                          Switch(
                            value: _unresolvedOnly,
                            onChanged: (v) { setState(() => _unresolvedOnly = v); _load(); },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _notifications.isEmpty
                          ? const QDEmptyState(title: 'No Notifications', subtitle: 'All clear.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _notifications.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _NotifCard(
                                  notif: _notifications[i],
                                  severityColor: _severityColor(_notifications[i].severity),
                                  typeIcon: _typeIcon(_notifications[i].notificationType),
                                  onMarkRead: () => _markRead(_notifications[i]),
                                  onResolve: () => _resolve(_notifications[i]),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final NotificationSummaryModel summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SumStat(label: 'Unread', value: '${summary.totalUnread}', color: Colors.black87),
          _SumStat(label: 'Critical', value: '${summary.critical}', color: Colors.red),
          _SumStat(label: 'Warnings', value: '${summary.warnings}', color: Colors.orange),
          _SumStat(label: 'Info', value: '${summary.info}', color: Colors.blue),
        ],
      ),
    );
  }
}

class _SumStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SumStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  final PlatformNotificationModel notif;
  final Color severityColor;
  final String typeIcon;
  final VoidCallback onMarkRead;
  final VoidCallback onResolve;

  const _NotifCard({
    required this.notif,
    required this.severityColor,
    required this.typeIcon,
    required this.onMarkRead,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(typeIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(notif.severity, style: TextStyle(fontSize: 11, color: severityColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(notif.message, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            if (notif.businessName != null) ...[
              const SizedBox(height: 4),
              Text(notif.businessName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(fmt.format(notif.createdOn), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Spacer(),
                if (!notif.isRead)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: onMarkRead,
                    child: const Text('Mark Read', style: TextStyle(fontSize: 12)),
                  ),
                if (!notif.isResolved)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: onResolve,
                    child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
