import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart'; // We need this to work with Property objects
import 'package:odiorent/models/message.dart'; // For chat functionality

// Get the global Supabase client
final supabase = Supabase.instance.client;

/// This class will handle all database interactions with Supabase.
/// We will add all our database-related functions here.
class DatabaseService {
  /// --- CREATE PROPERTY (Day 3 Task) ---
  Future<void> createProperty(Property property) async {
    // Anti-duplication check
    final existingCheck = await supabase
        .from('properties')
        .select('id')
        .eq('name', property.name)
        .eq('landlord_id', property.landlordId)
        .maybeSingle();

    if (existingCheck != null) {
      throw Exception('A property with the same name already exists.');
    }

    try {
      final propertyMap = property.toJson();
      // Insert the property and immediately select it back to get the generated ID
      final newProperty = await supabase.from('properties').insert(propertyMap).select().single();
      debugPrint("Property created successfully with ID: ${newProperty['id']}");

      // --- Create Notifications for all Admins ---
      // 1. Fetch all admin user IDs
      final adminUsers = await supabase.from('profiles').select('id').eq('role', 'admin');

      // 2. Create a list of notification maps
      final notifications = (adminUsers as List).map((admin) {
        return {
          'recipient_id': admin['id'],
          'title': 'New Property Submission',
          'body': 'A new property "${property.name}" is awaiting review.',
          // Optional: You could build a deep link to the property view
          // 'link': '/admin/property/${newProperty['id']}',
        };
      }).toList();

      // 3. Insert all notifications in a single batch
      if (notifications.isNotEmpty) {
        await supabase.from('notifications').insert(notifications);
        debugPrint("Created ${notifications.length} notifications for admins.");
      }
      // --- End Notification ---

    } catch (e) {
      debugPrint("Error creating property: $e");
      rethrow;
    }
  }

  /// --- DELETE PROPERTY (Landlord Function) ---
  Future<void> deleteProperty(String propertyId) async {
    try {
      await supabase.from('properties').delete().eq('id', propertyId);
      debugPrint("Property $propertyId deleted successfully!");
    } catch (e) {
      debugPrint("Error deleting property: $e");
      rethrow;
    }
  }

  /// --- UPDATE PROPERTY (Landlord Function) ---
  Future<void> updateProperty(Property property) async {
    try {
      final propertyMap = property.toJson();
      debugPrint("Updating property with ID: ${property.id}, Data: $propertyMap"); // Debugging line
      // The property ID must not be null when updating.
      if (property.id == null) {
        throw Exception("Property ID cannot be null when updating.");
      }
      await supabase.from('properties').update(propertyMap).eq('id', property.id!);
      debugPrint("Property ${property.id} updated successfully!");
    } catch (e) {
      debugPrint("Error updating property: $e");
      rethrow;
    }
  }

