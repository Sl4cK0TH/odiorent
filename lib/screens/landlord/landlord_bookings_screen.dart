import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odiorent/models/booking.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/screens/landlord/landlord_booking_details_screen.dart';

class LandlordBookingsScreen extends StatefulWidget {
  const LandlordBookingsScreen({super.key});

  @override
  State<LandlordBookingsScreen> createState() => _LandlordBookingsScreenState();
}

class _LandlordBookingsScreenState extends State<LandlordBookingsScreen> {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();

  String _selectedFilter = 'pending'; // pending, approved, active, all, completed, rejected, cancelled

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
        title: const Text('Booking Requests'),
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
                _buildFilterChip('Pending', 'pending', showBadge: true),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', 'cancelled'),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all'),
              ],
            ),
          ),

          // Pending Count Banner
          if (_selectedFilter == 'pending')
            StreamBuilder<int>(
              stream: _dbService.streamPendingBookingsCount(currentUser.uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(
                        '$count pending booking${count == 1 ? '' : 's'} awaiting your response',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),

          // Bookings List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.streamBookingsByLandlord(currentUser.uid),
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
                          _selectedFilter == 'pending'
                              ? Icons.pending_actions
                              : Icons.bookmark_border,
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

  Widget _buildFilterChip(String label, String value, {bool showBadge = false}) {
    final isSelected = _selectedFilter == value;
    
    Widget chipChild = Text(label);
    
    if (showBadge && value == 'pending') {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        return StreamBuilder<int>(
          stream: _dbService.streamPendingBookingsCount(currentUser.uid),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
          },
        );
      }
    }

    return FilterChip(
      label: chipChild,
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFFFF6B6B),
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
    final renterName = bookingData['renterName'] as String? ?? 'Renter';
    final monthlyRent = (bookingData['monthlyRent'] as num?)?.toDouble() ?? 0.0;
    final moveInDate = bookingData['moveInDate']?.toDate() as DateTime?;
    final durationMonths = bookingData['durationMonths'] as int? ?? 0;

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
              builder: (context) => LandlordBookingDetailsScreen(
                bookingId: bookingData['id'] as String,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                renterName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              moveInDate != null
                                  ? '${DateFormat('MMM dd, yyyy').format(moveInDate)} ($durationMonths mo.)'
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Status Badge
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.approved:
        return Icons.check_circle;
      case BookingStatus.active:
        return Icons.home;
      case BookingStatus.completed:
        return Icons.check_circle_outline;
      case BookingStatus.rejected:
        return Icons.cancel;
      case BookingStatus.cancelled:
        return Icons.block;
    }
  }
}
