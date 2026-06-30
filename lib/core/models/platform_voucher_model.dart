class PlatformVoucherModel {
  final int platformVoucherId;
  final String code;
  final String name;
  final String voucherType;
  final double discountValue;
  final int? usageLimit;
  final int usageCount;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isActive;
  final double revenueImpact;

  const PlatformVoucherModel({
    required this.platformVoucherId,
    required this.code,
    required this.name,
    required this.voucherType,
    required this.discountValue,
    this.usageLimit,
    required this.usageCount,
    this.validFrom,
    this.validTo,
    required this.isActive,
    required this.revenueImpact,
  });

  factory PlatformVoucherModel.fromJson(Map<String, dynamic> j) => PlatformVoucherModel(
        platformVoucherId: j['platformVoucherId'] as int? ?? 0,
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        voucherType: j['voucherType'] as String? ?? 'PERCENT',
        discountValue: (j['discountValue'] as num?)?.toDouble() ?? 0,
        usageLimit: j['usageLimit'] as int?,
        usageCount: j['usageCount'] as int? ?? 0,
        validFrom: j['validFrom'] != null ? DateTime.tryParse(j['validFrom'] as String) : null,
        validTo: j['validTo'] != null ? DateTime.tryParse(j['validTo'] as String) : null,
        isActive: j['isActive'] as bool? ?? true,
        revenueImpact: (j['revenueImpact'] as num?)?.toDouble() ?? 0,
      );
}

class VoucherUsageModel {
  final int platformVoucherUsageId;
  final int tenantId;
  final String businessName;
  final double discountApplied;
  final DateTime usedOn;

  const VoucherUsageModel({
    required this.platformVoucherUsageId,
    required this.tenantId,
    required this.businessName,
    required this.discountApplied,
    required this.usedOn,
  });

  factory VoucherUsageModel.fromJson(Map<String, dynamic> j) => VoucherUsageModel(
        platformVoucherUsageId: j['platformVoucherUsageId'] as int? ?? 0,
        tenantId: j['tenantId'] as int? ?? 0,
        businessName: j['businessName'] as String? ?? '',
        discountApplied: (j['discountApplied'] as num?)?.toDouble() ?? 0,
        usedOn: DateTime.tryParse(j['usedOn'] as String? ?? '') ?? DateTime.now(),
      );
}
