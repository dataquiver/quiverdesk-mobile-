import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String role;
  final int? businessId;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.businessId,
  });

  bool get isPlatformAdmin => role == 'PLATFORM_ADMIN';
  bool get isBusinessOwner => role == 'BUSINESS_OWNER' || role == 'BRANCH_MANAGER';
  bool get isStaff => !isPlatformAdmin && !isBusinessOwner;

  factory UserModel.fromJwt(Map<String, dynamic> claims, {int? businessId}) {
    return UserModel(
      userId: (claims['personId'] ?? claims['sub'] ?? '').toString(),
      name: claims['Name'] ?? claims['name'] ?? '',
      email: claims['Email'] ?? claims['email'] ?? '',
      role: claims['role'] ?? claims['RoleCode'] ?? '',
      businessId: businessId,
    );
  }

  @override
  List<Object?> get props => [userId, name, email, role, businessId];
}

// Login response context (tenant-role pair)
class AuthContext {
  final int tenantId;
  final String tenantName;
  final String roleCode;
  final String roleName;

  const AuthContext({
    required this.tenantId,
    required this.tenantName,
    required this.roleCode,
    required this.roleName,
  });

  factory AuthContext.fromJson(Map<String, dynamic> json) {
    return AuthContext(
      tenantId: json['tenantId'] as int,
      tenantName: json['tenantName'] as String? ?? '',
      roleCode: json['roleCode'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
    );
  }
}
