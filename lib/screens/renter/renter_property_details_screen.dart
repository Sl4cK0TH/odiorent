import 'package:flutter/material.dart';
import 'package:odiorent/models/property_with_landlord.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/screens/renter/booking/booking_screen.dart';

class RenterPropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const RenterPropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<RenterPropertyDetailsScreen> createState() =>
      _RenterPropertyDetailsScreenState();
}

class _RenterPropertyDetailsScreenState
    extends State<RenterPropertyDetailsScreen> {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  Future<PropertyWithLandlord>? _propertyFuture;

  @override
  void initState() {
    super.initState();
    _propertyFuture = _fetchPropertyDetails();
  }

  Future<PropertyWithLandlord> _fetchPropertyDetails() async {
    final data = await _dbService.getPropertyWithLandlordDetails(widget.propertyId);
    return PropertyWithLandlord.fromMap(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PropertyWithLandlord>(
        future: _propertyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Property not found.'));
          }

          final propertyWithLandlord = snapshot.data!;
          final property = propertyWithLandlord.property;
          final landlord = propertyWithLandlord.landlord;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: property.imageUrls.isNotEmpty
                      ? Image.network(
                          property.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.business, size: 100, color: Colors.grey),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.business, size: 100, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            property.address,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '₱${property.price.toStringAsFixed(2)} / month',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.king_bed_outlined, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text('${property.beds} Beds'),
                              const SizedBox(width: 24),
                              Icon(Icons.room_service_outlined, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text('${property.rooms} Rooms'),
                            ],
                          ),
                          const Divider(height: 32),
                          const Text(
                            'Description',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            property.description,
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                          ),
                          const Divider(height: 32),
                          const Text(
                            'Landlord Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${landlord.firstName} ${landlord.lastName}', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Username: ${landlord.userName}', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Email: ${landlord.email}', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Contact: ${landlord.phoneNumber}', style: const TextStyle(fontSize: 16)),
                          
                          // --- BIR Permit Display ---
                          if (property.birPermitUrl != null && property.birPermitUrl!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                  "Verified BIR Permit",
                                  style: TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.bold, 
                                      color: Color(0xFF388E3C), // Dark Green
                                  ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                        property.birPermitUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Text("Could not load permit image"),
                                        ),
                                    ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message Landlord'),
                onPressed: () {
                  Fluttertoast.showToast(msg: "Messaging feature coming soon!");
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Book Now'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BookingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
