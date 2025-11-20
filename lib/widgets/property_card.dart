import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  const PropertyCard({super.key, required this.property});

  // Helper to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Property Image ---
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(15.0),
            ),
            child: Image.network(
              // Use the first image as the thumbnail
              // Add a placeholder if no images exist
              property.imageUrls.isNotEmpty
                  ? property.imageUrls.first
                  : 'https://placehold.co/600x400/grey/white?text=No+Image',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              // Show a loading indicator while the image loads
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              // Show a placeholder icon if the image fails to load
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),

          // --- Property Details ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Property Name ---
                Text(
                  property.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // --- Price ---
                Text(
                  // Format the price
                  '₱${property.price.toStringAsFixed(2)} / month',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50), // Your primaryGreen
                  ),
                ),
                const SizedBox(height: 8),

                // --- Address ---
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        property.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${property.ratingCount} ratings)",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // --- Status Badge ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(property.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    // Capitalize the first letter
                    property.status[0].toUpperCase() +
                        property.status.substring(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
