import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/qd_button.dart';
import '../../../../core/widgets/qd_loading.dart';
import '../../repository/business_repository.dart';

class WalkInBillingScreen extends StatefulWidget {
  const WalkInBillingScreen({super.key});

  @override
  State<WalkInBillingScreen> createState() => _WalkInBillingScreenState();
}

class _WalkInBillingScreenState extends State<WalkInBillingScreen> {
  final _repo = BusinessRepository();
  final _formKey = GlobalKey<FormState>();

  int? _tenantId;
  bool _loadingData = true;
  bool _submitting = false;

  List<ServiceModel> _services = [];

  // Customer
  int? _selectedCustomerId;
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  // Line items
  final List<_ServiceLine> _serviceLines = [];
  final List<_CustomItem> _customItems = [];

  // Totals
  final _discountAmtCtrl = TextEditingController(text: '0');
  final _discountPctCtrl = TextEditingController(text: '0');
  String _gstType = 'NONE';
  double _taxPct = 0;

  // Payment
  final List<_PaymentEntry> _payments = [_PaymentEntry()];

  static const _gstOptions = ['NONE', 'CGST_SGST', 'IGST'];
  static const _taxPresets = [0.0, 5.0, 12.0, 18.0, 28.0];
  static const _paymentMethods = ['CASH', 'CARD', 'UPI', 'BANK_TRANSFER'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _discountAmtCtrl.dispose();
    _discountPctCtrl.dispose();
    for (final p in _payments) {
      p.amountCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final id = await TokenStorage.getBusinessId();
    _tenantId = id != null ? int.tryParse(id) : null;
    if (_tenantId == null) {
      if (mounted) setState(() => _loadingData = false);
      return;
    }
    try {
      final svcs = await _repo.getServices(_tenantId!);
      if (mounted) {
        setState(() {
          _services = svcs;
          _loadingData = false;
          if (_serviceLines.isEmpty) _serviceLines.add(_ServiceLine());
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  double get _subtotal {
    double s = 0;
    for (final l in _serviceLines) {
      if (l.service != null) s += l.service!.price * l.quantity;
    }
    for (final c in _customItems) {
      final p = double.tryParse(c.priceCtrl.text) ?? 0;
      final q = int.tryParse(c.qtyCtrl.text) ?? 1;
      s += p * q;
    }
    return s;
  }

  double get _discountAmt {
    final pct = double.tryParse(_discountPctCtrl.text) ?? 0;
    if (pct > 0) return _subtotal * pct / 100;
    return double.tryParse(_discountAmtCtrl.text) ?? 0;
  }

  double get _taxable => _subtotal - _discountAmt;
  double get _taxAmt => _taxPct > 0 ? _taxable * _taxPct / 100 : 0;
  double get _total => _taxable + _taxAmt;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_serviceLines.every((l) => l.service == null) && _customItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one service or item')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        if (_selectedCustomerId != null) 'customerPersonId': _selectedCustomerId,
        if (_customerNameCtrl.text.trim().isNotEmpty)
          'customerName': _customerNameCtrl.text.trim(),
        if (_customerPhoneCtrl.text.trim().isNotEmpty)
          'customerPhone': _customerPhoneCtrl.text.trim(),
        'services': _serviceLines
            .where((l) => l.service != null)
            .map((l) => {
                  'serviceId': l.service!.serviceId,
                  'quantity': l.quantity,
                })
            .toList(),
        'customItems': _customItems
            .map((c) => {
                  'description': c.descCtrl.text.trim(),
                  'quantity': int.tryParse(c.qtyCtrl.text) ?? 1,
                  'unitPrice': double.tryParse(c.priceCtrl.text) ?? 0,
                })
            .where((c) => (c['description'] as String).isNotEmpty)
            .toList(),
        'discountAmount': double.tryParse(_discountAmtCtrl.text) ?? 0,
        'discountPercent': double.tryParse(_discountPctCtrl.text) ?? 0,
        'taxPercent': _taxPct,
        'gstType': _gstType,
        'payments': _payments
            .where((p) => (double.tryParse(p.amountCtrl.text) ?? 0) > 0)
            .map((p) => {
                  'amount': double.tryParse(p.amountCtrl.text) ?? 0,
                  'paymentMethod': p.method,
                })
            .toList(),
      };

      final result = await _repo.createWalkInBill(_tenantId!, payload);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _showSuccessSheet(result);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: QDPalette.error500,
          ),
        );
      }
    }
  }

