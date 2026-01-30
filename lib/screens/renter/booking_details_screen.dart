import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploadingPayment = false;
  bool _isNotifying = false;
  


  Future<void> _pickAndUploadPayment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                if (pickedFile.path.isNotEmpty)
                  Image.file(File(pickedFile.path), height: 200, fit: BoxFit.cover),
                const SizedBox(height: 16),
                const Text('Upload this image as proof of payment?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() {
            _isUploadingPayment = true;
        });
        
        try {
            await _dbService.uploadProofOfPayment(
                bookingId: widget.bookingId,
                file: pickedFile,
            );
            
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment uploaded successfully!')),
                );
                setState(() {}); // Refresh
            }
        } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error uploading payment: $e'), backgroundColor: Colors.red),
              );
            }
        } finally {
            if (mounted) setState(() => _isUploadingPayment = false);
        }
      }
    }
  }

  Future<void> _notifyLandlord() async {
      setState(() => _isNotifying = true);
      try {
          await _dbService.submitPaymentProof(widget.bookingId);
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Landlord notified successfully!')),
              );
              setState(() {}); // Refresh UI
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error notifying landlord: $e'), backgroundColor: Colors.red),
              );
          }
      } finally {
          if (mounted) setState(() => _isNotifying = false);
      }
  }

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
        backgroundColor: const Color(0xFF4CAF50),
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
                      if (bookingData['landlordMessage'] != null && (status == BookingStatus.active || status == BookingStatus.approved)) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Message: ${bookingData['landlordMessage']}",
                             style: const TextStyle(fontStyle: FontStyle.italic),
                             textAlign: TextAlign.center,
                          ),
                      ],
                    ],
                  ),
                ),
                
                // 24-Hour Countdown Timer
                if (status == BookingStatus.approved && 
                    bookingData['paymentStatus'] != 'pending_verification' && 
                    bookingData['paymentStatus'] != 'verified') ...[
                    const SizedBox(height: 24),
                    if (bookingData['approvedAt'] != null)
                      CountdownWidget(
                        deadline: (bookingData['approvedAt'] as Timestamp)
                            .toDate()
                            .add(const Duration(hours: 24)),
                      ),
                ],

                // Verified / Rejected Banners
                if (bookingData['paymentStatus'] == 'verified') ...[
                    const SizedBox(height: 24),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                            children: [
                                Icon(Icons.verified, color: Colors.white, size: 40),
                                SizedBox(height: 8),
                                Text(
                                    "BOOKING VERIFIED",
                                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                            ],
                        ),
                    ),
                ],
                
                if (bookingData['status'] == 'rejected') ...[ // Using string check or enum? enum is better but raw data is map.
                     // The status Banner already handles "Rejected" visually.
                     // But user asked for "below it is the reason why...".
                     // Existing code already has "Rejection Reason" section at bottom.
                     // User said: "Booking Rejected then below it is the reason".
                     // Let's ensure THAT section is prominent.
                ],

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
                    if (bookingData['roomName'] != null)
                      _buildInfoRow('Room / Unit', bookingData['roomName']),
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
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                            'Note: A 50% downpayment is required to secure this booking.',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
                        ),
                    ),
                    _buildInfoRow(
                      'Payment Method',
                      'Over the Counter',
                    ),
                    const Divider(thickness: 2),
                    _buildInfoRow(
                      'Total Amount',
                      '₱${NumberFormat('#,##0.00').format((bookingData['totalAmount'] as num?)?.toDouble() ?? 0)}',
                      isTotal: true,
                    ),
                  ],
                ),

                // Payment Information
                _buildPaymentSection(bookingData),

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
                color: isTotal ? const Color(0xFF4CAF50) : Colors.black,
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

  Widget _buildPaymentSection(Map<String, dynamic> bookingData) {
      final status = bookingData['status'] as String;
      final paymentStatus = bookingData['paymentStatus'] as String?;
      final proofUrl = bookingData['proofOfPaymentUrl'] as String?;
      
      // Only show if approved or active or if payment exists
      if (status != 'approved' && status != 'active' && proofUrl == null) {
          return const SizedBox.shrink();
      }
      
      final bool canEdit = paymentStatus != 'pending_verification' && paymentStatus != 'verified' && paymentStatus != 'rejected';
      final bool isSubmitted = paymentStatus == 'pending_verification';

      return _buildSection(
          'Payment Information',
          [
              // Landlord GCash Number
              if (bookingData['landlordGcashNumber'] != null) ...[
                  _buildInfoRow('Landlord GCash No', bookingData['landlordGcashNumber'] as String),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
              ],
              
              if (proofUrl != null) ...[
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('Proof of Payment:', style: TextStyle(fontWeight: FontWeight.bold)),
                     if (canEdit)
                        TextButton.icon(
                            onPressed: _pickAndUploadPayment, 
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text("Change"),
                        ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 InkWell(
                     onTap: canEdit ? _pickAndUploadPayment : null,
                     child: ClipRRect(
                         borderRadius: BorderRadius.circular(8),
                         child: Stack(
                           alignment: Alignment.center,
                           children: [
                             Image.network(proofUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                             if (canEdit)
                               Container(
                                 color: Colors.black38,
                                 padding: const EdgeInsets.all(8),
                                 child: const Icon(Icons.camera_alt, color: Colors.white),
                               ),
                           ],
                         ),
                     ),
                 ),
                 const SizedBox(height: 12),
              ],
              
              if (paymentStatus != null)
                 _buildInfoRow('Payment Status', 
                     paymentStatus == 'pending_verification' ? 'UNDER REVIEW' : paymentStatus.toUpperCase()
                 ),
                 
              if (status == 'approved') ...[
                 const SizedBox(height: 16),
                 
                 // Upload Button (only if no proof yet)
                 if (proofUrl == null)
                     SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: Text(_isUploadingPayment ? 'Uploading...' : 'Upload Proof of Payment'),
                            onPressed: _isUploadingPayment ? null : _pickAndUploadPayment,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                            ),
                        ),
                     ),
                     
                  // Notify Landlord Button (only if proof exists and not submitted)
                  if (proofUrl != null && !isSubmitted && paymentStatus != 'verified')
                     SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.notifications_active),
                            label: Text(_isNotifying ? 'Notifying...' : 'Notify Landlord'),
                            onPressed: _isNotifying ? null : _notifyLandlord,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                            ),
                        ),
                     ),
                     
                   if (isSubmitted)
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                          ),
                          child: const Column(
                              children: [
                                  Icon(Icons.hourglass_top, color: Colors.blue),
                                  SizedBox(height: 4),
                                  Text("Payment submitted. Waiting for landlord verification.", 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                                  ),
                              ],
                          ),
                      ),
              ],
          ],
      );
  }
}

class CountdownWidget extends StatefulWidget {
  final DateTime deadline;
  const CountdownWidget({super.key, required this.deadline});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
       _calculateRemaining();
    });
  }

  void _calculateRemaining() {
      final now = DateTime.now();
      final diff = widget.deadline.difference(now);
      if (mounted) {
          setState(() {
              _remaining = diff;
          });
      }
      if (diff.isNegative) {
          _timer.cancel();
      }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      if (_remaining.isNegative) {
          return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
              ),
              child: const Text(
                  "Deadline Exceeded - Booking will be cancelled shortly.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
              ),
          );
      }

      final hours = _remaining.inHours;
      final minutes = _remaining.inMinutes % 60;
      final seconds = _remaining.inSeconds % 60;

      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Column(
              children: [
                  const Text(
                      "Time remaining to pay deposit:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontFamily: 'Courier',
                      ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                      "Booking will constitute as cancelled if deposit is not paid within 24 hours.",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                  ),
              ],
          ),
      );
  }
}
