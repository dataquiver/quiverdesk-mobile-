class InvoiceModel {
  final int invoiceId;
  final String customerName;
  final String? customerPhone;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String? paymentMode;
  final DateTime invoiceDate;
  final List<InvoiceItem> items;

  const InvoiceModel({
    required this.invoiceId,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    this.paymentMode,
    required this.invoiceDate,
    required this.items,
  });

  double get balance => totalAmount - paidAmount;
  bool get isPaid => status == 'PAID';
  bool get isUnpaid => status == 'UNPAID' || status == 'ISSUED';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final itemList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return InvoiceModel(
      invoiceId: json['invoiceId'] as int,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'UNPAID',
      paymentMode: json['paymentMode'] as String?,
      invoiceDate: DateTime.tryParse(json['invoiceDate'] ?? '') ?? DateTime.now(),
      items: itemList,
    );
  }
}

class InvoiceItem {
  final String serviceName;
  final double price;
  final int quantity;

  const InvoiceItem({
    required this.serviceName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      serviceName: json['serviceName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
