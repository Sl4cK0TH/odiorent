import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:odiorent/models/property.dart'; // We need this to work with Property objects
import 'package:odiorent/models/message.dart'; // For chat functionality

// Get the global Supabase client
final supabase = Supabase.instance.client;

/// This class will handle all database interactions with Supabase.
/// We will add all our database-related functions here.
class DatabaseService {
  /// --- CREATE PROPERTY (Day 3 Task) ---
  Future<void> createProperty(Property property) async {
    try {
      final propertyMap = property.toJson();
      await supabase.from('properties').insert(propertyMap);
      if (kDebugMode) {
        if (kDebugMode) debugPrint("Property created successfully!");
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) debugPrint("Error creating property: $e");
      }
      rethrow;
    }
  }

  /// --- GET LANDLORD PROPERTIES (Day 3 Task) ---
  Future<List<Property>> getLandlordProperties(String landlordId) async {
    try {
      final response = await supabase
          .from('properties')
          .select()
          .eq('landlord_id', landlordId);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      return properties;
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting landlord properties: $e");
      return [];
    }
  }

  /// --- GET PENDING PROPERTIES (Admin Function) ---
  Future<List<Property>> getPendingProperties() async {
    try {
      final response = await supabase
          .from('properties')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) debugPrint("Fetched ${properties.length} pending properties");
      return properties;
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting pending properties: $e");
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

      await supabase
          .from('properties')
          .update({'status': status})
          .eq('id', propertyId);

      if (kDebugMode) debugPrint("Property $propertyId status updated to: $status");
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating property status: $e");
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
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false); // Most recent first

      // Convert the response to a list of Property objects
      final properties = (response as List<dynamic>)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) debugPrint("Fetched ${properties.length} approved properties");
      return properties;
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting approved properties: $e");
      // Return an empty list on error
      return [];
    }
  }

  // --- We will add more functions here as we build the app ---
  // - getOrCreateChat() (for Day 6)
  // - etc.

  // ========== CHAT FUNCTIONS (Day 6) ==========

  /// Get or create a chat between renter and landlord for a specific property
  Future<String> getOrCreateChat({
    required String renterId,
    required String landlordId,
    required String propertyId,
  }) async {
    try {
      if (kDebugMode) debugPrint("Getting or creating chat for property: $propertyId");

      // Check if chat already exists
      final existingChat = await supabase
          .from('chats')
          .select()
          .eq('renter_id', renterId)
          .eq('landlord_id', landlordId)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (existingChat != null) {
        if (kDebugMode) debugPrint("Chat already exists: ${existingChat['id']}");
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

      if (kDebugMode) debugPrint("Created new chat: ${newChat['id']}");
      return newChat['id'].toString();
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting or creating chat: $e");
      rethrow;
    }
  }

  /// Get all chats for a user (either as renter or landlord)
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      if (kDebugMode) debugPrint("Getting chats for user: $userId");

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

      if (kDebugMode) debugPrint("Fetched ${chats.length} chats");
      return List<Map<String, dynamic>>.from(chats);
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting user chats: $e");
      return [];
    }
  }

  /// Get messages for a specific chat
  Stream<List<Message>> getChatMessages(String chatId) {
    if (kDebugMode) debugPrint("Setting up message stream for chat: $chatId");

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('timestamp', ascending: true)
        .map((data) {
          if (kDebugMode) debugPrint("Received ${data.length} messages");
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
      if (kDebugMode) debugPrint("Sending message to chat: $chatId");

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

      if (kDebugMode) debugPrint("Message sent successfully");
    } catch (e) {
      if (kDebugMode) debugPrint("Error sending message: $e");
      rethrow;
    }
  }
}
