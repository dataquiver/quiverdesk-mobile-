class StaffMemberModel {
  final int personId;
  final int personTenantRoleId;
  final String fullName;
  final String roleCode;
  final String roleName;
  final String? mobileNumber;
  final String? email;
  final bool isActive;

  const StaffMemberModel({
    required this.personId,
    required this.personTenantRoleId,
    required this.fullName,
    required this.roleCode,
    required this.roleName,
    this.mobileNumber,
    this.email,
    this.isActive = true,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    return StaffMemberModel(
      personId: json['personId'] as int,
      personTenantRoleId: json['personTenantRoleId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      roleCode: json['roleCode'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String?,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
