import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:fluttertoast/fluttertoast.dart'; // Import for Fluttertoast
import 'package:odiorent/models/property.dart';
import 'package:odiorent/screens/landlord/landlord_edit_property_screen.dart'; // For navigation
import 'package:odiorent/services/firebase_database_service.dart'; // Import for FirebaseDatabaseService
import 'package:odiorent/widgets/video_player_widget.dart';

class LandlordPropertyDetailsScreen extends StatelessWidget {
  final Property property;

  const LandlordPropertyDetailsScreen({super.key, required this.property});

  // --- Define Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final bool? result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => LandlordEditPropertyScreen(property: property),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Property'),
                  content: const Text('Are you sure you want to permanently delete this property? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                try {
                  await FirebaseDatabaseService().deleteProperty(property.id!);
                  if (context.mounted) {
                    Fluttertoast.showToast(
                      msg: "Property deleted successfully!",
                      backgroundColor: Colors.green,
                    );
                    Navigator.of(context).pop(true); // Pop details screen, signal refresh
                  }
                } catch (e) {
                  if (context.mounted) {
                    Fluttertoast.showToast(
                      msg: "Error deleting property: $e",
                      backgroundColor: Colors.red,
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Property Image Carousel (Placeholder for now) ---
            SizedBox(
              height: 250,
              width: double.infinity,
              child: property.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: property.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          property.imageUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Property Name ---
                  Text(
                    property.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Price ---
                  Text(
                    NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(property.price),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Address ---
                  Text(
                    property.address,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // --- Description ---
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // --- Virtual Tour ---
                  if (property.videoUrls.isNotEmpty) ...[
                    const Text(
                      'Virtual Tour',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
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
                                showLikeButton: false, // Landlord doesn't need like button
                                autoPlay: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                  ],

                  // --- Property Specs ---
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSpecIcon(Icons.meeting_room_outlined, '${property.rooms} Rooms'),
                      _buildSpecIcon(Icons.bed_outlined, '${property.beds} Beds'),
                      _buildSpecIcon(Icons.shower_outlined, '${property.showers} Showers'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for property specs
  Widget _buildSpecIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.grey[800]),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
