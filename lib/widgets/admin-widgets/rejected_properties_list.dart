import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fluttertoast/fluttertoast.dart';

class RejectedPropertiesList extends StatefulWidget {
  const RejectedPropertiesList({super.key});

  @override
  State<RejectedPropertiesList> createState() => _RejectedPropertiesListState();
}

class _RejectedPropertiesListState extends State<RejectedPropertiesList> {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  late Future<List<Property>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _dbService
        .getPropertiesByStatusWithLandlordDetails(PropertyStatus.rejected);
  }

  void _refreshList() {
    setState(() {
      _propertiesFuture = _dbService
          .getPropertiesByStatusWithLandlordDetails(PropertyStatus.rejected);
    });
  }

  Future<void> _updatePropertyStatus(String propertyId, PropertyStatus status,
      String landlordId, String propertyName) async {
    try {
      await _dbService.updatePropertyStatus(
        propertyId: propertyId,
        status: status,
        landlordId: landlordId,
        propertyName: propertyName,
      );
      Fluttertoast.showToast(
        msg: "Property ${statusToString(status)} successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      _refreshList(); // Refresh the list after update
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update property status: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Property>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final properties = snapshot.data;
        if (properties == null || properties.isEmpty) {
          return const Center(child: Text("No rejected properties."));
        }

        return ListView.builder(
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Address: ${property.address}'),
                    Text('Landlord: ${property.landlordName ?? 'N/A'}'),
                    Text('Email: ${property.landlordEmail ?? 'N/A'}'),
                    Text(
                      'Requested: ${DateFormat('MMM d, yyyy').format(property.createdAt)}',
                    ),
                    if (property.approvedAt != null)
                      Text(
                        'Approved: ${DateFormat('MMM d, yyyy').format(property.approvedAt!)}',
                      ),
                    Text(
                        'Status: ${statusToString(property.status).toUpperCase()}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _updatePropertyStatus(
                            property.id!,
                            PropertyStatus.approved,
                            property.landlordId,
                            property.name,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}