import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        backgroundColor: QDPalette.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _data?.businessName ?? 'Business Detail',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: QDPalette.neutral900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: QDPalette.neutral100),
        ),
      ),
      body: _isLoading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final b = _data!;
    return ListView(
      children: [
        // Header
        Container(
          color: QDPalette.surfaceCard,
          padding: const EdgeInsets.all(QDSpace.x5),
          child: Column(
            children: [
              QDAvatar(name: b.businessName, size: 72, radius: QDRadius.md),
              const SizedBox(height: 14),
              Text(
                b.businessName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: QDPalette.neutral900,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (b.businessType != null) ...[
                const SizedBox(height: 6),
                QDIndustryChip(type: b.businessType!),
              ],
              const SizedBox(height: 10),
              if (b.subscriptionStatus != null) ...[
                QDStatusChip.fromStatus(b.subscriptionStatus!),
                if (b.subscriptionPlan != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    b.subscriptionPlan!,
                    style: const TextStyle(fontSize: 12, color: QDPalette.neutral400,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('Staff', '${b.staffCount ?? 0}', QDPalette.primary500),
                  Container(width: 1, height: 36, color: QDPalette.neutral100),
                  _stat('Customers', '${b.customerCount ?? 0}', QDPalette.success500),
                  Container(width: 1, height: 36, color: QDPalette.neutral100),
                  _stat('Since', b.createdAt != null ? '${b.createdAt!.year}' : '—',
                      QDPalette.neutral400),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: QDPalette.neutral100),

        // Details
        Padding(
          padding: const EdgeInsets.all(QDSpace.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business Info',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: QDPalette.neutral800, letterSpacing: -0.2)),
              const SizedBox(height: QDSpace.cardGap),
              Container(
                decoration: BoxDecoration(
                  color: QDPalette.surfaceCard,
                  borderRadius: BorderRadius.circular(QDRadius.card),
                  border: Border.all(color: QDPalette.neutral100),
                  boxShadow: QDShadow.card,
                ),
                child: Column(
                  children: [
                    if (b.ownerName != null)
                      _infoRow(Icons.person_outline_rounded, 'Owner', b.ownerName!),
                    if (b.ownerEmail != null)
                      _divider(b.ownerName != null),
                    if (b.ownerEmail != null)
                      _infoRow(Icons.email_outlined, 'Email', b.ownerEmail!),
                    if (b.ownerPhone != null)
                      _divider(b.ownerEmail != null),
                    if (b.ownerPhone != null)
                      _infoRow(Icons.phone_outlined, 'Phone', b.ownerPhone!),
                    if (b.city != null || b.state != null)
                      _divider(b.ownerPhone != null),
                    if (b.city != null || b.state != null)
                      _infoRow(Icons.location_on_outlined, 'Location',
                          [b.city, b.state].where((s) => s != null).join(', ')),
                    if (b.createdAt != null)
                      _divider(b.city != null || b.state != null),
                    if (b.createdAt != null)
                      _infoRow(Icons.calendar_today_outlined, 'Joined',
                          QDDateUtils.formatDate(b.createdAt!)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color,
                letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: QDPalette.neutral400)),
      ],
    );
  }

  Widget _divider(bool show) {
    if (!show) return const SizedBox.shrink();
    return Container(height: 1, color: QDPalette.neutral100);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad, vertical: QDSpace.x3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: QDPalette.neutral300),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: QDPalette.neutral400, fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                    color: QDPalette.neutral800),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
