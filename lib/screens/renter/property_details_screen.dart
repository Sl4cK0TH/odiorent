import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/screens/shared/chat_room_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  // --- Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF388E3C);

  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  late Property _property;
  bool _isMessageLoading = false;
  bool _isFetchingDetails = false;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _fetchPropertyDetails();
  }

  void _handleBookNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking flow coming soon!'),
      ),
    );
  }

  /// --- Day 6: Message Landlord ---
  /// This function will handle the logic for starting a chat.
  void _handleMessageLandlord() async {
    setState(() => _isMessageLoading = true);

    try {
      // 1. Get current renter's ID
      final renterId = _authService.getCurrentUser()?.uid;
      if (renterId == null) {
        // Handle user not found
        setState(() => _isMessageLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2. Get the landlord's ID from the property
      final landlordId = _property.landlordId;

      // 3. Call the database service function to get or create chat
      final chatResult = await _dbService.getOrCreateChat(
        renterId: renterId,
        landlordId: landlordId,
        propertyId: _property.id!,
      );

      final chatId = chatResult['chatId'] as String;
      final isNewChat = chatResult['isNewChat'] as bool;

      setState(() => _isMessageLoading = false);

      // 4. Navigate to the chat room
      if (mounted) {
        // Prepare initial message for new chats
        final initialMessage = isNewChat
            ? 'Hi! I\'m interested in "${_property.name}" at ${_property.address}. Is it still available?'
            : null;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatId: chatId,
              propertyName: _property.name,
              otherUserName: _formatFullName(_property),
              otherUserId: landlordId,
              otherUserProfileUrl: _property.landlordProfilePictureUrl,
              initialMessage: initialMessage,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isMessageLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchPropertyDetails() async {
    final propertyId = widget.property.id;
    if (propertyId == null) {
      return;
    }
    setState(() => _isFetchingDetails = true);
    try {
      final response = await _dbService.getPropertyWithLandlordDetails(propertyId);
      final detailedProperty = Property.fromMap(response);
      if (!mounted) return;
      setState(() {
        _property = detailedProperty;
        _isFetchingDetails = false;
      });
    } catch (e) {
      debugPrint('Error fetching property details: $e');
      if (mounted) {
        setState(() => _isFetchingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = _property;
    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
      ),
      // --- Sticky Bottom Button ---
      // We use bottomNavigationBar to make the button
      // "stick" to the bottom, even when the content scrolls.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
        child: _isMessageLoading
            ? const Center(
                heightFactor: 1.0,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('Message Landlord'),
                      onPressed: _handleMessageLandlord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Book Now'),
                      onPressed: _handleBookNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: primaryGreen),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Carousel ---
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: property.imageUrls.length,
                itemBuilder: (context, index) {
                  // Use a ternary to handle empty image lists
                  return property.imageUrls.isNotEmpty
                      ? Image.network(
                          property.imageUrls[index],
                          fit: BoxFit.cover,
                          // Show a loading spinner while the image loads
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                              ),
                            );
                          },
                          // Show a broken image icon if the image fails to load
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                },
              ),
            ),

            // --- Details Section ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Price ---
                  Text(
                    // Format price to 2 decimal places
                    '₱${property.price.toStringAsFixed(2)} / month',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Name ---
                  Text(
                    property.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Address ---
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Room/Bed/Shower Stats ---
                  // We re-use the same chip style from the Admin screen
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.meeting_room_outlined,
                        '${property.rooms} Rooms',
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.bed_outlined,
                        '${property.beds} Beds',
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.shower_outlined,
                        '${property.showers} Showers',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Description ---
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(thickness: 0.5, height: 20),
                  Text(
                    property.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Landlord Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(thickness: 0.5, height: 20),
                  _buildInfoRow(
                    'Full Name',
                    _formatFullName(property),
                  ),
                  _buildInfoRow(
                    'Email',
                    property.landlordEmail ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Contact Number',
                    property.landlordPhoneNumber ?? 'N/A',
                  ),
                  if (_isFetchingDetails)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: LinearProgressIndicator(),
                    ),
                  // TODO: Add landlord profile picture later
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the stat chips (beds, rooms)
  Widget _buildStatChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18, color: darkGreen),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: primaryGreen.withAlpha(26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryGreen.withAlpha(77)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullName(Property property) {
    final parts = <String>[];
    final firstName = property.landlordFirstName?.trim();
    final lastName = property.landlordLastName?.trim();
    if (firstName != null && firstName.isNotEmpty) {
      parts.add(firstName);
    }
    if (lastName != null && lastName.isNotEmpty) {
      parts.add(lastName);
    }
    if (parts.isEmpty) {
      return 'N/A';
    }
    return parts.join(' ');
  }
}