  void _showSuccessSheet(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: QDPalette.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(QDRadius.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: QDPalette.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: QDPalette.success500, size: 42),
            ),
            const SizedBox(height: 16),
            const Text('Bill Created!',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: QDPalette.neutral900)),
            const SizedBox(height: 6),
            Text(
              result['invoiceNumber'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 14, color: QDPalette.neutral500),
            ),
            const SizedBox(height: 12),
            _ReceiptRow(
                label: 'Customer',
                value: result['customerName'] as String?),
            _ReceiptRow(
                label: 'Total',
                value: QDCurrency.format(
                    ((result['totalAmount'] as num?)?.toDouble() ?? 0))),
            _ReceiptRow(
                label: 'Paid',
                value: QDCurrency.format(
                    ((result['paidAmount'] as num?)?.toDouble() ?? 0))),
            _ReceiptRow(label: 'Status', value: result['status'] as String?),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('View Bills'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QDPalette.primary500,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedCustomerId = null;
                        _customerNameCtrl.clear();
                        _customerPhoneCtrl.clear();
                        _serviceLines
                          ..clear()
                          ..add(_ServiceLine());
                        _customItems.clear();
                        _discountAmtCtrl.text = '0';
                        _discountPctCtrl.text = '0';
                        _taxPct = 0;
                        _gstType = 'NONE';
                        _payments
                          ..clear()
                          ..add(_PaymentEntry());
                        _submitting = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('Walk-in Billing')),
      body: _loadingData
          ? const QDLoading()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(QDSpace.screenPad),
                children: [
                  _sectionHeader('Customer'),
                  _CustomerSection(
                    tenantId: _tenantId!,
                    repo: _repo,
                    nameCtrl: _customerNameCtrl,
                    phoneCtrl: _customerPhoneCtrl,
                    onCustomerSelected: (id) =>
                        setState(() => _selectedCustomerId = id),
                  ),
                  const SizedBox(height: QDSpace.sectionGap),

                  _sectionHeader('Services'),
                  if (_services.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: QDSpace.cardGap),
                      padding: const EdgeInsets.all(QDSpace.cardPad),
                      decoration: BoxDecoration(
                        color: QDPalette.warningBg,
                        borderRadius: BorderRadius.circular(QDRadius.card),
                        border: Border.all(color: QDPalette.warning500.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: QDPalette.warning500, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No services set up yet. Use Custom Items below to add any item manually.',
                              style: const TextStyle(fontSize: 13, color: QDPalette.neutral700, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_services.isNotEmpty)
                  ..._serviceLines.asMap().entries.map((e) {
                    final i = e.key;
                    final line = e.value;
                    return _ServiceLineRow(
                      key: ValueKey('svc_$i'),
                      line: line,
                      services: _services,
                      onRemove: _serviceLines.length > 1
                          ? () => setState(() => _serviceLines.removeAt(i))
                          : null,
                      onChanged: () => setState(() {}),
                    );
                  }),
                  if (_services.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Service'),
                    onPressed: () =>
                        setState(() => _serviceLines.add(_ServiceLine())),
                  ),
                  const SizedBox(height: QDSpace.cardGap),

                  _sectionHeader('Custom Items (optional)'),
                  ..._customItems.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return _CustomItemRow(
                      key: ValueKey('item_$i'),
                      item: item,
                      onRemove: () =>
                          setState(() => _customItems.removeAt(i)),
                      onChanged: () => setState(() {}),
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Custom Item'),
                    onPressed: () =>
                        setState(() => _customItems.add(_CustomItem())),
                  ),
                  const SizedBox(height: QDSpace.sectionGap),

                  _sectionHeader('Discount & Tax'),
                  _TotalsSection(
                    discountAmtCtrl: _discountAmtCtrl,
                    discountPctCtrl: _discountPctCtrl,
                    gstType: _gstType,
                    taxPct: _taxPct,
                    gstOptions: _gstOptions,
                    taxPresets: _taxPresets,
                    onGstChanged: (v) => setState(() => _gstType = v),
                    onTaxChanged: (v) => setState(() => _taxPct = v),
                    onChanged: () => setState(() {}),
                  ),

                  // Running total
                  _TotalBanner(
                    subtotal: _subtotal,
                    discount: _discountAmt,
                    tax: _taxAmt,
                    total: _total,
                  ),
                  const SizedBox(height: QDSpace.sectionGap),

                  _sectionHeader('Payment (leave empty to invoice later)'),
                  ..._payments.asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    return _PaymentRow(
                      key: ValueKey('pay_$i'),
                      entry: entry,
                      methods: _paymentMethods,
                      onRemove: _payments.length > 1
                          ? () {
                              entry.amountCtrl.dispose();
                              setState(() => _payments.removeAt(i));
                            }
                          : null,
                      onChanged: () => setState(() {}),
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Split Payment'),
                    onPressed: () =>
                        setState(() => _payments.add(_PaymentEntry())),
                  ),
                  const SizedBox(height: QDSpace.sectionGap),

                  QDButton(
                    label: 'Create Bill',
                    isLoading: _submitting,
                    icon: Icons.receipt_long_rounded,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: QDSpace.x4),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: QDSpace.x2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: QDPalette.neutral500,
                letterSpacing: .5)),
      );
}

