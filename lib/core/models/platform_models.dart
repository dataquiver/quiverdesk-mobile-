// ── Subscription Plans ─────────────────────────────────────────────────────
class PlatformPlanModel {
  final int subscriptionPlanId;
  final String planCode;
  final String planName;
  final String? description;
  final double monthlyPrice;
  final double annualPrice;
  final int trialDays;
  final int maxUsers;
  final int maxBranches;
  final int maxCustomers;
  final int maxStaff;
  final int maxAppointmentsPerMonth;
  final int maxStorageMb;
  final bool isActive;
  final int activeSubscriberCount;

  const PlatformPlanModel({
    required this.subscriptionPlanId,
    required this.planCode,
    required this.planName,
    this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.trialDays,
    required this.maxUsers,
    required this.maxBranches,
    required this.maxCustomers,
    required this.maxStaff,
    required this.maxAppointmentsPerMonth,
    required this.maxStorageMb,
    required this.isActive,
    required this.activeSubscriberCount,
  });

  factory PlatformPlanModel.fromJson(Map<String, dynamic> j) => PlatformPlanModel(
        subscriptionPlanId: j['subscriptionPlanId'] as int? ?? 0,
        planCode: j['planCode'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        description: j['description'] as String?,
        monthlyPrice: (j['monthlyPrice'] as num?)?.toDouble() ?? 0,
        annualPrice: (j['annualPrice'] as num?)?.toDouble() ?? 0,
        trialDays: j['trialDays'] as int? ?? 0,
        maxUsers: j['maxUsers'] as int? ?? 0,
        maxBranches: j['maxBranches'] as int? ?? 0,
        maxCustomers: j['maxCustomers'] as int? ?? 0,
        maxStaff: j['maxStaff'] as int? ?? 0,
        maxAppointmentsPerMonth: j['maxAppointmentsPerMonth'] as int? ?? 0,
        maxStorageMb: j['maxStorageMb'] as int? ?? 0,
        isActive: j['isActive'] as bool? ?? false,
        activeSubscriberCount: j['activeSubscriberCount'] as int? ?? 0,
      );
}

// ── Features ───────────────────────────────────────────────────────────────
class PlatformFeatureModel {
  final int featureId;
  final String featureCode;
  final String featureName;
  final String? description;
  final String category;
  final bool isActive;
  final int planCount;

  const PlatformFeatureModel({
    required this.featureId,
    required this.featureCode,
    required this.featureName,
    this.description,
    required this.category,
    required this.isActive,
    required this.planCount,
  });

