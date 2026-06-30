class ServiceModel {
  final int serviceId;
  final String serviceName;
  final double price;
  final int durationMinutes;
  final String? category;
  final bool isActive;
  final String? description;

  const ServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.durationMinutes,
    this.category,
    this.isActive = true,
    this.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'] as int,
      serviceName: json['serviceName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      category: json['category'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }
}
