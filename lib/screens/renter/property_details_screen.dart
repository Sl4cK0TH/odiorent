import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/widgets/custom_button.dart';
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

  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  /// --- Day 6: Message Landlord ---
  /// This function will handle the logic for starting a chat.
  void _handleMessageLandlord() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get current renter's ID
      final renterId = _authService.getCurrentUser()?.id;
      if (renterId == null) {
        // Handle user not found
        setState(() => _isLoading = false);
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
      final landlordId = widget.property.landlordId;

      // 3. Call the database service function to get or create chat
      final chatId = await _dbService.getOrCreateChat(
        renterId: renterId,
        landlordId: landlordId,
        propertyId: widget.property.id!,
      );

      setState(() => _isLoading = false);

      // 4. Navigate to the chat room
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatId: chatId,
              propertyName: widget.property.name,
              otherUserEmail: 'Landlord',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.name),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
      ),
      // --- Sticky Bottom Button ---
      // We use bottomNavigationBar to make the button
      // "stick" to the bottom, even when the content scrolls.
      bottomNavigationBar: Container(
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
        child: _isLoading
            ? const Center(
                heightFactor: 1.0, // Keep the container size
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
              )
            : CustomButton(
                text: "Message Landlord",
                onPressed: _handleMessageLandlord,
                backgroundColor: primaryGreen,
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
                itemCount: widget.property.imageUrls.length,
                itemBuilder: (context, index) {
                  // Use a ternary to handle empty image lists
                  return widget.property.imageUrls.isNotEmpty
                      ? Image.network(
                          widget.property.imageUrls[index],
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
                    '₱${widget.property.price.toStringAsFixed(2)} / month',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Name ---
                  Text(
                    widget.property.name,
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
                          widget.property.address,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Room/Bed Stats ---
                  // We re-use the same chip style from the Admin screen
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.bed_outlined,
                        '${widget.property.beds} Beds',
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.meeting_room_outlined,
                        '${widget.property.rooms} Rooms',
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
                    widget.property.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
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
}
