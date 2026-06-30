import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _repo = BusinessRepository();
  List<Map<String, dynamic>>? _followUps;
  List<Map<String, dynamic>>? _campaigns;
  bool _loading = true;
  String? _error;
  int? _tenantId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = await TokenStorage.getBusinessId();
    _tenantId = id != null ? int.tryParse(id) : null;
    await _load();
  }

  Future<void> _load() async {
    if (_tenantId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.getCrmFollowUps(_tenantId!).catchError((_) => <Map<String, dynamic>>[]),
        _repo.getCrmCampaigns(_tenantId!).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _followUps = results[0];
          _campaigns = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: const Text('CRM'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Follow-ups'), Tab(text: 'Campaigns')],
        ),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _FollowUpsList(items: _followUps ?? []),
                    _CampaignsList(items: _campaigns ?? []),
                  ],
                ),
    );
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
}

class _FollowUpsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _FollowUpsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const QDEmptyState(
        icon: Icons.follow_the_signs_outlined,
        title: 'No follow-ups',
        subtitle: 'Customer follow-ups will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final f = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: QDColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QDColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, color: QDColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['customerName'] as String? ?? 'Customer',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(f['type'] as String? ?? '',
                        style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Text(f['scheduledDate'] as String? ?? '',
                  style: const TextStyle(fontSize: 12, color: QDColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

class _CampaignsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _CampaignsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const QDEmptyState(
        icon: Icons.campaign_outlined,
        title: 'No campaigns',
        subtitle: 'Marketing campaigns will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: QDColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QDColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined, color: QDColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['campaignName'] as String? ?? 'Campaign',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${c['channel'] ?? ''} · ${c['sentCount'] ?? 0} sent',
                        style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Text(c['status'] as String? ?? '',
                  style: const TextStyle(fontSize: 12, color: QDColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
