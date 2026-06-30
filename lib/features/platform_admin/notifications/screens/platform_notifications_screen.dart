import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/models/platform_models.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../repository/platform_repository.dart';

class PlatformNotificationsScreen extends StatefulWidget {
  const PlatformNotificationsScreen({super.key});

  @override
  State<PlatformNotificationsScreen> createState() =>
      _PlatformNotificationsScreenState();
}

class _PlatformNotificationsScreenState
    extends State<PlatformNotificationsScreen> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _resolve(PlatformNotificationModel n) async {
    try {
      await _repo.resolveNotification(n.platformNotificationId);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _generateAlerts() async {
    try {
      await _repo.generateAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Alerts generated.')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _severityColor(String s) => switch (s.toUpperCase()) {
    'CRITICAL' => QDPalette.error500,
    'WARNING'  => QDPalette.warning500,
    'INFO'     => QDPalette.info500,
    _          => QDPalette.neutral400,
  };

  Color _severityBg(String s) => switch (s.toUpperCase()) {
    'CRITICAL' => QDPalette.errorBg,
    'WARNING'  => QDPalette.warningBg,
    'INFO'     => QDPalette.infoBg,
    _          => QDPalette.neutral50,
  };

  IconData _typeIconData(String t) => switch (t) {
    'TRIAL_EXPIRING'       => Icons.timer_outlined,
    'SUBSCRIPTION_EXPIRING'=> Icons.calendar_today_outlined,
    'FAILED_PAYMENT'       => Icons.error_outline_rounded,
    'NEW_BUSINESS'         => Icons.celebration_outlined,
    'BUSINESS_INACTIVE'    => Icons.bedtime_outlined,
    _                      => Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Generate Alerts',
            onPressed: _generateAlerts,
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    if (_summary != null) _SummaryBar(summary: _summary!),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: QDSpace.screenPad, vertical: 10),
                      decoration: BoxDecoration(
                        color: QDPalette.surfaceCard,
                        border: const Border(
                            bottom: BorderSide(color: QDPalette.neutral100)),
                      ),
                      child: Row(
                        children: [
                          const Text('Unresolved only',
                              style: TextStyle(fontSize: 13,
                                  color: QDPalette.neutral700,
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Switch(
                            value: _unresolvedOnly,
                            onChanged: (v) {
                              setState(() => _unresolvedOnly = v);
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _notifications.isEmpty
                          ? const QDEmptyState(
                              title: 'No Notifications',
                              subtitle: 'All clear — no pending alerts.',
                              icon: Icons.notifications_off_outlined,
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: QDPalette.primary500,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(QDSpace.screenPad),
                                itemCount: _notifications.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: QDSpace.x2),
                                itemBuilder: (_, i) => _NotifCard(
                                  notif: _notifications[i],
                                  severityColor:
                                      _severityColor(_notifications[i].severity),
                                  severityBg:
                                      _severityBg(_notifications[i].severity),
                                  typeIcon:
                                      _typeIconData(_notifications[i].notificationType),
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
      margin: const EdgeInsets.all(QDSpace.screenPad),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SumStat(label: 'Unread', value: '${summary.totalUnread}',
              color: QDPalette.neutral800),
          _vDivider(),
          _SumStat(label: 'Critical', value: '${summary.critical}',
              color: QDPalette.error500),
          _vDivider(),
          _SumStat(label: 'Warnings', value: '${summary.warnings}',
              color: QDPalette.warning500),
          _vDivider(),
          _SumStat(label: 'Info', value: '${summary.info}',
              color: QDPalette.info500),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: QDPalette.neutral100);
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
        Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color,
                letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: QDPalette.neutral400)),
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  final PlatformNotificationModel notif;
  final Color severityColor;
  final Color severityBg;
  final IconData typeIcon;
  final VoidCallback onMarkRead;
  final VoidCallback onResolve;

  const _NotifCard({
    required this.notif,
    required this.severityColor,
    required this.severityBg,
    required this.typeIcon,
    required this.onMarkRead,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, HH:mm');
    return Container(
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: notif.isRead ? QDPalette.neutral100 : severityColor.withValues(alpha: 0.25)),
        boxShadow: QDShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(QDRadius.iconChip),
                ),
                child: Icon(typeIcon, size: 18, color: severityColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                    fontSize: 14,
                    color: QDPalette.neutral800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(QDRadius.xs),
                ),
                child: Text(notif.severity,
                    style: TextStyle(fontSize: 10, color: severityColor,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(notif.message,
              style: const TextStyle(fontSize: 13, color: QDPalette.neutral700,
                  height: 1.4)),
          if (notif.businessName != null) ...[
            const SizedBox(height: 4),
            Text(notif.businessName!,
                style: const TextStyle(fontSize: 12, color: QDPalette.neutral400)),
          ],
          const SizedBox(height: 10),
          Container(height: 1, color: QDPalette.neutral100),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: QDPalette.neutral300),
              const SizedBox(width: 4),
              Text(fmt.format(notif.createdOn),
                  style: const TextStyle(fontSize: 11, color: QDPalette.neutral400)),
              const Spacer(),
              if (!notif.isRead)
                _ActionBtn(label: 'Mark Read', onTap: onMarkRead),
              if (!notif.isResolved)
                _ActionBtn(label: 'Resolve', onTap: onResolve),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: QDPalette.primary50,
          borderRadius: BorderRadius.circular(QDRadius.xs),
          border: Border.all(color: QDPalette.primary100),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: QDPalette.primary600,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
