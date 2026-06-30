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
  final bool? isActiveDirect;

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
    this.isActiveDirect,
  });

  bool get isActive =>
      isActiveDirect ?? (subscriptionStatus == 'ACTIVE' || subscriptionStatus == 'TRIAL');

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      tenantId: json['tenantId'] as int,
      businessName: json['name'] as String? ??
          json['businessName'] as String? ??
          json['tenantName'] as String? ??
          '',
      businessType:
          json['businessCategory'] as String? ?? json['businessType'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerEmail: json['email'] as String? ?? json['ownerEmail'] as String?,
      ownerPhone: json['phoneNumber'] as String? ?? json['ownerPhone'] as String?,
      subscriptionPlan: json['subscriptionPlan'] as String? ?? json['planCode'] as String?,
      subscriptionStatus:
          json['subscriptionStatus'] as String? ?? json['status'] as String?,
      createdAt: _parseDate(json['createdOn'] ?? json['createdAt']),
      staffCount: json['staffCount'] as int?,
      customerCount: json['customerCount'] as int?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      isActiveDirect: json['isActive'] as bool?,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
