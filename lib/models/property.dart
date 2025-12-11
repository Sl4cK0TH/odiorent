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

  final PropertyStatus status; // Use the enum instead of String
  final DateTime createdAt; // New: Date when the property was created
  final DateTime? approvedAt; // New: Date when the property was approved (nullable)

  // New: Landlord details (will be populated via joins in queries)
  final String? landlordName;
  final String? landlordEmail;
  final String? landlordFirstName;
  final String? landlordLastName;
  final String? landlordUserName;  // Changed from landlordUsername for consistency
  final String? landlordPhoneNumber;
  final String? landlordProfilePictureUrl;  // Changed from landlordProfilePicture

  // New: Rating details (populated from the 'properties_with_avg_rating' view)
  final double averageRating;
  final int ratingCount;

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
    required this.status,
    required this.createdAt, // New
    this.approvedAt, // New (nullable)
    this.landlordName, // New (nullable)
    this.landlordEmail, // New (nullable)
    this.landlordFirstName,
    this.landlordLastName,
    this.landlordUserName,  // Changed
    this.landlordPhoneNumber,
    this.landlordProfilePictureUrl,  // Changed
    this.averageRating = 0.0, // New
    this.ratingCount = 0, // New
  });

  /// --- `toJson` Method ---
  /// Converts a Property object into a Map (JSON) to be sent *to* Supabase.
  /// This is used for creating or updating properties.
  Map<String, dynamic> toJson() {
    return {
      // We don't send the 'id' when creating a new property,
      // as Supabase generates it automatically.
      'landlord_id': landlordId,
      'name': name,
      'address': address,
      'description': description,
      'price': price,
      'rooms': rooms,
      'beds': beds,
      'showers': showers,
      'image_urls': imageUrls,
      'status': statusToString(status), // Convert enum to string
      'created_at': createdAt.toIso8601String(), // Include created_at
      'approved_at': approvedAt?.toIso8601String(), // Include approved_at if not null
    };
  }

  /// --- `fromJson` Factory ---
  /// Creates a Property object *from* a Map (JSON) received from Supabase.
  /// This is used for reading properties from the database.
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
      status: statusFromString(json['status'] as String), // Convert string to enum
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      landlordName: json['user_name'] as String?,
      landlordEmail: json['email'] as String?,
      landlordFirstName: json['first_name'] as String?,
      landlordLastName: json['last_name'] as String?,
      landlordUserName: json['user_name'] as String?,  // Changed
      landlordPhoneNumber: json['phone_number'] as String?,
      landlordProfilePictureUrl: json['profile_picture_url'] as String?,  // Changed
      averageRating: (json['average_rating'] as num? ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
    );
  }

  /// --- `toFirestore` Method ---
  /// Converts a Property object into a Map for Firestore
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
      'status': statusToString(status),
      'createdAt': createdAt,
      'approvedAt': approvedAt,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }

  /// --- `fromFirestore` Factory ---
  /// Creates a Property object from a Firestore DocumentSnapshot
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
      status: statusFromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      averageRating: (data['averageRating'] as num? ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] as int? ?? 0,
    );
  }

  /// --- `copyWith` Method ---
  /// Creates a copy of this Property with some fields replaced
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
    );
  }
}
