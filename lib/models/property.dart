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

  // 'image_urls' is a text array in Supabase, which maps to List<String>
  final List<String> imageUrls;

  final String status; // 'pending', 'approved', or 'rejected'
  final DateTime createdAt; // New: Date when the property was created
  final DateTime? approvedAt; // New: Date when the property was approved (nullable)

  // New: Landlord details (will be populated via joins in queries)
  final String? landlordName;
  final String? landlordEmail;
  final String? landlordFirstName;
  final String? landlordLastName;
  final String? landlordUsername;
  final String? landlordPhoneNumber;

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
    required this.imageUrls,
    required this.status,
    required this.createdAt, // New
    this.approvedAt, // New (nullable)
    this.landlordName, // New (nullable)
    this.landlordEmail, // New (nullable)
    this.landlordFirstName,
    this.landlordLastName,
    this.landlordUsername,
    this.landlordPhoneNumber,
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
      'image_urls': imageUrls,
      'status': status,
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
      imageUrls: List<String>.from(json['image_urls'] as List<dynamic>),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      landlordName: json['user_name'] as String?,
      landlordEmail: json['email'] as String?,
      landlordFirstName: json['first_name'] as String?,
      landlordLastName: json['last_name'] as String?,
      landlordUsername: json['user_name'] as String?,
      landlordPhoneNumber: json['phone_number'] as String?,
      averageRating: (json['average_rating'] as num? ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
    );
  }
}
