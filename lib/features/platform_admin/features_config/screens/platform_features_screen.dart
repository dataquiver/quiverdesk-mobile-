import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
      backgroundColor: QDPalette.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(QDRadius.sheet))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            QDSpace.screenPad, QDSpace.x5, QDSpace.screenPad,
            MediaQuery.of(ctx).viewInsets.bottom + QDSpace.x5),
        child: StatefulBuilder(
          builder: (ctx, setSt) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Feature',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: QDPalette.neutral900)),
                const SizedBox(height: QDSpace.x4),
                TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Feature Code (e.g. CRM_ACCESS)')),
                const SizedBox(height: QDSpace.x3),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Feature Name')),
                const SizedBox(height: QDSpace.x3),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description (optional)')),
                const SizedBox(height: QDSpace.x3),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['CORE', 'ADVANCED', 'PREMIUM']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSt(() => category = v ?? category),
                ),
                const SizedBox(height: QDSpace.x5),
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
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Add Feature'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String cat) => switch (cat) {
    'CORE'     => QDPalette.primary500,
    'ADVANCED' => QDPalette.success500,
    'PREMIUM'  => QDPalette.info500,
    _          => QDPalette.neutral400,
  };

  Color _categoryBg(String cat) => switch (cat) {
    'CORE'     => QDPalette.primary50,
    'ADVANCED' => QDPalette.successBg,
    'PREMIUM'  => QDPalette.infoBg,
    _          => QDPalette.neutral50,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(
        title: const Text('Features'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateForm,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const QDLoading()
          : _error != null
              ? QDError(message: _error!, onRetry: _load)
              : _features.isEmpty
                  ? const QDEmptyState(
                      title: 'No Features',
                      subtitle: 'No features configured.',
                      icon: Icons.tune_rounded,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: QDPalette.primary500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(QDSpace.screenPad),
                        itemCount: _features.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: QDSpace.x2),
                        itemBuilder: (_, i) {
                          final f = _features[i];
                          final catColor = _categoryColor(f.category);
                          final catBg = _categoryBg(f.category);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: QDSpace.cardPad,
                                vertical: QDSpace.x3),
                            decoration: BoxDecoration(
                              color: QDPalette.surfaceCard,
                              borderRadius:
                                  BorderRadius.circular(QDRadius.card),
                              border: Border.all(color: QDPalette.neutral100),
                              boxShadow: QDShadow.card,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: catBg,
                                              borderRadius: BorderRadius.circular(
                                                  QDRadius.xs),
                                            ),
                                            child: Text(f.category,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: catColor,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: f.isActive
                                                  ? QDPalette.successBg
                                                  : QDPalette.neutral50,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      QDRadius.full),
                                            ),
                                            child: Text(
                                              f.isActive ? 'Active' : 'Off',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: f.isActive
                                                    ? QDPalette.success500
                                                    : QDPalette.neutral400,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(f.featureName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: QDPalette.neutral800)),
                                      const SizedBox(height: 2),
                                      Text(f.featureCode,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: QDPalette.neutral400,
                                              fontWeight: FontWeight.w500)),
                                      if (f.description != null &&
                                          f.description!.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(f.description!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: QDPalette.neutral500,
                                                height: 1.3)),
                                      ],
                                      const SizedBox(height: 3),
                                      Text('${f.planCount} plans',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: QDPalette.neutral400)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: f.isActive,
                                  onChanged: (_) => _toggle(f),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
