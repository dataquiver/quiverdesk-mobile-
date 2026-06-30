import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/models/business_model.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/platform_repository.dart';

class BusinessDetailScreen extends StatefulWidget {
  final int businessId;
  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  final _repo = PlatformRepository();
  BusinessModel? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _repo.getBusinessDetail(widget.businessId);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _statusColor(String? s) => switch (s?.toUpperCase()) {
    'ACTIVE' => QDColors.success,
    'TRIAL' => QDColors.warning,
    'EXPIRED' => QDColors.error,
    'SUSPENDED' => QDColors.cancelled,
    _ => QDColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: Text(_data?.businessName ?? 'Business Detail')),
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final b = _data!;
    final sc = _statusColor(b.subscriptionStatus);

    return ListView(
      children: [
        // Header
        Container(
          color: QDColors.surface,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: QDColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    b.businessName.isNotEmpty ? b.businessName[0].toUpperCase() : 'B',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w700, color: QDColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(b.businessName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: QDColors.textPrimary),
                  textAlign: TextAlign.center),
              if (b.businessType != null) ...[
                const SizedBox(height: 4),
                Text(b.businessType!,
                    style: const TextStyle(color: QDColors.textSecondary, fontSize: 14)),
              ],
              const SizedBox(height: 10),
              if (b.subscriptionStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sc.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${b.subscriptionPlan ?? ''} · ${b.subscriptionStatus}',
                    style: TextStyle(color: sc, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('Staff', '${b.staffCount ?? 0}', QDColors.primary),
                  _divider(),
                  _stat('Customers', '${b.customerCount ?? 0}', QDColors.secondary),
                  _divider(),
                  _stat('Since', b.createdAt != null
                      ? '${b.createdAt!.year}'
                      : '—', QDColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business Info',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _infoSection([
                if (b.ownerName != null)
                  _row(Icons.person_outline, 'Owner', b.ownerName!),
                if (b.ownerEmail != null)
                  _row(Icons.email_outlined, 'Email', b.ownerEmail!),
                if (b.ownerPhone != null)
                  _row(Icons.phone_outlined, 'Phone', b.ownerPhone!),
                if (b.city != null || b.state != null)
                  _row(Icons.location_on_outlined, 'Location',
                      [b.city, b.state].where((s) => s != null).join(', ')),
                if (b.createdAt != null)
                  _row(Icons.calendar_today_outlined, 'Joined',
                      QDDateUtils.formatDate(b.createdAt!)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: QDColors.textSecondary)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: QDColors.divider);

  Widget _infoSection(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: QDColors.textHint),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: QDColors.textPrimary),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
