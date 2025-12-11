import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BookingStatus {
  pending,    // Waiting for landlord approval
  approved,   // Landlord approved
  rejected,   // Landlord rejected
  active,     // Currently ongoing
  completed,  // Booking period ended
  cancelled,  // Cancelled by renter or landlord
}

// Helper function to convert string to BookingStatus enum
BookingStatus bookingStatusFromString(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return BookingStatus.approved;
    case 'rejected':
      return BookingStatus.rejected;
    case 'active':
      return BookingStatus.active;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    case 'pending':
    default:
      return BookingStatus.pending;
  }
}

// Helper function to convert BookingStatus enum to string
String bookingStatusToString(BookingStatus status) {
  return status.toString().split('.').last;
}

class Booking {
  final String? id;
  final String propertyId;
  final String renterId;
  final String landlordId;
  
  // Property details (denormalized for easy access)
  final String? propertyName;
  final String? propertyAddress;
  final double? propertyPrice;
  final String? propertyImageUrl;
  
  // Renter details (denormalized)
  final String? renterName;
  final String? renterEmail;
  final String? renterPhone;
  
  // Booking details
  final DateTime moveInDate;
  final int durationMonths; // Duration in months
  final DateTime moveOutDate; // Calculated: moveInDate + durationMonths
  final int numberOfOccupants;
  final String? specialRequests;
  
  // Financial details
  final double monthlyRent;
  final double securityDeposit; // Usually 1-2 months rent
  final double totalAmount; // monthlyRent * durationMonths + securityDeposit
  
  // Status and timestamps
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? rejectionReason;

  Booking({
    this.id,
    required this.propertyId,
    required this.renterId,
    required this.landlordId,
    this.propertyName,
    this.propertyAddress,
    this.propertyPrice,
    this.propertyImageUrl,
    this.renterName,
    this.renterEmail,
    this.renterPhone,
    required this.moveInDate,
    required this.durationMonths,
    required this.moveOutDate,
    required this.numberOfOccupants,
    this.specialRequests,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.rejectionReason,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'renterId': renterId,
      'landlordId': landlordId,
      'propertyName': propertyName,
      'propertyAddress': propertyAddress,
      'propertyPrice': propertyPrice,
      'propertyImageUrl': propertyImageUrl,
      'renterName': renterName,
      'renterEmail': renterEmail,
      'renterPhone': renterPhone,
      'moveInDate': Timestamp.fromDate(moveInDate),
      'durationMonths': durationMonths,
      'moveOutDate': Timestamp.fromDate(moveOutDate),
      'numberOfOccupants': numberOfOccupants,
      'specialRequests': specialRequests,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'totalAmount': totalAmount,
      'status': bookingStatusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'rejectionReason': rejectionReason,
    };
  }

  /// Create from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      propertyId: data['propertyId'] as String,
      renterId: data['renterId'] as String,
      landlordId: data['landlordId'] as String,
      propertyName: data['propertyName'] as String?,
      propertyAddress: data['propertyAddress'] as String?,
      propertyPrice: (data['propertyPrice'] as num?)?.toDouble(),
      propertyImageUrl: data['propertyImageUrl'] as String?,
      renterName: data['renterName'] as String?,
      renterEmail: data['renterEmail'] as String?,
      renterPhone: data['renterPhone'] as String?,
      moveInDate: (data['moveInDate'] as Timestamp).toDate(),
      durationMonths: data['durationMonths'] as int,
      moveOutDate: (data['moveOutDate'] as Timestamp).toDate(),
      numberOfOccupants: data['numberOfOccupants'] as int,
      specialRequests: data['specialRequests'] as String?,
      monthlyRent: (data['monthlyRent'] as num).toDouble(),
      securityDeposit: (data['securityDeposit'] as num).toDouble(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      status: bookingStatusFromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null 
          ? (data['approvedAt'] as Timestamp).toDate() 
          : null,
      rejectedAt: data['rejectedAt'] != null 
          ? (data['rejectedAt'] as Timestamp).toDate() 
          : null,
      cancelledAt: data['cancelledAt'] != null 
          ? (data['cancelledAt'] as Timestamp).toDate() 
          : null,
      cancellationReason: data['cancellationReason'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  /// Create a copy with updated fields
  Booking copyWith({
    String? id,
    String? propertyId,
    String? renterId,
    String? landlordId,
    String? propertyName,
    String? propertyAddress,
    double? propertyPrice,
    String? propertyImageUrl,
    String? renterName,
    String? renterEmail,
    String? renterPhone,
    DateTime? moveInDate,
    int? durationMonths,
    DateTime? moveOutDate,
    int? numberOfOccupants,
    String? specialRequests,
    double? monthlyRent,
    double? securityDeposit,
    double? totalAmount,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? rejectionReason,
  }) {
    return Booking(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      renterId: renterId ?? this.renterId,
      landlordId: landlordId ?? this.landlordId,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      propertyImageUrl: propertyImageUrl ?? this.propertyImageUrl,
      renterName: renterName ?? this.renterName,
      renterEmail: renterEmail ?? this.renterEmail,
      renterPhone: renterPhone ?? this.renterPhone,
      moveInDate: moveInDate ?? this.moveInDate,
      durationMonths: durationMonths ?? this.durationMonths,
      moveOutDate: moveOutDate ?? this.moveOutDate,
      numberOfOccupants: numberOfOccupants ?? this.numberOfOccupants,
      specialRequests: specialRequests ?? this.specialRequests,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Get status color for UI
  static Color getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case BookingStatus.approved:
        return const Color(0xFF66BB6A); // Green
      case BookingStatus.active:
        return const Color(0xFF42A5F5); // Blue
      case BookingStatus.completed:
        return const Color(0xFF9E9E9E); // Grey
      case BookingStatus.rejected:
        return const Color(0xFFEF5350); // Red
      case BookingStatus.cancelled:
        return const Color(0xFFFF7043); // Deep Orange
    }
  }

  /// Get display text for status
  static String getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Approval';
      case BookingStatus.approved:
        return 'Approved';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return status == BookingStatus.pending || 
           status == BookingStatus.approved;
  }

  /// Check if booking is currently active
  bool get isActive {
    return status == BookingStatus.active;
  }

  /// Check if move-in date has passed
  bool get hasMoveInDatePassed {
    return DateTime.now().isAfter(moveInDate);
  }

  /// Check if move-out date has passed
  bool get hasMoveOutDatePassed {
    return DateTime.now().isAfter(moveOutDate);
  }
}
