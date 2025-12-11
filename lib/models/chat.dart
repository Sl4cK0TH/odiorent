import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? propertyName;
  final String? propertyAddress;
  final List<String>? propertyImageUrls;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserFirstName;
  final String? otherUserLastName;
  final String? otherUserProfilePicture;

  Chat({
    required this.id,
    this.lastMessage,
    this.lastMessageAt,
    this.propertyName,
    this.propertyAddress,
    this.propertyImageUrls,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserFirstName,
    this.otherUserLastName,
    this.otherUserProfilePicture,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String currentUserId) {
    // Determine which participant is the "other" user
    final participant1 = map['participant_1'] as Map<String, dynamic>?;
    final participant2 = map['participant_2'] as Map<String, dynamic>?;
    
    final isParticipant1Current = participant1?['id'] == currentUserId;
    final otherUser = isParticipant1Current ? participant2 : participant1;

    // Get property info
    final property = map['property'] as Map<String, dynamic>?;
    final imageUrls = property?['image_urls'] as List?;

    return Chat(
      id: map['id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      propertyName: property?['name'] as String?,
      propertyAddress: property?['address'] as String?,
      propertyImageUrls: imageUrls?.map((e) => e.toString()).toList(),
      otherUserId: otherUser?['id'] as String? ?? '',
      otherUserName: otherUser?['user_name'] as String?,
      otherUserFirstName: otherUser?['first_name'] as String?,
      otherUserLastName: otherUser?['last_name'] as String?,
      otherUserProfilePicture: otherUser?['profile_picture_url'] as String?,
    );
  }

  String get otherUserDisplayName {
    if (otherUserName != null && otherUserName!.isNotEmpty) {
      return otherUserName!;
    }
    if (otherUserFirstName != null && otherUserLastName != null) {
      return '$otherUserFirstName $otherUserLastName';
    }
    if (otherUserFirstName != null) {
      return otherUserFirstName!;
    }
    return 'Unknown User';
  }

  /// --- `toFirestore` Method ---
  /// Converts a Chat object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'propertyName': propertyName,
      'propertyAddress': propertyAddress,
      'propertyImageUrls': propertyImageUrls,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserFirstName': otherUserFirstName,
      'otherUserLastName': otherUserLastName,
      'otherUserProfilePicture': otherUserProfilePicture,
    };
  }

  /// --- `fromFirestore` Factory ---
  /// Creates a Chat object from a Firestore DocumentSnapshot
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      propertyName: data['propertyName'] as String?,
      propertyAddress: data['propertyAddress'] as String?,
      propertyImageUrls: (data['propertyImageUrls'] as List?)?.map((e) => e.toString()).toList(),
      otherUserId: data['otherUserId'] as String? ?? '',
      otherUserName: data['otherUserName'] as String?,
      otherUserFirstName: data['otherUserFirstName'] as String?,
      otherUserLastName: data['otherUserLastName'] as String?,
      otherUserProfilePicture: data['otherUserProfilePicture'] as String?,
    );
  }
}
