// lib/models/user.dart

class AppUser {
  final String id;
  final String email;
  final String role;
  final String lastName;
  final String firstName;
  final String? middleName; // Nullable
  final String userName;
  final String phoneNumber;
  final String? profilePictureUrl; // New: Nullable field for profile picture URL

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.lastName,
    required this.firstName,
    this.middleName,
    required this.userName,
    required this.phoneNumber,
    this.profilePictureUrl, // New: Add to constructor
  });

  // Factory constructor to create an AppUser from a JSON map (e.g., from Supabase)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      lastName: json['last_name'],
      firstName: json['first_name'],
      middleName: json['middle_name'], // Supabase returns null if not present
      userName: json['user_name'],
      phoneNumber: json['phone_number'],
      profilePictureUrl: json['profile_picture_url'], // New: Parse profile picture URL
    );
  }
}
