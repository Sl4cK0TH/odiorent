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
  final String? profilePictureUrl; // New: Nullable field for profile picture URL

  AdminUser({
    required this.id,
    required this.email,
    required this.role,
    this.lastName,
    this.firstName,
    this.middleName,
    this.userName,
    this.phoneNumber,
    this.profilePictureUrl, // New: Add to constructor
  });

  factory AdminUser.fromMap(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      lastName: json['last_name'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      userName: json['user_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?, // New: Parse profile picture URL
    );
  }
}
