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
        isActive: j['isActive'] as bool? ?? true,
        activeSubscriberCount: j['activeSubscriberCount'] as int? ?? 0,
      );
}
