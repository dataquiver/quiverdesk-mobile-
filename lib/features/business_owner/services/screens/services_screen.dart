import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
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
      backgroundColor: QDColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: FloatingActionButton(
        onPressed: _tenantId != null ? _showAddSheet : null,
        backgroundColor: QDColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _services!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ServiceCard(service: _services![i]),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: QDColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.spa_outlined, color: QDColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${service.durationMinutes} min · ${service.category ?? "General"}',
                    style: const TextStyle(color: QDColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(QDCurrency.format(service.price),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: QDColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: service.isActive ? QDColors.success.withValues(alpha: 0.1) : QDColors.textHint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  service.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    color: service.isActive ? QDColors.success : QDColors.textHint,
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
  const _AddServiceSheet({required this.tenantId, required this.repo, required this.onSaved});

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

  static const _categories = ['HAIR', 'SKIN', 'NAIL', 'MASSAGE', 'DENTAL', 'GENERAL'];

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
          SnackBar(content: Text(e.toString()), backgroundColor: QDColors.error),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _field(_name, 'Service Name', required: true),
            Row(
              children: [
                Expanded(child: _field(_price, 'Price', keyboardType: TextInputType.number, required: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_duration, 'Duration (min)', keyboardType: TextInputType.number, required: true)),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 20),
            QDButton(label: 'Save Service', isLoading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboardType, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: required ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null : null,
        ),
      );

  @override
  void dispose() { _name.dispose(); _price.dispose(); _duration.dispose(); super.dispose(); }
}
