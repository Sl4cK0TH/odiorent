import 'package:cloud_firestore/cloud_firestore.dart';

class VideoLike {
  final String? id;
  final String propertyId;
  final String videoUrl;
  final String userId;
  final DateTime createdAt;

  VideoLike({
    this.id,
    required this.propertyId,
    required this.videoUrl,
    required this.userId,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'videoUrl': videoUrl,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory VideoLike.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoLike(
      id: doc.id,
      propertyId: data['propertyId'] as String,
      videoUrl: data['videoUrl'] as String,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Create from Map
  factory VideoLike.fromMap(Map<String, dynamic> data, String id) {
    return VideoLike(
      id: id,
      propertyId: data['propertyId'] as String,
      videoUrl: data['videoUrl'] as String,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
