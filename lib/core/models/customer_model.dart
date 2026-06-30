import 'package:equatable/equatable.dart';

class CustomerModel extends Equatable {
  final int personId;
  final String fullName;
  final String? email;
  final String? mobileNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final int? totalVisits;
  final double? totalSpent;
  final DateTime? lastVisitDate;
  final String? notes;

  const CustomerModel({
    required this.personId,
    required this.fullName,
    this.email,
    this.mobileNumber,
    this.gender,
    this.dateOfBirth,
    this.totalVisits,
    this.totalSpent,
    this.lastVisitDate,
    this.notes,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      personId: json['personId'] as int,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      totalVisits: json['totalVisits'] as int?,
      totalSpent: (json['totalSpent'] as num?)?.toDouble()
          ?? (json['lifetimeRevenue'] as num?)?.toDouble(),
      lastVisitDate: json['lastVisitDate'] != null
          ? DateTime.tryParse(json['lastVisitDate'])
          : null,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [personId];
}