  factory PlatformFeatureModel.fromJson(Map<String, dynamic> j) => PlatformFeatureModel(
        featureId: j['featureId'] as int? ?? 0,
        featureCode: j['featureCode'] as String? ?? '',
        featureName: j['featureName'] as String? ?? '',
        description: j['description'] as String?,
        category: j['category'] as String? ?? '',
        isActive: j['isActive'] as bool? ?? false,
        planCount: j['planCount'] as int? ?? 0,
      );
}

// ── Payments ───────────────────────────────────────────────────────────────
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

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';

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
        status: j['status'] as String? ?? '',
        paymentMode: j['paymentMode'] as String?,
        dueDate: DateTime.tryParse(j['dueDate'] as String? ?? ''),
        paidOn: DateTime.tryParse(j['paidOn'] as String? ?? ''),
        createdOn: DateTime.tryParse(j['createdOn'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Vouchers ───────────────────────────────────────────────────────────────
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
        voucherType: j['voucherType'] as String? ?? '',
        discountValue: (j['discountValue'] as num?)?.toDouble() ?? 0,
        usageLimit: j['usageLimit'] as int?,
        usageCount: j['usageCount'] as int? ?? 0,
        validFrom: DateTime.tryParse(j['validFrom'] as String? ?? ''),
        validTo: DateTime.tryParse(j['validTo'] as String? ?? ''),
        isActive: j['isActive'] as bool? ?? false,
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

// ── Reports ────────────────────────────────────────────────────────────────
class BusinessGrowthItem {
  final String month;
  final int newBusinesses;
  final int totalBusinesses;
  final int churnedBusinesses;

  const BusinessGrowthItem({
    required this.month,
    required this.newBusinesses,
    required this.totalBusinesses,
    required this.churnedBusinesses,
  });

  factory BusinessGrowthItem.fromJson(Map<String, dynamic> j) => BusinessGrowthItem(
        month: j['month'] as String? ?? '',
        newBusinesses: j['newBusinesses'] as int? ?? 0,
        totalBusinesses: j['totalBusinesses'] as int? ?? 0,
        churnedBusinesses: j['churnedBusinesses'] as int? ?? 0,
      );
}

class RevenueReportItem {
  final String month;
  final double revenue;
  final double newRevenue;
  final double renewalRevenue;

  const RevenueReportItem({
    required this.month,
    required this.revenue,
    required this.newRevenue,
    required this.renewalRevenue,
  });

  factory RevenueReportItem.fromJson(Map<String, dynamic> j) => RevenueReportItem(
        month: j['month'] as String? ?? '',
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0,
        newRevenue: (j['newRevenue'] as num?)?.toDouble() ?? 0,
        renewalRevenue: (j['renewalRevenue'] as num?)?.toDouble() ?? 0,
      );
}

class PlanWiseRevenueItem {
  final String planCode;
  final String planName;
  final int subscriberCount;
  final double monthlyRevenue;
  final double annualRevenue;

  const PlanWiseRevenueItem({
    required this.planCode,
    required this.planName,
    required this.subscriberCount,
    required this.monthlyRevenue,
    required this.annualRevenue,
  });

  factory PlanWiseRevenueItem.fromJson(Map<String, dynamic> j) => PlanWiseRevenueItem(
        planCode: j['planCode'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        subscriberCount: j['subscriberCount'] as int? ?? 0,
        monthlyRevenue: (j['monthlyRevenue'] as num?)?.toDouble() ?? 0,
        annualRevenue: (j['annualRevenue'] as num?)?.toDouble() ?? 0,
      );
}

class ExpiringTrialItem {
  final int tenantId;
  final String businessName;
  final String ownerName;
  final DateTime trialExpiryDate;
  final int daysLeft;

  const ExpiringTrialItem({
    required this.tenantId,
    required this.businessName,
    required this.ownerName,
    required this.trialExpiryDate,
    required this.daysLeft,
  });

  factory ExpiringTrialItem.fromJson(Map<String, dynamic> j) => ExpiringTrialItem(
        tenantId: j['tenantId'] as int? ?? 0,
        businessName: j['businessName'] as String? ?? '',
        ownerName: j['ownerName'] as String? ?? '',
        trialExpiryDate: DateTime.tryParse(j['trialExpiryDate'] as String? ?? '') ?? DateTime.now(),
        daysLeft: j['daysLeft'] as int? ?? 0,
      );
}

class UpcomingRenewalItem {
  final int tenantId;
  final String businessName;
  final String planName;
  final DateTime renewalDate;
  final double amount;
  final int daysUntilRenewal;

  const UpcomingRenewalItem({
    required this.tenantId,
    required this.businessName,
    required this.planName,
    required this.renewalDate,
    required this.amount,
    required this.daysUntilRenewal,
  });

  factory UpcomingRenewalItem.fromJson(Map<String, dynamic> j) => UpcomingRenewalItem(
        tenantId: j['tenantId'] as int? ?? 0,
        businessName: j['businessName'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        renewalDate: DateTime.tryParse(j['renewalDate'] as String? ?? '') ?? DateTime.now(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        daysUntilRenewal: j['daysUntilRenewal'] as int? ?? 0,
      );
}

// ── Notifications ──────────────────────────────────────────────────────────
class PlatformNotificationModel {
  final int platformNotificationId;
  final int? tenantId;
  final String? businessName;
  final String notificationType;
  final String title;
  final String message;
  final String severity;
  final bool isRead;
  final bool isResolved;
  final DateTime createdOn;

  const PlatformNotificationModel({
    required this.platformNotificationId,
    this.tenantId,
    this.businessName,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.severity,
    required this.isRead,
    required this.isResolved,
    required this.createdOn,
  });

  factory PlatformNotificationModel.fromJson(Map<String, dynamic> j) => PlatformNotificationModel(
        platformNotificationId: j['platformNotificationId'] as int? ?? 0,
        tenantId: j['tenantId'] as int?,
        businessName: j['businessName'] as String?,
        notificationType: j['notificationType'] as String? ?? '',
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        severity: j['severity'] as String? ?? 'INFO',
        isRead: j['isRead'] as bool? ?? false,
        isResolved: j['isResolved'] as bool? ?? false,
        createdOn: DateTime.tryParse(j['createdOn'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotificationSummaryModel {
  final int totalUnread;
  final int critical;
  final int warnings;
  final int info;

  const NotificationSummaryModel({
    required this.totalUnread,
    required this.critical,
    required this.warnings,
    required this.info,
  });

  factory NotificationSummaryModel.fromJson(Map<String, dynamic> j) => NotificationSummaryModel(
        totalUnread: j['totalUnread'] as int? ?? 0,
        critical: j['critical'] as int? ?? 0,
        warnings: j['warnings'] as int? ?? 0,
        info: j['info'] as int? ?? 0,
      );
}
