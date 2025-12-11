// lib/models/admin_user.dart

import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// --- `toFirestore` Method ---
  /// Converts an AdminUser object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'lastName': lastName,
      'firstName': firstName,
      'middleName': middleName,
      'userName': userName,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  /// --- `fromFirestore` Factory ---
  /// Creates an AdminUser object from a Firestore DocumentSnapshot
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      email: data['email'] as String,
      role: data['role'] as String,
      lastName: data['lastName'] as String?,
      firstName: data['firstName'] as String?,
      middleName: data['middleName'] as String?,
      userName: data['userName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
    );
  }
}
