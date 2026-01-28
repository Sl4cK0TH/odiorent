import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyRoom {
  final String? id;
  final String propertyId;
  final String title;
  final String description;
  final double price; // Monthly price per bed/person
  final int capacity; // Total beds in this room
  final List<String> imageUrls;
  final DateTime createdAt;

  PropertyRoom({
    this.id,
    required this.propertyId,
    required this.title,
    required this.description,
    required this.price,
    required this.capacity,
    required this.imageUrls,
    required this.createdAt,
  });

  /// --- `toJson` Method (for Firestore) ---
  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'title': title,
      'description': description,
      'price': price,
      'capacity': capacity,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
    };
  }

  /// --- `fromFirestore` Factory ---
  factory PropertyRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyRoom(
      id: doc.id,
      propertyId: data['propertyId'] as String,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      price: (data['price'] as num).toDouble(),
      capacity: (data['capacity'] as int),
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// --- `copyWith` Method ---
  PropertyRoom copyWith({
    String? id,
    String? propertyId,
    String? title,
    String? description,
    double? price,
    int? capacity,
    List<String>? imageUrls,
    DateTime? createdAt,
  }) {
    return PropertyRoom(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
