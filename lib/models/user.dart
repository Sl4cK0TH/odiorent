// lib/models/user.dart

// ENUM for user role to match the database ENUM.
enum UserRole {
  renter,
  landlord,
  admin,
}

// Helper function to convert a string to a UserRole enum value.
UserRole roleFromString(String? role) {
  switch (role) {
    case 'landlord':
      return UserRole.landlord;
    case 'admin':
      return UserRole.admin;
    case 'renter':
    default:
      return UserRole.renter;
  }
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String userName;
  final String phoneNumber;
  final String? profilePictureUrl;
  final DateTime? lastSeen; // For online presence

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.lastName,
    required this.firstName,
    this.middleName,
    required this.userName,
    required this.phoneNumber,
    this.profilePictureUrl,
    this.lastSeen, // Add to constructor
  });

  // Factory constructor to create an AppUser from a JSON map
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      role: roleFromString(json['role'] as String?),
      lastName: json['last_name'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      userName: json['user_name'],
      phoneNumber: json['phone_number'],
      profilePictureUrl: json['profile_picture_url'],
      // Parse the last_seen timestamp
      lastSeen: json['last_seen'] == null
          ? null
          : DateTime.parse(json['last_seen'] as String),
    );
  }
}