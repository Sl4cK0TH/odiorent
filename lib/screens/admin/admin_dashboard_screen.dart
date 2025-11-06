import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/screens/admin/admin_property_view.dart';
import 'package:odiorent/screens/shared/welcome_screen.dart'; // For sign out
import 'package:intl/intl.dart'; // For formatting dates

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // --- Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  // Services
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // A Future to hold the list of pending properties
  late Future<List<Property>> _pendingPropertiesFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future
    _pendingPropertiesFuture = _dbService.getPendingProperties();
  }

  // Function to refresh the list
  void _refreshPendingList() {
    setState(() {
      _pendingPropertiesFuture = _dbService.getPendingProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard - Pending Approvals'),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                // Go back to the very first screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Property>>(
        future: _pendingPropertiesFuture,
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          // --- Error State ---
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // --- Empty State ---
          final properties = snapshot.data;
          if (properties == null || properties.isEmpty) {
            return const Center(
              child: Text(
                "No properties are pending approval. Good job!",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // --- Success State (Show List) ---
          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];

              // We'll add this to 'property.dart' model later if it's not there
              // For now, let's assume 'created_at' exists as a DateTime?
              // String formattedDate = property.createdAt != null
              //     ? DateFormat('MMMd, yyyy - h:mm a').format(property.createdAt!)
              //     : 'No date';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  child: Icon(
                    property.rooms > 1 ? Icons.apartment : Icons.home,
                  ),
                ),
                title: Text(
                  property.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(property.address),
                // trailing: Text(formattedDate), // Example of date
                onTap: () async {
                  // Navigate to the detail view screen
                  final bool? needsRefresh = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AdminPropertyViewScreen(property: property),
                    ),
                  );

                  // If the detail screen popped and returned 'true',
                  // it means an action was taken, so we refresh the list.
                  if (needsRefresh == true) {
                    _refreshPendingList();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
