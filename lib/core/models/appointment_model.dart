import 'package:equatable/equatable.dart';

class AppointmentModel extends Equatable {
  final int appointmentId;
  final String customerName;
  final String? customerPhone;
  final String serviceName;
  final String staffName;
  final DateTime appointmentDate;
  final String startTime;
  final String? endTime;
  final String status;
  final double? servicePrice;
  final int? durationMinutes;
  final String? notes;
  final double? rating;

  const AppointmentModel({
    required this.appointmentId,
    required this.customerName,
    this.customerPhone,
    required this.serviceName,
    required this.staffName,
    required this.appointmentDate,
    required this.startTime,
    this.endTime,
    required this.status,
    this.servicePrice,
    this.durationMinutes,
    this.notes,
    this.rating,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Extract first service name from services array (API field) or fall back to serviceName
    final services = json['services'] as List<dynamic>?;
    final firstService = services?.isNotEmpty == true ? services!.first as Map<String, dynamic>? : null;
    final svcName = json['serviceName'] as String?
        ?? firstService?['serviceName'] as String?
        ?? '';
    return AppointmentModel(
      appointmentId: json['appointmentId'] as int,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? json['customerMobile'] as String?,
      serviceName: svcName,
      staffName: json['staffName'] as String? ?? json['assignedToName'] as String? ?? '',
      appointmentDate: DateTime.tryParse(json['appointmentDate'] ?? '') ?? DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String?,
      status: json['status'] as String? ?? 'SCHEDULED',
      servicePrice: (json['servicePrice'] as num?)?.toDouble()
          ?? (json['totalAmount'] as num?)?.toDouble(),
      durationMinutes: json['durationMinutes'] as int?,
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  AppointmentModel copyWith({String? status}) {
    return AppointmentModel(
      appointmentId: appointmentId,
      customerName: customerName,
      customerPhone: customerPhone,
      serviceName: serviceName,
      staffName: staffName,
      appointmentDate: appointmentDate,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      servicePrice: servicePrice,
      durationMinutes: durationMinutes,
      notes: notes,
      rating: rating,
    );
  }

  @override
  List<Object?> get props => [appointmentId, status];
}
