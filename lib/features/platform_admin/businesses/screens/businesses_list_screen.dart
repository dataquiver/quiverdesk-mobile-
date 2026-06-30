import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../app/themes.dart';
import '../../../../core/models/business_model.dart';
import '../../../../core/widgets/qd_empty_state.dart';
import '../../../../core/widgets/qd_error.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/platform_repository.dart';

class BusinessesListScreen extends StatefulWidget {
  const BusinessesListScreen({super.key});

  @override
  State<BusinessesListScreen> createState() => _BusinessesListScreenState();
}

class _BusinessesListScreenState extends State<BusinessesListScreen> {
  final _repo = PlatformRepository();
  final _searchCtrl = TextEditingController();
  List<BusinessModel> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await _repo.getBusinesses(search: search);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: QDPalette.surfaceBackground,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(count: _items.length, isLoading: _isLoading),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                QDSpace.screenPad, 0, QDSpace.screenPad, QDSpace.x3),
              child: QDSearchBar(
                controller: _searchCtrl,
                placeholder: 'Search businesses...',
                onSubmitted: (v) => _load(search: v.trim()),
                onChanged: (v) { if (v.isEmpty) _load(); },
                onClear: _load,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const QDLoading()
                  : _error != null
                      ? QDError(message: _error!, onRetry: _load)
                      : _items.isEmpty
                          ? const QDEmptyState(
                              title: 'No businesses yet',
                              subtitle: 'Businesses registered on the platform will appear here.',
                              icon: Icons.business_outlined,
                            )
                          : RefreshIndicator(
                              color: QDPalette.primary500,
                              backgroundColor: QDPalette.surfaceCard,
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  QDSpace.screenPad, 4,
                                  QDSpace.screenPad, QDSpace.x6),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: QDSpace.x2),
                                itemBuilder: (_, i) => _BusinessCard(
                                  business: _items[i],
                                  onTap: () => context.push(
                                      '/platform/businesses/${_items[i].tenantId}'),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header (title + count) ──────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int count;
  final bool isLoading;

  const _Header({required this.count, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: QDPalette.surfaceCard,
      padding: EdgeInsets.fromLTRB(
          QDSpace.screenPad, top + QDSpace.x3, QDSpace.screenPad, QDSpace.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Businesses',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: QDPalette.neutral900,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                if (!isLoading) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? "business" : "businesses"} on the platform',
                    style: const TextStyle(
                      fontSize: 13,
                      color: QDPalette.neutral400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Business Card ───────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback onTap;

  const _BusinessCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = business;
    final hasLocation = b.city != null || b.state != null;
    final location = [b.city, b.state].whereType<String>().join(', ');

    return Material(
      color: QDPalette.surfaceCard,
      borderRadius: BorderRadius.circular(QDRadius.card),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(QDRadius.card),
        splashColor: QDPalette.primary50,
        highlightColor: QDPalette.primary50.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(QDRadius.card),
            border: Border.all(color: QDPalette.neutral100, width: 1),
            boxShadow: QDShadow.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              QDAvatar(name: b.businessName, size: 46),
              const SizedBox(width: QDSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.businessName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: QDPalette.neutral800,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (b.businessType != null)
                          QDIndustryChip(type: b.businessType!),
                        if (b.businessType != null && hasLocation)
                          const SizedBox(width: 6),
                        if (hasLocation)
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: QDPalette.neutral400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    if (b.ownerName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        b.ownerName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: QDPalette.neutral400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: QDSpace.x2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (b.subscriptionStatus != null)
                    QDStatusChip.fromStatus(b.subscriptionStatus!),
                  if (b.subscriptionPlan != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      b.subscriptionPlan!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: QDPalette.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: QDSpace.x1),
              const Icon(
                Icons.chevron_right_rounded,
                color: QDPalette.neutral300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
