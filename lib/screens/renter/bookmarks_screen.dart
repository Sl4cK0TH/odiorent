import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/widgets/property_card.dart';
import 'package:odiorent/screens/renter/property_details_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view bookmarks'))
          : StreamBuilder<List<Property>>(
              stream: _dbService.getUserBookmarksStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final properties = snapshot.data ?? [];

                if (properties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                    'No bookmarks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark properties to save them for later',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailsScreen(property: property),
                    ),
                  );
                },
                child: PropertyCard(property: property),
              );
            },
          );
        },
      ),
    );
  }
}
