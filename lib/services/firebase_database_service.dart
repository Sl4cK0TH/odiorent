import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odiorent/models/message.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/cloudinary_service.dart';
import 'package:path/path.dart' as p;

/// Firebase Database Service
/// Replaces Supabase DatabaseService with Cloud Firestore
class FirebaseDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  // ========== PROPERTY CRUD OPERATIONS ==========

  /// --- CREATE PROPERTY ---
  Future<void> createProperty(Property property) async {
    try {
      // Anti-duplication check
      final existingQuery = await _firestore
          .collection('properties')
          .where('name', isEqualTo: property.name)
          .where('landlordId', isEqualTo: property.landlordId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('A property with the same name already exists.');
      }

      // Create property document
      final docRef = await _firestore.collection('properties').add(
            property.toFirestore()
              ..['createdAt'] = FieldValue.serverTimestamp()
              ..['averageRating'] = 0.0
              ..['ratingCount'] = 0,
          );

      debugPrint("✅ Property created successfully with ID: ${docRef.id}");

      // Create notifications for all admins
      final adminsQuery =
          await _firestore.collection('users').where('role', isEqualTo: 'admin').get();

      final batch = _firestore.batch();

      for (var adminDoc in adminsQuery.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipient_id': adminDoc.id,
          'title': 'New Property Submission',
          'body': 'A new property "${property.name}" is awaiting review.',
          'link': '/admin/property/${docRef.id}',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint("✅ Created ${adminsQuery.docs.length} notifications for admins");
    } catch (e) {
      debugPrint("❌ Error creating property: $e");
      rethrow;
    }
  }

  /// --- UPDATE PROPERTY ---
  Future<void> updateProperty(Property property) async {
    try {
      if (property.id == null) {
        throw Exception("Property ID cannot be null when updating.");
      }

      await _firestore
          .collection('properties')
          .doc(property.id)
          .update(property.toFirestore());

      debugPrint("✅ Property ${property.id} updated successfully!");
    } catch (e) {
      debugPrint("❌ Error updating property: $e");
      rethrow;
    }
  }

  /// --- DELETE PROPERTY ---
  Future<void> deleteProperty(String propertyId) async {
    try {
      // Delete property ratings subcollection first
      final ratingsQuery = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ratings')
          .get();

      final batch = _firestore.batch();
      for (var doc in ratingsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete property document
      batch.delete(_firestore.collection('properties').doc(propertyId));

      await batch.commit();
      debugPrint("✅ Property $propertyId deleted successfully!");
    } catch (e) {
      debugPrint("❌ Error deleting property: $e");
      rethrow;
    }
  }

  /// --- GET LANDLORD PROPERTIES ---
  Future<List<Property>> getLandlordProperties(String landlordId) async {
    try {
      debugPrint("📍 Fetching properties for landlord: $landlordId");
      
      final querySnapshot = await _firestore
          .collection('properties')
          .where('landlordId', isEqualTo: landlordId)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint("📦 Found ${querySnapshot.docs.length} property documents");

      final properties = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final property = Property.fromFirestore(doc);
          // Fetch landlord details
          return await _enrichPropertyWithLandlordDetails(property);
        }).toList(),
      );

      debugPrint("✅ Fetched ${properties.length} properties for landlord $landlordId");
      return properties;
    } catch (e) {
      debugPrint("❌ Error getting landlord properties: $e");
      debugPrint("📌 If you see 'index' error, create index in Firebase Console");
      debugPrint("   Collection: properties, Fields: landlordId (Ascending), createdAt (Descending)");
      // Try fallback query without orderBy
      try {
        final fallbackSnapshot = await _firestore
            .collection('properties')
            .where('landlordId', isEqualTo: landlordId)
            .get();
        
        debugPrint("⚠️ Using fallback query (no ordering): ${fallbackSnapshot.docs.length} docs");
        
        final properties = await Future.wait(
          fallbackSnapshot.docs.map((doc) async {
            final property = Property.fromFirestore(doc);
            return await _enrichPropertyWithLandlordDetails(property);
          }).toList(),
        );
        
        // Sort in memory
        properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return properties;
      } catch (fallbackError) {
        debugPrint("❌ Fallback query also failed: $fallbackError");
        return [];
      }
    }
  }

  /// --- GET APPROVED PROPERTIES (with client-side search) ---
  Future<List<Property>> getApprovedProperties({String? searchQuery}) async {
    try {
      QuerySnapshot querySnapshot;
      
      try {
        // Try query with orderBy (requires composite index)
        querySnapshot = await _firestore
            .collection('properties')
            .where('status', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .get();
        debugPrint("✅ Using indexed query for approved properties");
      } catch (e) {
        // Fallback: query without orderBy if index doesn't exist
        debugPrint("⚠️ Index missing for approved+createdAt, using fallback query");
        debugPrint("   Create index: https://console.firebase.google.com/project/_/firestore/indexes");
        querySnapshot = await _firestore
            .collection('properties')
            .where('status', isEqualTo: 'approved')
            .get();
        debugPrint("⚠️ Using fallback query (no ordering): ${querySnapshot.docs.length} docs");
      }

      List<Property> properties = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final property = Property.fromFirestore(doc);
          return await _enrichPropertyWithLandlordDetails(property);
        }).toList(),
      );

      // Sort manually if using fallback or after filtering
      properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Client-side filtering if search query provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        properties = properties.where((property) {
          return property.name.toLowerCase().contains(lowerQuery) ||
              property.address.toLowerCase().contains(lowerQuery) ||
              property.description.toLowerCase().contains(lowerQuery) ||
              (property.landlordUserName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (property.landlordFirstName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (property.landlordLastName?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      debugPrint("✅ Fetched ${properties.length} approved properties");
      return properties;
    } catch (e) {
      debugPrint("❌ Error getting approved properties: $e");
      return [];
    }
  }

  /// --- GET PENDING PROPERTIES (Admin) ---
  Future<List<Property>> getPendingProperties() async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final properties = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final property = Property.fromFirestore(doc);
          return await _enrichPropertyWithLandlordDetails(property);
        }).toList(),
      );

      debugPrint("✅ Fetched ${properties.length} pending properties");
      return properties;
    } catch (e) {
      debugPrint("❌ Error getting pending properties: $e");
      return [];
    }
  }

  /// --- GET ALL PROPERTIES WITH LANDLORD DETAILS (Admin) ---
  Future<List<Property>> getAllPropertiesWithLandlordDetails() async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .orderBy('createdAt', descending: true)
          .get();

      final properties = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final property = Property.fromFirestore(doc);
          return await _enrichPropertyWithLandlordDetails(property);
        }).toList(),
      );

      debugPrint("✅ Fetched ${properties.length} total properties");
      return properties;
    } catch (e) {
      debugPrint("❌ Error getting all properties: $e");
      return [];
    }
  }

  /// --- GET PROPERTIES BY STATUS (Admin) ---
  Future<List<Property>> getPropertiesByStatusWithLandlordDetails(
      PropertyStatus status) async {
    try {
      final statusString = statusToString(status);
      QuerySnapshot querySnapshot;
      
      try {
        // Try query with orderBy (requires composite index)
        querySnapshot = await _firestore
            .collection('properties')
            .where('status', isEqualTo: statusString)
            .orderBy('createdAt', descending: true)
            .get();
        debugPrint("✅ Using indexed query for $statusString properties");
      } catch (e) {
        // Fallback: query without orderBy if index doesn't exist
        debugPrint("⚠️ Index missing for status+createdAt, using fallback query");
        debugPrint("   Create index: https://console.firebase.google.com/project/_/firestore/indexes");
        querySnapshot = await _firestore
            .collection('properties')
            .where('status', isEqualTo: statusString)
            .get();
        debugPrint("⚠️ Using fallback query (no ordering): ${querySnapshot.docs.length} docs");
      }

      final properties = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final property = Property.fromFirestore(doc);
          return await _enrichPropertyWithLandlordDetails(property);
        }).toList(),
      );

      // Sort manually if using fallback query
      properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint("✅ Fetched ${properties.length} $statusString properties");
      return properties;
    } catch (e) {
      debugPrint("❌ Error getting $status properties: $e");
      return [];
    }
  }

  /// --- GET PROPERTY WITH LANDLORD DETAILS ---
  Future<Map<String, dynamic>> getPropertyWithLandlordDetails(String propertyId) async {
    try {
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();

      if (!propertyDoc.exists) {
        throw Exception('Property not found');
      }

      final propertyData = propertyDoc.data()!;
      final landlordId = propertyData['landlordId'];

      // Fetch landlord details
      final landlordDoc = await _firestore.collection('users').doc(landlordId).get();
      final landlordData = landlordDoc.data() ?? {};

      // Merge property and landlord data
      return {
        ...propertyData,
        'id': propertyDoc.id,
        'landlord_user_name': landlordData['userName'],
        'landlord_first_name': landlordData['firstName'],
        'landlord_last_name': landlordData['lastName'],
        'landlord_email': landlordData['email'],
        'landlord_phone_number': landlordData['phoneNumber'],
        'landlord_profile_picture_url': landlordData['profilePictureUrl'],
      };
    } catch (e) {
      debugPrint("❌ Error getting property with landlord details: $e");
      rethrow;
    }
  }

  /// Helper: Enrich property with landlord details
  Future<Property> _enrichPropertyWithLandlordDetails(Property property) async {
    try {
      final landlordDoc =
          await _firestore.collection('users').doc(property.landlordId).get();

      if (landlordDoc.exists) {
        final landlordData = landlordDoc.data()!;
        return property.copyWith(
          landlordUserName: landlordData['userName'],
          landlordFirstName: landlordData['firstName'],
          landlordLastName: landlordData['lastName'],
          landlordEmail: landlordData['email'],
          landlordPhoneNumber: landlordData['phoneNumber'],
          landlordProfilePictureUrl: landlordData['profilePictureUrl'],
        );
      }

      return property;
    } catch (e) {
      debugPrint("⚠️ Error fetching landlord details: $e");
      return property;
    }
  }

  /// --- UPDATE PROPERTY STATUS (Admin) ---
  Future<void> updatePropertyStatus({
    required String propertyId,
    required PropertyStatus status,
    required String landlordId,
    required String propertyName,
  }) async {
    try {
      final statusString = statusToString(status);
      final updateData = <String, dynamic>{
        'status': statusString,
      };

      if (status == PropertyStatus.approved) {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
      } else {
        updateData['approvedAt'] = null;
      }

      await _firestore.collection('properties').doc(propertyId).update(updateData);

      // Create notification for landlord
      final notificationBody =
          'Your property "$propertyName" has been ${statusString == 'approved' ? 'Approved' : 'Rejected'}.';

      await _firestore.collection('notifications').add({
        'recipientId': landlordId,
        'title': 'Property Status Update',
        'body': notificationBody,
        'link': '/landlord/property/$propertyId',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Property $propertyId status updated to: $statusString");
    } catch (e) {
      debugPrint("❌ Error updating property status: $e");
      rethrow;
    }
  }

  /// --- GET PROPERTIES COUNT ---
  Future<int> getPropertiesCount() async {
    try {
      final querySnapshot = await _firestore.collection('properties').count().get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint("❌ Error getting properties count: $e");
      return 0;
    }
  }

  /// --- GET PROPERTIES COUNT BY STATUS ---
  Future<int> getPropertiesCountByStatus(PropertyStatus status) async {
    try {
      final statusString = statusToString(status);
      final querySnapshot = await _firestore
          .collection('properties')
          .where('status', isEqualTo: statusString)
          .count()
          .get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint("❌ Error getting properties count by status: $e");
      return 0;
    }
  }

  // ========== PROPERTY RATINGS ==========

  /// --- ADD PROPERTY RATING ---
  Future<void> addPropertyRating({
    required String propertyId,
    required String userId,
    int? rating,
    String? comment,
  }) async {
    try {
      // At least one of rating or comment must be provided
      if (rating == null && (comment == null || comment.isEmpty)) {
        throw Exception('Either rating or comment must be provided');
      }

      // Use userId as document ID for upsert behavior (one rating per user per property)
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ratings')
          .doc(userId)
          .set({
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Recalculate average rating only if rating was provided
      if (rating != null) {
        await _recalculatePropertyRating(propertyId);
      }

      debugPrint("✅ Rating/review added/updated for property $propertyId by user $userId");
    } catch (e) {
      debugPrint("❌ Error adding/updating rating: $e");
      rethrow;
    }
  }

  /// Helper: Recalculate property average rating
  Future<void> _recalculatePropertyRating(String propertyId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        await _firestore.collection('properties').doc(propertyId).update({
          'averageRating': 0.0,
          'ratingCount': 0,
        });
        return;
      }

      double total = 0;
      int ratingCount = 0;
      
      for (var doc in ratingsSnapshot.docs) {
        final rating = doc.data()['rating'] as num?;
        if (rating != null) {
          total += rating.toDouble();
          ratingCount++;
        }
      }

      final average = ratingCount > 0 ? total / ratingCount : 0.0;

      await _firestore.collection('properties').doc(propertyId).update({
        'averageRating': average,
        'ratingCount': ratingCount,
      });

      debugPrint("✅ Updated property rating: $average ($ratingCount ratings)");
    } catch (e) {
      debugPrint("❌ Error recalculating property rating: $e");
    }
  }

  /// --- GET PROPERTY RATINGS ---
  Future<List<Map<String, dynamic>>> getPropertyRatings(String propertyId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .get();

      final ratings = await Future.wait(
        ratingsSnapshot.docs.map((doc) async {
          final data = doc.data();
          final userId = data['userId'] as String;

          // Get user details
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.exists ? userDoc.data() : null;

          return {
            'id': doc.id,
            'rating': data['rating'],
            'comment': data['comment'],
            'createdAt': data['createdAt'],
            'userName': userData?['userName'],
            'firstName': userData?['firstName'],
            'lastName': userData?['lastName'],
            'profilePictureUrl': userData?['profilePictureUrl'],
          };
        }).toList(),
      );

      debugPrint("✅ Fetched ${ratings.length} ratings for property $propertyId");
      return ratings;
    } catch (e) {
      debugPrint("❌ Error getting property ratings: $e");
      return [];
    }
  }

  /// --- GET USER'S RATING FOR PROPERTY ---
  Future<Map<String, dynamic>?> getUserRatingForProperty({
    required String propertyId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ratings')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return {
        'rating': data['rating'],
        'comment': data['comment'],
        'createdAt': data['createdAt'],
      };
    } catch (e) {
      debugPrint("❌ Error getting user rating: $e");
      return null;
    }
  }

  // ========== USER PROFILE OPERATIONS ==========

  /// --- UPDATE USER PROFILE ---
  Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? phoneNumber,
    String? userName,
    String? profilePictureUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['firstName'] = firstName;
      if (middleName != null) updates['middleName'] = middleName;
      if (lastName != null) updates['lastName'] = lastName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (userName != null) updates['userName'] = userName;
      if (profilePictureUrl != null) updates['profilePictureUrl'] = profilePictureUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
        debugPrint("✅ Profile updated successfully for user $userId");
      }
    } catch (e) {
      debugPrint("❌ Error updating user profile: $e");
      rethrow;
    }
  }

  /// --- UPDATE USER LAST SEEN ---
  Future<void> updateUserLastSeen(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("⚠️ Error updating last seen: $e");
      // Fail silently
    }
  }

  /// --- SAVE FCM TOKEN ---
  Future<void> saveFcmToken(String token, String userId) async {
    try {
      // Use token as document ID for automatic deduplication
      await _firestore.collection('fcmTokens').doc(token).set({
        'userId': userId,
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ FCM token saved");
    } catch (e) {
      debugPrint("❌ Error saving FCM token: $e");
    }
  }

  // ========== CHAT OPERATIONS ==========

  /// --- GET OR CREATE CHAT ---
  Future<Map<String, dynamic>> getOrCreateChat({
    required String renterId,
    required String landlordId,
    required String propertyId,
  }) async {
    try {
      debugPrint("Getting or creating chat for property: $propertyId");

      // Check if chat already exists
      final existingQuery = await _firestore
          .collection('chats')
          .where('renterId', isEqualTo: renterId)
          .where('landlordId', isEqualTo: landlordId)
          .where('propertyId', isEqualTo: propertyId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final chatId = existingQuery.docs.first.id;
        debugPrint("✅ Chat already exists: $chatId");
        return {'chatId': chatId, 'isNewChat': false};
      }

      // Create new chat
      final docRef = await _firestore.collection('chats').add({
        'renterId': renterId,
        'landlordId': landlordId,
        'propertyId': propertyId,
        'participants': [renterId, landlordId],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Created new chat: ${docRef.id}");
      return {'chatId': docRef.id, 'isNewChat': true};
    } catch (e) {
      debugPrint("❌ Error getting or creating chat: $e");
      rethrow;
    }
  }

  /// --- GET USER CHATS ---
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      debugPrint("Getting chats for user: $userId");

      QuerySnapshot querySnapshot;
      
      try {
        // Try query with orderBy (requires composite index)
        querySnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageAt', descending: true)
            .get();
        debugPrint("✅ Using indexed query for user chats");
      } catch (e) {
        // Fallback: query without orderBy if index doesn't exist
        debugPrint("⚠️ Index missing for participants+lastMessageAt, using fallback query");
        debugPrint("   Create index: https://console.firebase.google.com/project/_/firestore/indexes");
        querySnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: userId)
            .get();
        debugPrint("⚠️ Using fallback query (no ordering): ${querySnapshot.docs.length} docs");
      }

      final chats = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          
          // Fetch property details
          final propertyId = data['propertyId'];
          Map<String, dynamic>? propertyData;
          if (propertyId != null) {
            final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
            if (propertyDoc.exists) {
              propertyData = {
                'name': propertyDoc.data()?['name'],
                'address': propertyDoc.data()?['address'],
                'image_urls': propertyDoc.data()?['imageUrls'],
              };
            }
          }

          // Fetch participant details
          final renterId = data['renterId'] as String;
          final landlordId = data['landlordId'] as String;

          final renterDoc = await _firestore.collection('users').doc(renterId).get();
          final landlordDoc = await _firestore.collection('users').doc(landlordId).get();

          final renterData = renterDoc.exists ? renterDoc.data() as Map<String, dynamic> : null;
          final landlordData = landlordDoc.exists ? landlordDoc.data() as Map<String, dynamic> : null;

          return {
            'id': doc.id,
            'lastMessage': data['lastMessage'],
            'lastMessageAt': data['lastMessageAt'],
            'property': propertyData,
            'participant_1': renterData == null ? null : {
              'id': renterId,
              'user_name': renterData['userName'],
              'first_name': renterData['firstName'],
              'last_name': renterData['lastName'],
              'profile_picture_url': renterData['profilePictureUrl'],
            },
            'participant_2': landlordData == null ? null : {
              'id': landlordId,
              'user_name': landlordData['userName'],
              'first_name': landlordData['firstName'],
              'last_name': landlordData['lastName'],
              'profile_picture_url': landlordData['profilePictureUrl'],
            },
          };
        }).toList(),
      );

      // Sort manually by lastMessageAt (newest first)
      chats.sort((a, b) {
        final aTime = a['lastMessageAt'] as Timestamp?;
        final bTime = b['lastMessageAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      debugPrint("✅ Fetched ${chats.length} chats");
      return chats;
    } catch (e) {
      debugPrint("❌ Error getting user chats: $e");
      return [];
    }
  }

  /// --- GET CHAT MESSAGES (Real-time Stream) ---
  Stream<List<Message>> getChatMessages(String chatId) {
    debugPrint("Setting up message stream for chat: $chatId");

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      debugPrint("Received ${snapshot.docs.length} messages");
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  /// --- SEND MESSAGE ---
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? text,
    XFile? attachmentFile,
  }) async {
    try {
      debugPrint("Sending message to chat: $chatId");

      if (text == null && attachmentFile == null) {
        throw Exception("Message must have either text or an attachment.");
      }

      String? attachmentUrl;
      MessageAttachmentType? attachmentType;
      String lastMessageText = text ?? "Sent an attachment";

      // Handle attachment upload
      if (attachmentFile != null) {
        // Note: fileBytes read for future use, currently using CloudinaryService
        // final fileBytes = await attachmentFile.readAsBytes();
        final fileExt = p.extension(attachmentFile.name);

        if (['.png', '.jpg', '.jpeg', '.gif', '.webp'].contains(fileExt.toLowerCase())) {
          attachmentType = MessageAttachmentType.image;
          lastMessageText = "Sent an image";
        } else if (['.mp4', '.mov', '.avi', '.webm'].contains(fileExt.toLowerCase())) {
          attachmentType = MessageAttachmentType.video;
          lastMessageText = "Sent a video";
        } else {
          attachmentType = MessageAttachmentType.file;
          lastMessageText = "Sent a file";
        }

        attachmentUrl = await _cloudinary.uploadXFile(
          file: attachmentFile,
          folder: 'chat_attachments',
          userId: senderId,
        );
      }

      // Create message
      final message = Message(
        chatId: chatId,
        senderId: senderId,
        text: text,
        sentAt: DateTime.now(),
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
      );

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMessageText,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Message sent successfully");
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
      rethrow;
    }
  }

  /// --- MARK MESSAGES AS READ ---
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('readAt', isNull: true)
          .get();

      final batch = _firestore.batch();
      
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'readAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();
      debugPrint("✅ Marked ${unreadMessages.docs.length} messages as read");
    } catch (e) {
      debugPrint("❌ Error marking messages as read: $e");
    }
  }

  // ========== NOTIFICATIONS ==========

  /// --- GET USER NOTIFICATIONS ---
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint("❌ Error getting notifications: $e");
      return [];
    }
  }

  /// --- MARK NOTIFICATION AS READ ---
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint("❌ Error marking notification as read: $e");
    }
  }

  /// --- GET UNREAD NOTIFICATIONS COUNT ---
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint("❌ Error getting unread notifications count: $e");
      return 0;
    }
  }

  // ========== BOOKMARKS OPERATIONS ==========

  /// --- ADD BOOKMARK ---
  Future<void> addBookmark({
    required String userId,
    required String propertyId,
  }) async {
    try {
      final bookmarkRef = _firestore.collection('bookmarks').doc('${userId}_$propertyId');
      
      await bookmarkRef.set({
        'userId': userId,
        'propertyId': propertyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Bookmark added successfully");
    } catch (e) {
      debugPrint("❌ Error adding bookmark: $e");
      rethrow;
    }
  }

  /// --- REMOVE BOOKMARK ---
  Future<void> removeBookmark({
    required String userId,
    required String propertyId,
  }) async {
    try {
      final bookmarkRef = _firestore.collection('bookmarks').doc('${userId}_$propertyId');
      await bookmarkRef.delete();

      debugPrint("✅ Bookmark removed successfully");
    } catch (e) {
      debugPrint("❌ Error removing bookmark: $e");
      rethrow;
    }
  }

  /// --- CHECK IF PROPERTY IS BOOKMARKED ---
  Future<bool> isPropertyBookmarked({
    required String userId,
    required String propertyId,
  }) async {
    try {
      final bookmarkRef = _firestore.collection('bookmarks').doc('${userId}_$propertyId');
      final doc = await bookmarkRef.get();
      return doc.exists;
    } catch (e) {
      debugPrint("❌ Error checking bookmark: $e");
      return false;
    }
  }

  /// --- GET USER BOOKMARKS ---
  Future<List<Property>> getUserBookmarks(String userId) async {
    try {
      QuerySnapshot bookmarksSnapshot;
      
      try {
        // Try query with orderBy (requires index)
        bookmarksSnapshot = await _firestore
            .collection('bookmarks')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
        debugPrint("✅ Using indexed query for bookmarks");
      } catch (e) {
        // Fallback: query without orderBy
        debugPrint("⚠️ Index missing for userId+createdAt, using fallback query");
        bookmarksSnapshot = await _firestore
            .collection('bookmarks')
            .where('userId', isEqualTo: userId)
            .get();
      }

      final properties = await Future.wait(
        bookmarksSnapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final propertyId = data['propertyId'] as String?;
          
          if (propertyId == null) {
            return null;
          }

          final propertyDoc = await _firestore
              .collection('properties')
              .doc(propertyId)
              .get();

          if (!propertyDoc.exists) {
            return null;
          }

          final property = Property.fromFirestore(propertyDoc);
          return await _enrichPropertyWithLandlordDetails(property);
        }).toList(),
      );

      // Filter out nulls and sort manually
      final validProperties = properties.whereType<Property>().toList();
      validProperties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint("✅ Fetched ${validProperties.length} bookmarked properties");
      return validProperties;
    } catch (e) {
      debugPrint("❌ Error getting user bookmarks: $e");
      return [];
    }
  }

  /// --- GET BOOKMARK STREAM (Real-time) ---
  Stream<bool> isPropertyBookmarkedStream({
    required String userId,
    required String propertyId,
  }) {
    return _firestore
        .collection('bookmarks')
        .doc('${userId}_$propertyId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ========================================
  // VIDEO LIKE METHODS
  // ========================================

  /// Like a video
  Future<void> likeVideo({
    required String propertyId,
    required String videoUrl,
    required String userId,
  }) async {
    try {
      // Create unique ID for this like: propertyId_videoIndex_userId
      final videoIndex = _getVideoIndex(videoUrl);
      final likeId = '${propertyId}_video${videoIndex}_$userId';

      await _firestore.collection('videoLikes').doc(likeId).set({
        'propertyId': propertyId,
        'videoUrl': videoUrl,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Video liked: $likeId");
    } catch (e) {
      debugPrint("❌ Error liking video: $e");
      rethrow;
    }
  }

  /// Unlike a video
  Future<void> unlikeVideo({
    required String propertyId,
    required String videoUrl,
    required String userId,
  }) async {
    try {
      final videoIndex = _getVideoIndex(videoUrl);
      final likeId = '${propertyId}_video${videoIndex}_$userId';

      await _firestore.collection('videoLikes').doc(likeId).delete();

      debugPrint("✅ Video unliked: $likeId");
    } catch (e) {
      debugPrint("❌ Error unliking video: $e");
      rethrow;
    }
  }

  /// Check if user has liked a video
  Future<bool> isVideoLiked({
    required String propertyId,
    required String videoUrl,
    required String userId,
  }) async {
    try {
      final videoIndex = _getVideoIndex(videoUrl);
      final likeId = '${propertyId}_video${videoIndex}_$userId';

      final doc = await _firestore.collection('videoLikes').doc(likeId).get();
      return doc.exists;
    } catch (e) {
      debugPrint("❌ Error checking if video is liked: $e");
      return false;
    }
  }

  /// Get like count for a specific video
  Future<int> getVideoLikeCount({
    required String propertyId,
    required String videoUrl,
  }) async {
    try {
      final videoIndex = _getVideoIndex(videoUrl);
      
      final snapshot = await _firestore
          .collection('videoLikes')
          .where('propertyId', isEqualTo: propertyId)
          .where('videoUrl', isEqualTo: videoUrl)
          .get();

      debugPrint("✅ Video $videoIndex has ${snapshot.docs.length} likes");
      return snapshot.docs.length;
    } catch (e) {
      debugPrint("❌ Error getting video like count: $e");
      return 0;
    }
  }

  /// Get like count stream for real-time updates
  Stream<int> getVideoLikeCountStream({
    required String propertyId,
    required String videoUrl,
  }) {
    return _firestore
        .collection('videoLikes')
        .where('propertyId', isEqualTo: propertyId)
        .where('videoUrl', isEqualTo: videoUrl)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Check if video is liked (stream for real-time updates)
  Stream<bool> isVideoLikedStream({
    required String propertyId,
    required String videoUrl,
    required String userId,
  }) {
    final videoIndex = _getVideoIndex(videoUrl);
    final likeId = '${propertyId}_video${videoIndex}_$userId';

    return _firestore
        .collection('videoLikes')
        .doc(likeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Helper: Extract video index from URL (0 or 1 for first/second video)
  int _getVideoIndex(String videoUrl) {
    // Simple hash to determine index (0 or 1)
    // In practice, you might want to use actual ordering
    return videoUrl.hashCode.abs() % 2;
  }
}
