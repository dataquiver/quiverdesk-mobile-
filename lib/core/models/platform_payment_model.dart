class PlatformPaymentModel {
  final int platformPaymentId;
  final int tenantId;
  final String businessName;
  final String invoiceNumber;
  final String planName;
  final double amount;
  final double taxAmount;
  final double totalAmount;
  final String paymentType;
  final String status;
  final String? paymentMode;
  final DateTime? dueDate;
  final DateTime? paidOn;
  final DateTime createdOn;

  const PlatformPaymentModel({
    required this.platformPaymentId,
    required this.tenantId,
    required this.businessName,
    required this.invoiceNumber,
    required this.planName,
    required this.amount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentType,
    required this.status,
    this.paymentMode,
    this.dueDate,
    this.paidOn,
    required this.createdOn,
  });

  factory PlatformPaymentModel.fromJson(Map<String, dynamic> j) => PlatformPaymentModel(
        platformPaymentId: j['platformPaymentId'] as int? ?? 0,
        tenantId: j['tenantId'] as int? ?? 0,
        businessName: j['businessName'] as String? ?? '',
        invoiceNumber: j['invoiceNumber'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        taxAmount: (j['taxAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        paymentType: j['paymentType'] as String? ?? '',
        status: j['status'] as String? ?? 'PENDING',
        paymentMode: j['paymentMode'] as String?,
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'] as String) : null,
        paidOn: j['paidOn'] != null ? DateTime.tryParse(j['paidOn'] as String) : null,
        createdOn: DateTime.tryParse(j['createdOn'] as String? ?? '') ?? DateTime.now(),
      );
}