// ── Customer Section ───────────────────────────────────────────────────────────

class _CustomerSection extends StatefulWidget {
  final int tenantId;
  final BusinessRepository repo;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final void Function(int?) onCustomerSelected;

  const _CustomerSection({
    required this.tenantId,
    required this.repo,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.onCustomerSelected,
  });

  @override
  State<_CustomerSection> createState() => _CustomerSectionState();
}

class _CustomerSectionState extends State<_CustomerSection> {
  bool _search = false;
  List<dynamic> _results = [];
  bool _searching = false;

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await widget.repo.getCustomers(widget.tenantId, search: query.trim());
      if (mounted) setState(() { _results = list; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_search) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name (optional)',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Search'),
                onPressed: () => setState(() => _search = true),
              ),
            ],
          ),
          const SizedBox(height: QDSpace.x3),
          TextFormField(
            controller: widget.phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ] else ...[
          TextFormField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Search existing customers',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() { _search = false; _results = []; }),
              ),
            ),
            onChanged: _doSearch,
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator(color: QDPalette.primary500, strokeWidth: 2)),
            ),
          ..._results.take(5).map((c) {
            final name = c.fullName as String? ?? '';
            final mobile = c.mobileNumber as String? ?? '';
            return ListTile(
              leading: const Icon(Icons.person_rounded, color: QDPalette.primary500),
              title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: mobile.isNotEmpty ? Text(mobile, style: const TextStyle(fontSize: 12)) : null,
              onTap: () {
                widget.nameCtrl.text = name;
                widget.phoneCtrl.text = mobile;
                widget.onCustomerSelected(c.personId as int?);
                setState(() { _search = false; _results = []; });
              },
            );
          }),
        ],
      ],
    );
  }
}

// ── Service Line ──────────────────────────────────────────────────────────────

class _ServiceLine {
  ServiceModel? service;
  int quantity = 1;
}

