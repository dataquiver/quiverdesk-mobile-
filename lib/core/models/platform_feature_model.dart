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
        category: j['category'] as String? ?? 'CORE',
        isActive: j['isActive'] as bool? ?? true,
        planCount: j['planCount'] as int? ?? 0,
      );
}
