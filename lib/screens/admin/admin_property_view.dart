import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/widgets/video_player_widget.dart';

class AdminPropertyViewScreen extends StatefulWidget {
  final Property property;
  const AdminPropertyViewScreen({super.key, required this.property});

  @override
  State<AdminPropertyViewScreen> createState() =>
      _AdminPropertyViewScreenState();
}

class _AdminPropertyViewScreenState extends State<AdminPropertyViewScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF388E3C);

  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  bool _isLoading = false;

  Future<void> _handleUpdateStatus(PropertyStatus newStatus) async {
    setState(() => _isLoading = true);

    try {
      await _dbService.updatePropertyStatus(
        propertyId: widget.property.id!,
        status: newStatus,
        landlordId: widget.property.landlordId,
        propertyName: widget.property.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property has been ${statusToString(newStatus)}.'),
          backgroundColor: newStatus == PropertyStatus.approved ? primaryGreen : Colors.red,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: widget.property.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.property.imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 50),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${widget.property.price.toStringAsFixed(2)} / month',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
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
                  Row(
                    children: [
                      _buildStatChip(Icons.bed, '${widget.property.beds} Beds'),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.meeting_room,
                        '${widget.property.rooms} Rooms',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Text(
                    widget.property.description,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // --- Virtual Tour ---
                  if (widget.property.videoUrls.isNotEmpty) ...[
                    const Text(
                      'Virtual Tour',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.property.videoUrls.length,
                        itemBuilder: (context, index) {
                          final videoUrl = widget.property.videoUrls[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < widget.property.videoUrls.length - 1 ? 12 : 0,
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
                                propertyId: widget.property.id!,
                                showLikeButton: false, // Admin doesn't need like button
                                autoPlay: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _handleUpdateStatus(PropertyStatus.rejected),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _handleUpdateStatus(PropertyStatus.approved),
                          ),
                        ),
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