class BusinessGrowthModel {
  final String month;
  final int newBusinesses;
  final int totalBusinesses;
  final int churnedBusinesses;

  const BusinessGrowthModel({
    required this.month,
    required this.newBusinesses,
    required this.totalBusinesses,
    required this.churnedBusinesses,
  });

  factory BusinessGrowthModel.fromJson(Map<String, dynamic> j) => BusinessGrowthModel(
        month: j['month'] as String? ?? '',
        newBusinesses: j['newBusinesses'] as int? ?? 0,
        totalBusinesses: j['totalBusinesses'] as int? ?? 0,
        churnedBusinesses: j['churnedBusinesses'] as int? ?? 0,
      );
}

class RevenueReportModel {
  final String month;
  final double revenue;
  final double newRevenue;
  final double renewalRevenue;

  const RevenueReportModel({
    required this.month,
    required this.revenue,
    required this.newRevenue,
    required this.renewalRevenue,
  });

  factory RevenueReportModel.fromJson(Map<String, dynamic> j) => RevenueReportModel(
        month: j['month'] as String? ?? '',
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0,
        newRevenue: (j['newRevenue'] as num?)?.toDouble() ?? 0,
        renewalRevenue: (j['renewalRevenue'] as num?)?.toDouble() ?? 0,
      );
}

class PlanWiseRevenueModel {
  final String planCode;
  final String planName;
  final int subscriberCount;
  final double monthlyRevenue;
  final double annualRevenue;

  const PlanWiseRevenueModel({
    required this.planCode,
    required this.planName,
    required this.subscriberCount,
    required this.monthlyRevenue,
    required this.annualRevenue,
  });

  factory PlanWiseRevenueModel.fromJson(Map<String, dynamic> j) => PlanWiseRevenueModel(
        planCode: j['planCode'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        subscriberCount: j['subscriberCount'] as int? ?? 0,
        monthlyRevenue: (j['monthlyRevenue'] as num?)?.toDouble() ?? 0,
        annualRevenue: (j['annualRevenue'] as num?)?.toDouble() ?? 0,
      );
}

class ExpiringTrialModel {
  final int tenantId;
  final String businessName;
  final String ownerName;
  final DateTime trialExpiryDate;
  final int daysLeft;

  const ExpiringTrialModel({
    required this.tenantId,
    required this.businessName,
    required this.ownerName,
    required this.trialExpiryDate,
    required this.daysLeft,
  });

  factory ExpiringTrialModel.fromJson(Map<String, dynamic> j) => ExpiringTrialModel(
        tenantId: j['tenantId'] as int? ?? 0,
        businessName: j['businessName'] as String? ?? '',
        ownerName: j['ownerName'] as String? ?? '',
        trialExpiryDate: DateTime.tryParse(j['trialExpiryDate'] as String? ?? '') ?? DateTime.now(),
        daysLeft: j['daysLeft'] as int? ?? 0,
      );
}

class UpcomingRenewalModel {
  final int tenantId;
  final String businessName;
  final String planName;
  final DateTime renewalDate;
  final double amount;
  final int daysUntilRenewal;

  const UpcomingRenewalModel({
    required this.tenantId,
    required this.businessName,
    required this.planName,
    required this.renewalDate,
    required this.amount,
    required this.daysUntilRenewal,
  });

  factory UpcomingRenewalModel.fromJson(Map<String, dynamic> j) => UpcomingRenewalModel(
        tenantId: j['tenantId'] as int? ?? 0,
        businessName: j['businessName'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        renewalDate: DateTime.tryParse(j['renewalDate'] as String? ?? '') ?? DateTime.now(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        daysUntilRenewal: j['daysUntilRenewal'] as int? ?? 0,
      );
}
