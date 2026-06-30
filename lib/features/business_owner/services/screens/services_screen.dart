import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_button.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _repo = BusinessRepository();
  List<ServiceModel>? _services;
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
      final data = await _repo.getServices(_tenantId!);
      if (mounted) setState(() { _services = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QDPalette.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(QDRadius.sheet))),
      builder: (_) => _AddServiceSheet(
        tenantId: _tenantId!,
        repo: _repo,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: FloatingActionButton(
        onPressed: _tenantId != null ? _showAddSheet : null,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : (_services?.isEmpty ?? true)
                  ? const QDEmptyState(
                      icon: Icons.spa_outlined,
                      title: 'No services yet',
                      subtitle: 'Add your first service',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: QDPalette.primary500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        itemCount: _services!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: QDSpace.cardGap),
                        itemBuilder: (_, i) =>
                            _ServiceCard(service: _services![i]),
                      ),
                    ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: QDPalette.primary50,
              borderRadius: BorderRadius.circular(QDRadius.iconChip),
            ),
            child: const Icon(Icons.spa_outlined, color: QDPalette.primary500, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.serviceName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: QDPalette.neutral800)),
                const SizedBox(height: 2),
                Text(
                    '${service.durationMinutes} min · ${service.category ?? "General"}',
                    style: const TextStyle(
                        color: QDPalette.neutral500, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(QDCurrency.format(service.price),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: QDPalette.primary600,
                      letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: service.isActive ? QDPalette.successBg : QDPalette.neutral50,
                  borderRadius: BorderRadius.circular(QDRadius.full),
                ),
                child: Text(
                  service.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    color: service.isActive
                        ? QDPalette.success500
                        : QDPalette.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddServiceSheet extends StatefulWidget {
  final int tenantId;
  final BusinessRepository repo;
  final VoidCallback onSaved;
  const _AddServiceSheet(
      {required this.tenantId, required this.repo, required this.onSaved});

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController(text: '30');
  String _category = 'HAIR';
  bool _loading = false;

  static const _categories = [
    'HAIR', 'SKIN', 'NAIL', 'MASSAGE', 'DENTAL', 'GENERAL'
  ];

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await widget.repo.createService(widget.tenantId, {
        'serviceName': _name.text.trim(),
        'price': double.parse(_price.text),
        'durationMinutes': int.parse(_duration.text),
        'category': _category,
        'isActive': true,
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: QDPalette.error500),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          QDSpace.screenPad, QDSpace.x5, QDSpace.screenPad,
          MediaQuery.of(context).viewInsets.bottom + QDSpace.x5),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: QDPalette.neutral900)),
            const SizedBox(height: QDSpace.x5),
            _field(_name, 'Service Name', required: true),
            Row(
              children: [
                Expanded(child: _field(_price, 'Price',
                    keyboardType: TextInputType.number, required: true)),
                const SizedBox(width: QDSpace.x3),
                Expanded(child: _field(_duration, 'Duration (min)',
                    keyboardType: TextInputType.number, required: true)),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: QDSpace.x5),
            QDButton(
                label: 'Save Service', isLoading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboardType, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: QDSpace.x3),
        child: TextFormField(
          controller: c,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null
              : null,
        ),
      );

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }
}
