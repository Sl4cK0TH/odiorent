import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odiorent/models/booking.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/screens/renter/booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();

  String _selectedFilter = 'all'; // all, pending, approved, active, completed, cancelled

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view bookings')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.streamBookingsByRenter(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bookings = snapshot.data ?? [];

                // Filter bookings
                final filteredBookings = _selectedFilter == 'all'
                    ? bookings
                    : bookings.where((b) => b['status'] == _selectedFilter).toList();

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
                              ? 'No bookings yet'
                              : 'No $_selectedFilter bookings',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final bookingData = filteredBookings[index];
                    return _buildBookingCard(bookingData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> bookingData) {
    final status = bookingStatusFromString(bookingData['status'] as String);
    final statusColor = Booking.getStatusColor(status);
    final statusText = Booking.getStatusText(status);

    final propertyName = bookingData['propertyName'] as String? ?? 'Property';
    final propertyAddress = bookingData['propertyAddress'] as String? ?? '';
    final propertyImageUrl = bookingData['propertyImageUrl'] as String?;
    final monthlyRent = (bookingData['monthlyRent'] as num?)?.toDouble() ?? 0.0;
    final moveInDate = bookingData['moveInDate']?.toDate() as DateTime?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(
                bookingId: bookingData['id'] as String,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              if (propertyImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    propertyImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.home, size: 40),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home, size: 40),
                ),
              const SizedBox(width: 12),

              // Booking Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (propertyAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        propertyAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          moveInDate != null
                              ? DateFormat('MMM dd, yyyy').format(moveInDate)
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${NumberFormat('#,##0.00').format(monthlyRent)}/month',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
