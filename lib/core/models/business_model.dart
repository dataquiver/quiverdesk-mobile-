class BusinessModel {
  final int tenantId;
  final String businessName;
  final String? businessType;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final String? subscriptionPlan;
  final String? subscriptionStatus;
  final DateTime? createdAt;
  final int? staffCount;
  final int? customerCount;
  final String? city;
  final String? state;

  const BusinessModel({
    required this.tenantId,
    required this.businessName,
    this.businessType,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.createdAt,
    this.staffCount,
    this.customerCount,
    this.city,
    this.state,
  });

  bool get isActive => subscriptionStatus == 'ACTIVE' || subscriptionStatus == 'TRIAL';

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      tenantId: json['tenantId'] as int,
      businessName: json['businessName'] ?? json['tenantName'] as String? ?? '',
      businessType: json['businessType'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
      subscriptionPlan: json['subscriptionPlan'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      staffCount: json['staffCount'] as int?,
      customerCount: json['customerCount'] as int?,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }
}