class _ServiceLineRow extends StatelessWidget {
  final _ServiceLine line;
  final List<ServiceModel> services;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _ServiceLineRow({
    super.key,
    required this.line,
    required this.services,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: QDSpace.x2),
      padding: const EdgeInsets.all(QDSpace.x3),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceModel>(
                value: line.service,
                hint: const Text('Select service',
                    style: TextStyle(color: QDPalette.neutral400, fontSize: 13)),
                isExpanded: true,
                items: services.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    '${s.serviceName} – ${QDCurrency.format(s.price)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                )).toList(),
                onChanged: (v) {
                  line.service = v;
                  onChanged();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: TextFormField(
              initialValue: '${line.quantity}',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) {
                line.quantity = int.tryParse(v) ?? 1;
                onChanged();
              },
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: QDPalette.error500, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Custom Item ───────────────────────────────────────────────────────────────

class _CustomItem {
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
}

class _CustomItemRow extends StatelessWidget {
  final _CustomItem item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _CustomItemRow({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: QDSpace.x2),
      padding: const EdgeInsets.all(QDSpace.x3),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: item.descCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Description',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              controller: item.priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: '₹',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: TextFormField(
              controller: item.qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Qty',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded,
                color: QDPalette.error500, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

// ── Totals Section ─────────────────────────────────────────────────────────────

class _TotalsSection extends StatelessWidget {
  final TextEditingController discountAmtCtrl;
  final TextEditingController discountPctCtrl;
  final String gstType;
  final double taxPct;
  final List<String> gstOptions;
  final List<double> taxPresets;
  final void Function(String) onGstChanged;
  final void Function(double) onTaxChanged;
  final VoidCallback onChanged;

  const _TotalsSection({
    required this.discountAmtCtrl,
    required this.discountPctCtrl,
    required this.gstType,
    required this.taxPct,
    required this.gstOptions,
    required this.taxPresets,
    required this.onGstChanged,
    required this.onTaxChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: discountAmtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Discount ₹',
                    isDense: true,
                    prefixText: '₹ ',
                  ),
                  onChanged: (_) {
                    discountPctCtrl.text = '0';
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: discountPctCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Discount %',
                    isDense: true,
                    suffixText: '%',
                  ),
                  onChanged: (_) {
                    discountAmtCtrl.text = '0';
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: QDSpace.x3),
          const Text('Tax',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: QDPalette.neutral500)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: taxPresets.map((t) {
              final selected = t == taxPct;
              return ChoiceChip(
                label: Text('${t.toStringAsFixed(0)}%'),
                selected: selected,
                onSelected: (_) => onTaxChanged(t),
                selectedColor: QDPalette.primary100,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? QDPalette.primary700 : QDPalette.neutral600,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          if (taxPct > 0) ...[
            const SizedBox(height: QDSpace.x2),
            DropdownButtonFormField<String>(
              value: gstType,
              decoration: const InputDecoration(
                labelText: 'GST Type',
                isDense: true,
              ),
              items: gstOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => onGstChanged(v ?? gstType),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Total Banner ──────────────────────────────────────────────────────────────

class _TotalBanner extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;

  const _TotalBanner({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: QDSpace.cardGap),
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.primary50,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.primary100),
      ),
      child: Column(
        children: [
          _row('Subtotal', subtotal, QDPalette.neutral700),
          if (discount > 0)
            _row('Discount', -discount, QDPalette.success500),
          if (tax > 0) _row('Tax', tax, QDPalette.neutral700),
          const Divider(color: QDPalette.primary200, thickness: 1),
          _row('Total', total, QDPalette.primary700, bold: true, large: true),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, Color color,
      {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: large ? 15 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: large ? QDPalette.primary700 : QDPalette.neutral600)),
          Text(
            amount < 0
                ? '- ${QDCurrency.format(-amount)}'
                : QDCurrency.format(amount),
            style: TextStyle(
                fontSize: large ? 18 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color,
                letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }
}

// ── Payment Row ───────────────────────────────────────────────────────────────

class _PaymentEntry {
  final amountCtrl = TextEditingController();
  String method = 'CASH';
}

class _PaymentRow extends StatelessWidget {
  final _PaymentEntry entry;
  final List<String> methods;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _PaymentRow({
    super.key,
    required this.entry,
    required this.methods,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: QDSpace.x2),
      padding: const EdgeInsets.symmetric(
          horizontal: QDSpace.x3, vertical: QDSpace.x2),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Amount',
                isDense: true,
                prefixText: '₹ ',
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: entry.method,
                isExpanded: true,
                style: const TextStyle(
                    fontSize: 13, color: QDPalette.neutral700),
                items: methods
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) entry.method = v;
                  onChanged();
                },
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded,
                  color: QDPalette.error500, size: 18),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

// ── Receipt Row ───────────────────────────────────────────────────────────────

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? value;
  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: QDPalette.neutral500)),
          Text(value!,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: QDPalette.neutral800)),
        ],
      ),
    );
  }
}
