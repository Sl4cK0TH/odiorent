import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odiorent/models/booking.dart';
import 'package:odiorent/services/firebase_database_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _dbService = FirebaseDatabaseService();
  bool _isCancelling = false;

  Future<void> _showCancelDialog(Map<String, dynamic> bookingData) async {
    final status = bookingStatusFromString(bookingData['status'] as String);
    
    if (status != BookingStatus.pending && status != BookingStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This booking cannot be cancelled'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this booking?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Please provide a reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelBooking(reasonController.text.trim());
    }

    reasonController.dispose();
  }

  Future<void> _cancelBooking(String reason) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a cancellation reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      await _dbService.cancelBooking(widget.bookingId, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _dbService.getBookingById(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookingData = snapshot.data;
          if (bookingData == null) {
            return const Center(child: Text('Booking not found'));
          }

          final status = bookingStatusFromString(bookingData['status'] as String);
          final statusColor = Booking.getStatusColor(status);
          final statusText = Booking.getStatusText(status);
          final canCancel = status == BookingStatus.pending || status == BookingStatus.approved;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 48,
                        color: statusColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Property Information
                _buildSection(
                  'Property Information',
                  [
                    if (bookingData['propertyImageUrl'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            bookingData['propertyImageUrl'] as String,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    _buildInfoRow('Name', bookingData['propertyName'] ?? 'N/A'),
                    _buildInfoRow('Address', bookingData['propertyAddress'] ?? 'N/A'),
                    _buildInfoRow(
                      'Monthly Rent',
                      '₱${NumberFormat('#,##0.00').format((bookingData['monthlyRent'] as num?)?.toDouble() ?? 0)}',
                    ),
                  ],
                ),

                // Booking Information
                _buildSection(
                  'Booking Information',
                  [
                    _buildInfoRow(
                      'Move-in Date',
                      bookingData['moveInDate'] != null
                          ? DateFormat('MMMM dd, yyyy').format(bookingData['moveInDate'].toDate())
                          : 'N/A',
                    ),
                    _buildInfoRow(
                      'Move-out Date',
                      bookingData['moveOutDate'] != null
                          ? DateFormat('MMMM dd, yyyy').format(bookingData['moveOutDate'].toDate())
                          : 'N/A',
                    ),
                    _buildInfoRow(
                      'Duration',
                      '${bookingData['durationMonths']} months',
                    ),
                    _buildInfoRow(
                      'Number of Occupants',
                      '${bookingData['numberOfOccupants']} ${(bookingData['numberOfOccupants'] as int) == 1 ? 'person' : 'people'}',
                    ),
                    if (bookingData['specialRequests'] != null &&
                        (bookingData['specialRequests'] as String).isNotEmpty)
                      _buildInfoRow(
                        'Special Requests',
                        bookingData['specialRequests'] as String,
                      ),
                  ],
                ),

                // Financial Summary
                _buildSection(
                  'Financial Summary',
                  [
                    _buildInfoRow(
                      'Monthly Rent',
                      '₱${NumberFormat('#,##0.00').format((bookingData['monthlyRent'] as num?)?.toDouble() ?? 0)}',
                    ),
                    _buildInfoRow(
                      'Duration',
                      '${bookingData['durationMonths']} months',
                    ),
                    _buildInfoRow(
                      'Security Deposit',
                      '₱${NumberFormat('#,##0.00').format((bookingData['securityDeposit'] as num?)?.toDouble() ?? 0)}',
                    ),
                    const Divider(thickness: 2),
                    _buildInfoRow(
                      'Total Amount',
                      '₱${NumberFormat('#,##0.00').format((bookingData['totalAmount'] as num?)?.toDouble() ?? 0)}',
                      isTotal: true,
                    ),
                  ],
                ),

                // Timestamps
                _buildSection(
                  'Timeline',
                  [
                    _buildInfoRow(
                      'Requested On',
                      bookingData['createdAt'] != null
                          ? DateFormat('MMMM dd, yyyy - hh:mm a').format(bookingData['createdAt'].toDate())
                          : 'N/A',
                    ),
                    if (bookingData['approvedAt'] != null)
                      _buildInfoRow(
                        'Approved On',
                        DateFormat('MMMM dd, yyyy - hh:mm a').format(bookingData['approvedAt'].toDate()),
                      ),
                    if (bookingData['rejectedAt'] != null)
                      _buildInfoRow(
                        'Rejected On',
                        DateFormat('MMMM dd, yyyy - hh:mm a').format(bookingData['rejectedAt'].toDate()),
                      ),
                    if (bookingData['cancelledAt'] != null)
                      _buildInfoRow(
                        'Cancelled On',
                        DateFormat('MMMM dd, yyyy - hh:mm a').format(bookingData['cancelledAt'].toDate()),
                      ),
                  ],
                ),

                // Rejection/Cancellation Reason
                if (bookingData['rejectionReason'] != null)
                  _buildSection(
                    'Rejection Reason',
                    [
                      Text(
                        bookingData['rejectionReason'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                if (bookingData['cancellationReason'] != null)
                  _buildSection(
                    'Cancellation Reason',
                    [
                      Text(
                        bookingData['cancellationReason'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Cancel Button
                if (canCancel)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isCancelling ? null : () => _showCancelDialog(bookingData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Cancel Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFFFF6B6B) : Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
