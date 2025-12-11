import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final Property property;

  const CreateBookingScreen({super.key, required this.property});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    _initializeRenterName();
  }

  Future<void> _initializeRenterName() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _renterNameController.text = currentUser.displayName ?? 'Renter';
    }
  }

  DateTime? _selectedMoveInDate;
  int _durationMonths = 12; // Default 1 year
  final _numberOfOccupantsController = TextEditingController(text: '1');
  final _renterNameController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingAvailability = false;

  // Financial calculations
  double get _monthlyRent => widget.property.price;
  double get _securityDeposit => _monthlyRent * 2; // 2 months security deposit
  double get _totalAmount => (_monthlyRent * _durationMonths) + _securityDeposit;

  @override
  void dispose() {
    _numberOfOccupantsController.dispose();
    _renterNameController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectMoveInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMoveInDate = picked;
      });
      await _checkAvailability();
    }
  }

  Future<void> _checkAvailability() async {
    if (_selectedMoveInDate == null) return;

    setState(() {
      _isCheckingAvailability = true;
    });

    final moveOutDate = DateTime(
      _selectedMoveInDate!.year,
      _selectedMoveInDate!.month + _durationMonths,
      _selectedMoveInDate!.day,
    );

    final isAvailable = await _dbService.isPropertyAvailable(
      propertyId: widget.property.id!,
      moveInDate: _selectedMoveInDate!,
      moveOutDate: moveOutDate,
    );

    setState(() {
      _isCheckingAvailability = false;
    });

    if (!isAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property is not available for the selected dates'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMoveInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a move-in date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final moveOutDate = DateTime(
        _selectedMoveInDate!.year,
        _selectedMoveInDate!.month + _durationMonths,
        _selectedMoveInDate!.day,
      );

      // Double-check availability
      final isAvailable = await _dbService.isPropertyAvailable(
        propertyId: widget.property.id!,
        moveInDate: _selectedMoveInDate!,
        moveOutDate: moveOutDate,
      );

      if (!isAvailable) {
        throw Exception('Property is not available for the selected dates');
      }

      final numberOfOccupants = int.parse(_numberOfOccupantsController.text);
      
      await _dbService.createBooking(
        propertyId: widget.property.id!,
        renterId: currentUser.uid,
        landlordId: widget.property.landlordId,
        propertyName: widget.property.name,
        propertyAddress: widget.property.address,
        propertyPrice: widget.property.price,
        propertyImageUrl: widget.property.imageUrls.isNotEmpty 
            ? widget.property.imageUrls[0] 
            : null,
        renterName: _renterNameController.text.trim(),
        renterEmail: currentUser.email,
        renterPhone: currentUser.phoneNumber,
        moveInDate: _selectedMoveInDate!,
        durationMonths: _durationMonths,
        numberOfOccupants: numberOfOccupants,
        specialRequests: _specialRequestsController.text.trim().isNotEmpty
            ? _specialRequestsController.text.trim()
            : null,
        monthlyRent: _monthlyRent,
        securityDeposit: _securityDeposit,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moveOutDate = _selectedMoveInDate != null
        ? DateTime(
            _selectedMoveInDate!.year,
            _selectedMoveInDate!.month + _durationMonths,
            _selectedMoveInDate!.day,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Property'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.property.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.property.imageUrls[0],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        widget.property.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.property.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${NumberFormat('#,##0.00').format(widget.property.price)}/month',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Booking Details
              const Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Move-in Date
              InkWell(
                onTap: _selectMoveInDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Move-in Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedMoveInDate != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedMoveInDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _selectedMoveInDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              if (_isCheckingAvailability)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Checking availability...',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Duration
              DropdownButtonFormField<int>(
                initialValue: _durationMonths,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  1, 2, 3, 6, 9, 12, 18, 24, 36
                ].map((months) {
                  final years = months ~/ 12;
                  final remainingMonths = months % 12;
                  String label = '';
                  if (years > 0) {
                    label = '$years year${years > 1 ? 's' : ''}';
                  }
                  if (remainingMonths > 0) {
                    if (label.isNotEmpty) label += ' ';
                    label += '$remainingMonths month${remainingMonths > 1 ? 's' : ''}';
                  }
                  return DropdownMenuItem(
                    value: months,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _durationMonths = value!;
                  });
                  _checkAvailability();
                },
              ),
              if (moveOutDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Move-out date: ${DateFormat('MMM dd, yyyy').format(moveOutDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Number of Occupants
              TextFormField(
                controller: _numberOfOccupantsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Occupants',
                  hintText: 'Enter number of people',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of occupants';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1) {
                    return 'Please enter a valid number (minimum 1)';
                  }
                  if (number > 50) {
                    return 'Number of occupants cannot exceed 50';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Renter Name (Editable)
              TextFormField(
                controller: _renterNameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Special Requests
              TextFormField(
                controller: _specialRequestsController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Special Requests (Optional)',
                  hintText: 'Any special requirements or requests...',
                  prefixIcon: const Icon(Icons.note_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Financial Summary
              const Text(
                'Financial Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Monthly Rent',
                        '₱${NumberFormat('#,##0.00').format(_monthlyRent)}',
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Duration',
                        '$_durationMonths months',
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Total Rent',
                        '₱${NumberFormat('#,##0.00').format(_monthlyRent * _durationMonths)}',
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Security Deposit (2 months)',
                        '₱${NumberFormat('#,##0.00').format(_securityDeposit)}',
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Payment Method',
                        'Over the Counter',
                      ),
                      const Divider(thickness: 2),
                      _buildSummaryRow(
                        'Total Amount',
                        '₱${NumberFormat('#,##0.00').format(_totalAmount)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _isCheckingAvailability
                      ? null
                      : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Booking Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFFFF6B6B) : null,
          ),
        ),
      ],
    );
  }
}
