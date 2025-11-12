import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:intl/intl.dart'; // For date formatting

class ApprovedPropertiesList extends StatefulWidget {
  const ApprovedPropertiesList({super.key});

  @override
  State<ApprovedPropertiesList> createState() => _ApprovedPropertiesListState();
}

class _ApprovedPropertiesListState extends State<ApprovedPropertiesList> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Property>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _propertiesFuture =
        _dbService.getPropertiesByStatusWithLandlordDetails('approved');
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
          return const Center(child: Text("No approved properties."));
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
                    Text('Status: ${property.status.toUpperCase()}'),
                    // Add more details as needed
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
