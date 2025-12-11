import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/screens/shared/chat_room_screen.dart';
import 'package:odiorent/screens/renter/create_booking_screen.dart';
import 'package:odiorent/widgets/video_player_widget.dart';

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
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _fetchPropertyDetails();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final user = _authService.getCurrentUser();
    if (user != null && _property.id != null) {
      final isBookmarked = await _dbService.isPropertyBookmarked(
        userId: user.uid,
        propertyId: _property.id!,
      );
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    final user = _authService.getCurrentUser();
    if (user == null || _property.id == null) return;

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      if (_isBookmarked) {
        await _dbService.removeBookmark(
          userId: user.uid,
          propertyId: _property.id!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from bookmarks'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _dbService.addBookmark(
          userId: user.uid,
          propertyId: _property.id!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to bookmarks'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isBookmarkLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBookNow() async {
    // Check if property status is approved
    if (_property.status != PropertyStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This property is not available for booking at this time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to booking screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBookingScreen(property: _property),
      ),
    );

    // If booking was successful, show confirmation
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent! The landlord will review your request.'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
        actions: [
          _isBookmarkLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  onPressed: _toggleBookmark,
                  tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                ),
        ],
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

                  // --- Virtual Tour ---
                  if (property.videoUrls.isNotEmpty) ...[
                    const Text(
                      'Virtual Tour',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(thickness: 0.5, height: 20),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: property.videoUrls.length,
                        itemBuilder: (context, index) {
                          final videoUrl = property.videoUrls[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < property.videoUrls.length - 1 ? 12 : 0,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 32,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: VideoPlayerWidget(
                                videoUrl: videoUrl,
                                propertyId: property.id!,
                                showLikeButton: true,
                                autoPlay: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- Ratings & Reviews ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ratings & Reviews',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _showAddRatingDialog,
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Add Review'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const Divider(thickness: 0.5, height: 20),
                  _buildRatingsSection(),
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

  Widget _buildRatingsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbService.getPropertyRatings(_property.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text('Error loading reviews: ${snapshot.error}');
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'No reviews yet. Be the first to review!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: ratings.map((rating) {
            final userName = rating['userName'] ?? 'Anonymous';
            final ratingValue = rating['rating'] as int;
            final comment = rating['comment'] as String?;
            final createdAt = rating['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: lightGreen.withAlpha(51),
                          child: Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < ratingValue
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            _formatDate(createdAt.toDate()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    if (comment != null && comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        comment,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddRatingDialog() async {
    final user = _authService.getCurrentUser();
    if (user == null || _property.id == null) return;

    // Check if user already has a rating
    final existingRating = await _dbService.getUserRatingForProperty(
      propertyId: _property.id!,
      userId: user.uid,
    );

    int selectedRating = existingRating?['rating'] ?? 0;
    final commentController = TextEditingController(
      text: existingRating?['comment'] ?? '',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingRating != null ? 'Update Review' : 'Add Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rating (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comment (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: primaryGreen, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                      // Capture context before async gap
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      
                      try {
                        await _dbService.addPropertyRating(
                          propertyId: _property.id!,
                          userId: user.uid,
                          rating: selectedRating,
                          comment: commentController.text.trim().isEmpty
                              ? null
                              : commentController.text.trim(),
                        );

                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Review submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refresh the screen to show updated ratings
                          setState(() {
                            _fetchPropertyDetails();
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
