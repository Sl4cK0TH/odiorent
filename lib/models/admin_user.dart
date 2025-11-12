// lib/models/admin_user.dart

class AdminUser {
  final String id;
  final String email;
  final String role;
  final String? lastName;
  final String? firstName;
  final String? middleName;
  final String? userName;
  final String? phoneNumber;

  AdminUser({
    required this.id,
    required this.email,
    required this.role,
    this.lastName,
    this.firstName,
    this.middleName,
    this.userName,
    this.phoneNumber,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      lastName: json['last_name'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      userName: json['user_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }
}
