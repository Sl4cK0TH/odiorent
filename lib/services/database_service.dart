import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart'; // We need this to work with Property objects
import 'package:odiorent/models/message.dart'; // For chat functionality

// Get the global Supabase client
final supabase = Supabase.instance.client;

/// This class will handle all database interactions with Supabase.
/// We will add all our database-related functions here.
class DatabaseService {
  // Helper query string for selecting properties with joined landlord details
  static const String _propertySelectQuery = '''
    *,
    profiles!landlord_id(user_name, email)
  ''';

  /// --- CREATE PROPERTY (Day 3 Task) ---
  Future<void> createProperty(Property property) async {
    try {
      final propertyMap = property.toJson();
      await supabase.from('properties').insert(propertyMap);
      debugPrint("Property created successfully!");
    } catch (e) {
      debugPrint("Error creating property: $e");
      rethrow;
    }
  }

  /// --- GET LANDLORD PROPERTIES (Day 3 Task) ---
  Future<List<Property>> getLandlordProperties(String landlordId) async {
    try {
      final response = await supabase
          .from('properties')
          .select(_propertySelectQuery) // Use the helper query
          .eq('landlord_id', landlordId);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      return properties;
    } catch (e) {
      debugPrint("Error getting landlord properties: $e");
      return [];
    }
  }

  /// --- GET PENDING PROPERTIES (Admin Function) ---
  /// This method is now deprecated in favor of getPropertiesByStatusWithLandlordDetails
  /// but kept for existing usage.
  Future<List<Property>> getPendingProperties() async {
    try {
      final response = await supabase
          .from('properties')
          .select(_propertySelectQuery) // Use the helper query
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
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
          .from('properties')
          .select(_propertySelectQuery)
          .order('created_at', ascending: false);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
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
          .from('properties')
          .select(_propertySelectQuery)
          .eq('status', status)
          .order('created_at', ascending: false);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint("Fetched ${properties.length} $status properties with landlord details");
      return properties;
    } catch (e) {
      debugPrint("Error getting $status properties with landlord details: $e");
      return [];
    }
  }

  /// --- UPDATE PROPERTY STATUS (Admin Function) ---
  Future<void> updatePropertyStatus(String propertyId, String status) async {
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
        updateData['approved_at'] = null; // Clear approved_at if status changes from approved
      }

      await supabase
          .from('properties')
          .update(updateData)
          .eq('id', propertyId);

      debugPrint("Property $propertyId status updated to: $status");
    } catch (e) {
      debugPrint("Error updating property status: $e");
      rethrow;
    }
  }

  /// --- UPDATE USER PROFILE ---
  /// Updates the first name, middle name, and last name of a user in the 'profiles' table.
  Future<void> updateUserProfile({
    required String userId,
    required String firstName,
    String? middleName,
    required String lastName,
    required String phoneNumber, // New parameter
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName, // Will be null if not provided
        'phone_number': phoneNumber, // Update phone number
      };

      await supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      rethrow;
    }
  }

  /// --- GET APPROVED PROPERTIES (Day 5 Task) ---
  /// Fetches all properties with 'approved' status for renters to browse.
  ///
  /// Returns a list of [Property] objects.
  Future<List<Property>> getApprovedProperties() async {
    try {
      // Select all properties where status is 'approved'
      final response = await supabase
          .from('properties')
          .select(_propertySelectQuery) // Use the helper query
          .eq('status', 'approved')
          .order('created_at', ascending: false); // Most recent first

      // Convert the response to a list of Property objects
      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint("Fetched ${properties.length} approved properties");
      return properties;
    } catch (e) {
      debugPrint("Error getting approved properties: $e");
      // Return an empty list on error
      return [];
    }
  }

  /// --- GET ALL PROPERTIES COUNT (Admin Function) ---
  /// Fetches the total number of properties in the database.
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