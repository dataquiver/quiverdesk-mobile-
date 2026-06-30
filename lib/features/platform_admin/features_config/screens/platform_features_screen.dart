import 'package:flutter/material.dart';
import '../../../../app/themes.dart';
import '../../../../core/models/platform_models.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../repository/platform_repository.dart';

class PlatformFeaturesScreen extends StatefulWidget {
  const PlatformFeaturesScreen({super.key});

  @override
  State<PlatformFeaturesScreen> createState() => _PlatformFeaturesScreenState();
}

class _PlatformFeaturesScreenState extends State<PlatformFeaturesScreen> {
  final _repo = PlatformRepository();
  List<PlatformFeatureModel> _features = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _repo.getFeatures();
      setState(() { _features = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggle(PlatformFeatureModel f) async {
    try {
      if (f.isActive) {
        await _repo.deactivateFeature(f.featureId);
      } else {
        await _repo.activateFeature(f.featureId);
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCreateForm() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'CORE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(builder: (ctx, setSt) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Feature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Feature Code (e.g. CRM_ACCESS)')),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Feature Name')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['CORE', 'ADVANCED', 'PREMIUM'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSt(() => category = v ?? category),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
                  try {
                    await _repo.createFeature({
                      'featureCode': codeCtrl.text.trim(),
                      'featureName': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'category': category,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Add Feature'),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'CORE': return Colors.blue;
      case 'ADVANCED': return Colors.green;
      case 'PREMIUM': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateForm,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _features.isEmpty
                  ? const QDEmptyState(title: 'No Features', subtitle: 'No features configured.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _features.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final f = _features[i];
                          final catColor = _categoryColor(f.category);
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: catColor.withAlpha(25),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(f.category,
                                                  style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: f.isActive ? QDColors.successLight : QDColors.divider,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                f.isActive ? 'Active' : 'Off',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: f.isActive ? QDColors.success : QDColors.textHint,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(f.featureName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(f.featureCode, style: const TextStyle(fontSize: 11, color: QDColors.textHint)),
                                        if (f.description != null && f.description!.isNotEmpty)
                                          Text(f.description!, style: const TextStyle(fontSize: 12, color: QDColors.textSecondary)),
                                        Text('${f.planCount} plans', style: const TextStyle(fontSize: 11, color: QDColors.textHint)),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: f.isActive,
                                    onChanged: (_) => _toggle(f),
                                    activeColor: QDColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
