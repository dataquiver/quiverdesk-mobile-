class InvoiceModel {
  final int invoiceId;
  final String invoiceNumber;
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
    required this.invoiceNumber,
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
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? json['customerMobile'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ISSUED',
      paymentMode: json['paymentMode'] as String?,
      invoiceDate: DateTime.tryParse(
              json['invoiceDate'] as String? ?? json['createdOn'] as String? ?? '') ??
          DateTime.now(),
      items: itemList,
    );
  }
}

class InvoiceItem {
  final String description;
  final double unitPrice;
  final double quantity;

  const InvoiceItem({
    required this.description,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      // Backend: InvoiceItemDto.Description and UnitPrice
      description: json['description'] as String? ??
          json['serviceName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