  /// --- GET LANDLORD PROPERTIES (Day 3 Task) ---
  Future<List<Property>> getLandlordProperties(String landlordId) async {
    try {
      final response = await supabase
          .from('properties_with_avg_rating') // Use the new view
          .select('*')
          .eq('landlord_id', landlordId);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromMap(json as Map<String, dynamic>))
          .toList();

      return properties;
    } catch (e) {
      debugPrint("Error getting landlord properties: $e");
      return [];
    }
  }

  /// --- GET PENDING PROPERTIES (Admin Function) ---
  Future<List<Property>> getPendingProperties() async {
    try {
      final response = await supabase
          .from('properties_with_avg_rating') // Use the new view
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromMap(json as Map<String, dynamic>))
          .toList();

      debugPrint("Fetched ${properties.length} pending properties");
      return properties;
    } catch (e) {
      debugPrint("Error getting pending properties: $e");
      return [];
    }
  }

  /// --- GET ALL PROPERTIES WITH LANDLORD DETAILS (Admin Function) ---
  Future<List<Property>> getAllPropertiesWithLandlordDetails() async {
    try {
      final response = await supabase
          .from('properties_with_avg_rating') // Use the new view
          .select('*')
          .order('created_at', ascending: false);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromMap(json as Map<String, dynamic>))
          .toList();

      debugPrint("Fetched ${properties.length} overall properties with landlord details");
      return properties;
    } catch (e) {
      debugPrint("Error getting all properties with landlord details: $e");
      return [];
    }
  }

  /// --- GET PROPERTIES BY STATUS WITH LANDLORD DETAILS (Admin Function) ---
  Future<List<Property>> getPropertiesByStatusWithLandlordDetails(
      String status) async {
    try {
      final response = await supabase
          .from('properties_with_avg_rating') // Use the new view
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromMap(json as Map<String, dynamic>))
          .toList();

      debugPrint("Fetched ${properties.length} $status properties with landlord details");
      return properties;
    } catch (e) {
      debugPrint("Error getting $status properties with landlord details: $e");
      return [];
    }
  }

  /// --- UPDATE PROPERTY STATUS (Admin Function) ---
  Future<void> updatePropertyStatus({
    required String propertyId,
    required String status,
    required String landlordId,
    required String propertyName,
  }) async {
    try {
      if (status != 'approved' && status != 'rejected' && status != 'pending') {
        throw Exception(
          'Invalid status. Must be "approved", "rejected", or "pending"',
        );
      }

      final Map<String, dynamic> updateData = {'status': status};
      if (status == 'approved') {
        updateData['approved_at'] = DateTime.now().toIso8601String();
      } else {
        updateData['approved_at'] =
            null; // Clear approved_at if status changes from approved
      }

      await supabase.from('properties').update(updateData).eq('id', propertyId);

      // --- Create Notification for Landlord ---
      final notificationBody =
          'Your property "$propertyName" has been ${status == 'approved' ? 'Approved' : 'Rejected'}.';
      await supabase.from('notifications').insert({
        'recipient_id': landlordId,
        'title': 'Property Status Update',
        'body': notificationBody,
      });
      // --- End Notification ---

      debugPrint("Property $propertyId status updated to: $status");
    } catch (e) {
      debugPrint("Error updating property status: $e");
      rethrow;
    }
  }

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
      final Map<String, dynamic> updates = {};
      if (firstName != null) updates['first_name'] = firstName;
      if (middleName != null) updates['middle_name'] = middleName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (userName != null) updates['user_name'] = userName;
      if (profilePictureUrl != null) updates['profile_picture_url'] = profilePictureUrl;

      if (updates.isNotEmpty) {
        debugPrint("Attempting to update profile for user $userId with data: $updates");
        await supabase.from('profiles').update(updates).eq('id', userId);
        debugPrint("✅ Profile update successful for user $userId");
      }
    } catch (e) {
      debugPrint("❌ Error updating user profile: $e");
      rethrow;
    }
  }

  /// --- GET PROPERTY WITH LANDLORD DETAILS (Renter Function) ---
  Future<Map<String, dynamic>> getPropertyWithLandlordDetails(String propertyId) async {
    try {
      final response = await supabase
          .from('properties_with_avg_rating') // Use the new view
          .select('*')
          .eq('id', propertyId)
          .single();

      return response;
    } catch (e) {
      debugPrint("Error getting property with landlord details: $e");
      rethrow;
    }
  }

  /// --- GET APPROVED PROPERTIES (Day 5 Task, updated for Search & Ratings) ---
  /// Fetches all 'approved' properties, with optional keyword filtering via RPC.
  Future<List<Property>> getApprovedProperties({String? searchQuery}) async {
    try {
      late final List<dynamic> data;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // If there's a search query, call the RPC function
        data = await supabase.rpc(
          'search_properties',
          params: {'search_term': searchQuery},
        );
      } else {
        // Otherwise, fetch all approved properties from the view
        data = await supabase
            .from('properties_with_avg_rating')
            .select('*')
            .eq('status', 'approved')
            .order('created_at', ascending: false);
      }

      final properties = data
          .map((json) => Property.fromMap(json as Map<String, dynamic>))
          .toList();

      debugPrint("Fetched ${properties.length} approved properties");
      return properties;
    } catch (e) {
      debugPrint("Error getting approved properties: $e");
      return [];
    }
  }

  /// --- ADD PROPERTY RATING (Day 6 Task) ---
  /// Allows a user to add a rating for a property.
  Future<void> addPropertyRating({
    required String propertyId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      await supabase.from('property_ratings').upsert({
        'property_id': propertyId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      }, onConflict: 'unique_user_property_rating'); // Use upsert to handle updates
      debugPrint("Rating added/updated successfully for property $propertyId by user $userId");
    } catch (e) {
      debugPrint("Error adding/updating rating: $e");
      rethrow;
    }
  }

  /// --- GET ALL PROPERTIES COUNT (Admin Function) ---
  Future<int> getPropertiesCount() async {
    try {
      final response = await supabase
          .from('properties')
          .select('count')
          .single(); // Use .single() to get the count directly

      return response['count'] as int;
    } catch (e) {
      debugPrint("Error getting all properties count: $e");
      return 0;
    }
  }

  /// --- GET PROPERTIES COUNT BY STATUS (Admin Function) ---
  /// Fetches the number of properties with a specific status.
  Future<int> getPropertiesCountByStatus(String status) async {
    try {
      final response = await supabase
          .from('properties')
          .select('count')
          .eq('status', status)
          .single(); // Use .single() to get the count directly

      return response['count'] as int;
    } catch (e) {
      debugPrint("Error getting properties count by status '$status': $e");
      return 0;
    }
  }

  // ========== CHAT FUNCTIONS (Day 6) ==========

  /// Get or create a chat between renter and landlord for a specific property
  Future<String> getOrCreateChat({
    required String renterId,
    required String landlordId,
    required String propertyId,
  }) async {
    try {
      debugPrint("Getting or creating chat for property: $propertyId");

      // Check if chat already exists
      final existingChat = await supabase
          .from('chats')
          .select()
          .eq('renter_id', renterId)
          .eq('landlord_id', landlordId)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (existingChat != null) {
        debugPrint("Chat already exists: ${existingChat['id']}");
        return existingChat['id'].toString();
      }

      // Create new chat
      final newChat = await supabase
          .from('chats')
          .insert({
            'renter_id': renterId,
            'landlord_id': landlordId,
            'property_id': propertyId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint("Created new chat: ${newChat['id']}");
      return newChat['id'].toString();
    } catch (e) {
      debugPrint("Error getting or creating chat: $e");
      rethrow;
    }
  }

  /// Get all chats for a user (either as renter or landlord)
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      debugPrint("Getting chats for user: $userId");

      final chats = await supabase
          .from('chats')
          .select('''
            *,
            properties:property_id (name, address, image_urls),
            renter:renter_id (email),
            landlord:landlord_id (email)
          ''')
          .or('renter_id.eq.$userId,landlord_id.eq.$userId')
          .order('created_at', ascending: false);

      debugPrint("Fetched ${chats.length} chats");
      return List<Map<String, dynamic>>.from(chats);
    } catch (e) {
      debugPrint("Error getting user chats: $e");
      return [];
    }
  }

  /// Get messages for a specific chat
  Stream<List<Message>> getChatMessages(String chatId) {
    debugPrint("Setting up message stream for chat: $chatId");

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('timestamp', ascending: true)
        .map((data) {
          debugPrint("Received ${data.length} messages");
          return data.map((msg) => Message.fromMap(msg)).toList();
        });
  }

  /// Send a message in a chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderEmail,
    required String content,
  }) async {
    try {
      debugPrint("Sending message to chat: $chatId");

      final message = Message(
        chatId: chatId,
        senderId: senderId,
        senderEmail: senderEmail,
        content: content,
        timestamp: DateTime.now(),
      );

      await supabase.from('messages').insert(message.toMap());

      // Update chat's last_message_at
      await supabase
          .from('chats')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      debugPrint("Message sent successfully");
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }
}