import 'package:cloud_firestore/cloud_firestore.dart';

// New ENUM for property status to match the database ENUM.
// This improves type safety and prevents invalid status values.
enum PropertyStatus {
  pending,
  approved,
  rejected,
}

// Helper function to convert a string to a PropertyStatus enum value.
PropertyStatus statusFromString(String status) {
  switch (status) {
    case 'approved':
      return PropertyStatus.approved;
    case 'rejected':
      return PropertyStatus.rejected;
    case 'pending':
    default:
      return PropertyStatus.pending;
  }
}

// Helper function to convert a PropertyStatus enum value to a string.
String statusToString(PropertyStatus status) {
  return status.toString().split('.').last;
}

class Property {
  // --- Class Fields ---

  // 'id' is nullable (String?) because when we create a *new* property
  // in the app, it doesn't have an ID until Supabase creates it.
  final String? id;

  final String landlordId;
  final String name;
  final String address;
  final String description;
  final double price; // 'numeric' in Postgres maps to double in Dart
  final int rooms;
  final int beds;
  final int showers; // Number of shower rooms/bathrooms

  // 'image_urls' is a text array in Supabase, which maps to List<String>
  final List<String> imageUrls;
  
  // 'video_urls' for virtual tour videos (up to 2 videos)
  final List<String> videoUrls;

  final PropertyStatus status; // Use the enum instead of String
  final DateTime createdAt; // New: Date when the property was created
  final DateTime? approvedAt; // New: Date when the property was approved (nullable)

  // New: Landlord details (will be populated via joins in queries)
  final String? landlordName;
  final String? landlordEmail;
  final String? landlordFirstName;
  final String? landlordLastName;
  final String? landlordUserName;
  final String? landlordPhoneNumber;
  final String? landlordProfilePictureUrl;

  // New: Rating details
  final double averageRating;
  final int ratingCount;

  // New: Location coordinates (Phase 2)
  final double? latitude;
  final double? longitude;
  
  // New: BIR Permit (from Landlord profile)
  final String? birPermitUrl;

  // --- Constructor ---
  Property({
    this.id, // Nullable
    required this.landlordId,
    required this.name,
    required this.address,
    required this.description,
    required this.price,
    required this.rooms,
    required this.beds,
    required this.showers,
    required this.imageUrls,
    required this.videoUrls,
    required this.status,
    required this.createdAt, // New
    this.approvedAt, // New (nullable)
    this.landlordName, // New (nullable)
    this.landlordEmail, // New (nullable)
    this.landlordFirstName,
    this.landlordLastName,
    this.landlordUserName,
    this.landlordPhoneNumber,
    this.landlordProfilePictureUrl,
    this.averageRating = 0.0, // New
    this.ratingCount = 0, // New
    this.latitude, // New
    this.longitude, // New
    this.birPermitUrl, // New
  });

  /// --- `toJson` Method ---
  Map<String, dynamic> toJson() {
    return {
      'landlord_id': landlordId,
      'name': name,
      'address': address,
      'description': description,
      'price': price,
      'rooms': rooms,
      'beds': beds,
      'showers': showers,
      'image_urls': imageUrls,
      'video_urls': videoUrls,
      'status': statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'latitude': latitude, // New
      'longitude': longitude, // New
      'birPermitUrl': birPermitUrl, // New
    };
  }

  /// --- `fromMap` Factory ---
  factory Property.fromMap(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String?,
      landlordId: json['landlord_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      rooms: json['rooms'] as int,
      beds: json['beds'] as int,
      showers: json['showers'] as int,
      imageUrls: List<String>.from(json['image_urls'] as List<dynamic>),
      videoUrls: List<String>.from(json['video_urls'] as List<dynamic>? ?? []),
      status: statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      landlordName: json['user_name'] as String?,
      landlordEmail: json['email'] as String?,
      landlordFirstName: json['first_name'] as String?,
      landlordLastName: json['last_name'] as String?,
      landlordUserName: json['user_name'] as String?,
      landlordPhoneNumber: json['phone_number'] as String?,
      landlordProfilePictureUrl: json['profile_picture_url'] as String?,
      averageRating: (json['average_rating'] as num? ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(), // New
      longitude: (json['longitude'] as num?)?.toDouble(), // New
      birPermitUrl: json['birPermitUrl'] as String?, // New
    );
  }

  /// --- `toFirestore` Method ---
  Map<String, dynamic> toFirestore() {
    return {
      'landlordId': landlordId,
      'name': name,
      'address': address,
      'description': description,
      'price': price,
      'rooms': rooms,
      'beds': beds,
      'showers': showers,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'status': statusToString(status),
      'createdAt': createdAt,
      'approvedAt': approvedAt,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'latitude': latitude, // New
      'longitude': longitude, // New
      'birPermitUrl': birPermitUrl, // New
    };
  }

  /// --- `fromFirestore` Factory ---
  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Property(
      id: doc.id,
      landlordId: data['landlordId'] as String,
      name: data['name'] as String,
      address: data['address'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      rooms: data['rooms'] as int,
      beds: data['beds'] as int,
      showers: data['showers'] as int? ?? 1,
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      videoUrls: List<String>.from(data['videoUrls'] as List<dynamic>? ?? []),
      status: statusFromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      averageRating: (data['averageRating'] as num? ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] as int? ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(), // New
      longitude: (data['longitude'] as num?)?.toDouble(), // New
      birPermitUrl: data['birPermitUrl'] as String?, // New
    );
  }

  /// --- `copyWith` Method ---
  Property copyWith({
    String? id,
    String? landlordId,
    String? name,
    String? address,
    String? description,
    double? price,
    int? rooms,
    int? beds,
    int? showers,
    List<String>? imageUrls,
    List<String>? videoUrls,
    PropertyStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? landlordName,
    String? landlordEmail,
    String? landlordFirstName,
    String? landlordLastName,
    String? landlordUserName,
    String? landlordPhoneNumber,
    String? landlordProfilePictureUrl,
    double? averageRating,
    int? ratingCount,
    double? latitude, // New
    double? longitude, // New
    String? birPermitUrl, // New
  }) {
    return Property(
      id: id ?? this.id,
      landlordId: landlordId ?? this.landlordId,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      price: price ?? this.price,
      rooms: rooms ?? this.rooms,
      beds: beds ?? this.beds,
      showers: showers ?? this.showers,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      landlordName: landlordName ?? this.landlordName,
      landlordEmail: landlordEmail ?? this.landlordEmail,
      landlordFirstName: landlordFirstName ?? this.landlordFirstName,
      landlordLastName: landlordLastName ?? this.landlordLastName,
      landlordUserName: landlordUserName ?? this.landlordUserName,
      landlordPhoneNumber: landlordPhoneNumber ?? this.landlordPhoneNumber,
      landlordProfilePictureUrl: landlordProfilePictureUrl ?? this.landlordProfilePictureUrl,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      birPermitUrl: birPermitUrl ?? this.birPermitUrl,
    );
  }
}
